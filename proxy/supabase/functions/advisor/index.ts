// Sanctum's advisor proxy.
//
// The first backend this product has had, and deliberately the smallest
// one that can exist: one endpoint, no database, no session, nothing
// kept. See `.claude/advisor.md` §5.
//
// ## What this is for
//
// The model API key cannot ship in the binary. That is the entire
// reason this exists — not orchestration, not memory, not a user
// record. Everything else about the advisor is computed on the phone
// and sent per request.
//
// ## What it must never do
//
// * Store a conversation. History arrives with every request and is
//   dropped when the response ends, which is how "no conversation
//   history on a server the app cannot delete from" is true by
//   construction rather than by policy.
// * Log a prompt body. Metadata only: latency, token counts, error
//   class. A log line with somebody's question in it is the same leak
//   as a database, with worse retention.
// * Trust the client about what it is entitled to. Today that means
//   rate limits only; see `TODO(step 6)`.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

// ── Configuration ──────────────────────────────────────────────────
//
// DeepSeek, over an OpenAI-compatible endpoint. All three of these are
// environment variables rather than constants, so switching vendor is a
// redeploy: anything that speaks the OpenAI shape needs only a
// different base URL and key.
//
// `deepseek-v4-flash` is the id in DeepSeek's own docs. If a dated
// pin is wanted — `-0731` or similar — set ADVISOR_MODEL rather than
// editing this line.

const MODEL = Deno.env.get('ADVISOR_MODEL') ?? 'deepseek-v4-flash';
const API_KEY = Deno.env.get('DEEPSEEK_API_KEY') ?? '';
const API_BASE = Deno.env.get('ADVISOR_API_BASE') ?? 'https://api.deepseek.com';
const MAX_TURNS_PER_HOUR = Number(Deno.env.get('ADVISOR_RATE_LIMIT') ?? '40');
const MAX_OUTPUT_TOKENS = Number(Deno.env.get('ADVISOR_MAX_TOKENS') ?? '700');

// ── The payload contract ───────────────────────────────────────────
//
// This mirrors `AdvisorContext` in the app, and the point of validating
// it here is not defence against a hostile client — it is defence
// against *our own* future bug. If a later version of the app ever
// starts sending a name, this rejects it rather than forwarding it to a
// third party.

/** Keys that may never appear anywhere in a request, at any depth. */
const DENIED_KEYS = new Set([
  'name', 'first_name', 'display_name', 'full_name',
  'birth', 'birth_date', 'birthdate', 'birth_time', 'dob',
  'email', 'phone', 'journal', 'entry', 'note',
  'device_id', 'user_id', 'install_id',
]);

/** The longest a fact value may be. Anything longer is prose. */
const MAX_FACT_LENGTH = 24;

type Message = { author: 'you' | 'counterpart'; body: string };

/** The screens a question can be asked from. */
const SURFACES = ['match', 'report', 'today', 'self'] as const;

type Surface = (typeof SURFACES)[number];

type AdvisorRequest = {
  surface: Surface;
  languageCode: string;
  facts: Record<string, unknown>;
  messages: Message[];
};

class BadRequest extends Error {}

/**
 * Rejects anything that does not look exactly like what the app sends.
 *
 * Walks the whole `facts` tree rather than checking the top level: the
 * payload nests (facets carry contacts), and a leak would not politely
 * appear at depth one.
 */
function validateFacts(value: unknown, depth = 0): void {
  if (depth > 6) throw new BadRequest('facts nested too deeply');

  if (Array.isArray(value)) {
    for (const item of value) validateFacts(item, depth + 1);
    return;
  }

  if (value !== null && typeof value === 'object') {
    for (const [key, child] of Object.entries(value)) {
      if (DENIED_KEYS.has(key)) throw new BadRequest(`denied key: ${key}`);
      validateFacts(child, depth + 1);
    }
    return;
  }

  if (typeof value === 'string' && value.length > MAX_FACT_LENGTH) {
    // A long string among the computed facts means somebody passed a
    // composed reading, or worse.
    throw new BadRequest('fact value too long');
  }

  if (
    value !== null &&
    typeof value !== 'string' &&
    typeof value !== 'number' &&
    typeof value !== 'boolean'
  ) {
    throw new BadRequest('non-primitive fact');
  }
}

function parseRequest(body: unknown): AdvisorRequest {
  if (body === null || typeof body !== 'object') {
    throw new BadRequest('body must be an object');
  }
  const raw = body as Record<string, unknown>;

  const surface = raw.surface;
  if (
    typeof surface !== 'string' ||
    !(SURFACES as readonly string[]).includes(surface)
  ) {
    throw new BadRequest('unknown surface');
  }

  const languageCode = raw.languageCode;
  if (typeof languageCode !== 'string' || !/^[a-z]{2}$/.test(languageCode)) {
    throw new BadRequest('bad languageCode');
  }

  const facts = raw.facts;
  if (facts === null || typeof facts !== 'object' || Array.isArray(facts)) {
    throw new BadRequest('facts must be an object');
  }
  validateFacts(facts);

  const messages = raw.messages;
  if (!Array.isArray(messages) || messages.length === 0) {
    throw new BadRequest('messages must be a non-empty array');
  }
  // Twenty is `ConversationHistory.maxMessages` in the app. Bounded
  // here too, because the bill is paid on this side.
  if (messages.length > 20) throw new BadRequest('too many messages');

  const parsed: Message[] = messages.map((message) => {
    if (message === null || typeof message !== 'object') {
      throw new BadRequest('bad message');
    }
    const { author, body: text } = message as Record<string, unknown>;
    if (author !== 'you' && author !== 'counterpart') {
      throw new BadRequest('bad author');
    }
    if (typeof text !== 'string' || text.length === 0) {
      throw new BadRequest('empty message');
    }
    if (text.length > 2000) throw new BadRequest('message too long');
    return { author, body: text };
  });

  return {
    surface: surface as Surface,
    languageCode,
    facts,
    messages: parsed,
  };
}

// ── Rate limiting ──────────────────────────────────────────────────
//
// In memory, per isolate. That is genuinely weak — Deno Deploy runs
// many isolates and they do not share this map — and it is deliberate
// for now: it costs nothing, it stops a runaway client on one instance,
// and the real ceiling is the spend cap on the vendor account.
//
// TODO(step 6): entitlement is what actually gates this. When purchases
// land, a turn should cost a verified receipt rather than a header the
// client chooses, and this map becomes a backstop rather than the
// control.

const seen = new Map<string, number[]>();

function rateLimited(installId: string): boolean {
  const now = Date.now();
  const hourAgo = now - 3_600_000;
  const hits = (seen.get(installId) ?? []).filter((at) => at > hourAgo);
  hits.push(now);
  seen.set(installId, hits);

  // Unbounded growth is the other way this leaks. Anything with no
  // recent activity is forgotten.
  if (seen.size > 10_000) {
    for (const [key, times] of seen) {
      if (times.every((at) => at <= hourAgo)) seen.delete(key);
    }
  }
  return hits.length > MAX_TURNS_PER_HOUR;
}

// ── The prompt ─────────────────────────────────────────────────────
//
// Server-side so it can be corrected without a store release.
//
// Three constraints in it are not stylistic. The advisor must not
// invent placements the app did not send; must not forecast, because
// the product refuses to (`roadmap.md` §1); and must answer in the
// reader's language, because the app is shipped in four.

function systemPrompt(request: AdvisorRequest): string {
  return [
    'You are an astrologer inside Sanctum, a quiet astrology app.',
    'You are given real computed positions — for one pairing, for one',
    'person, or for one day. Answer only from those numbers.',
    '',
    'Rules:',
    '- Never invent a placement, an aspect or a score that is not in the',
    '  data given. If the data cannot answer, say so plainly.',
    '- Never predict dated events or outcomes. Describe conditions and',
    '  dynamics. This product does not forecast.',
    '- You do not know anyone\'s name, age, gender or history, and you',
    '  must not guess. The other person is "them".',
    '- Do not claim to know what another person thinks or feels. You are',
    '  reading a chart, not a mind.',
    ...(request.surface === 'self'
      ? [
        '- This chart is the reader\'s own, and there is no second',
        '  person in it. Do not invent one, and do not answer as though',
        '  a relationship were being described.',
      ]
      : []),
    '- Be warm, specific and short: three or four sentences unless asked',
    '  for more. No horoscope filler, no cosmic vocabulary.',
    `- Write in the language with code "${request.languageCode}".`,
    '',
    `Surface: ${request.surface}`,
    `Computed data: ${JSON.stringify(request.facts)}`,
  ].join('\n');
}

// ── The vendor call ────────────────────────────────────────────────
//
// DeepSeek, over its OpenAI-compatible `/chat/completions`. Behind one
// function and two environment variables, so switching vendor is a
// redeploy: anything speaking the OpenAI shape needs only a different
// `ADVISOR_API_BASE` and key.
//
// The system prompt is a `system` *message* here rather than a
// top-level field, which is the one shape difference from the Anthropic
// format worth knowing about.

async function callModel(request: AdvisorRequest): Promise<Response> {
  return await fetch(`${API_BASE}/chat/completions`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${API_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: MAX_OUTPUT_TOKENS,
      stream: true,
      messages: [
        { role: 'system', content: systemPrompt(request) },
        ...request.messages.map((message) => ({
          role: message.author === 'you' ? 'user' : 'assistant',
          content: message.body,
        })),
      ],
    }),
  });
}

// ── The wire format back to the app ────────────────────────────────
//
// Our own SSE, not the vendor's, so the client is not coupled to a
// vendor's event names and switching models is a server change only.
//
//   data: {"delta":"some text"}
//   data: {"done":true}
//   data: {"error":"rate_limited"}

function sse(payload: Record<string, unknown>): Uint8Array {
  return new TextEncoder().encode(`data: ${JSON.stringify(payload)}\n\n`);
}

function errorStream(kind: string, status: number): Response {
  const body = new ReadableStream({
    start(controller) {
      controller.enqueue(sse({ error: kind }));
      controller.close();
    },
  });
  return new Response(body, {
    status,
    headers: { 'content-type': 'text/event-stream' },
  });
}

serve(async (httpRequest: Request) => {
  const startedAt = Date.now();

  if (httpRequest.method !== 'POST') {
    return errorStream('bad_request', 405);
  }

  const installId = httpRequest.headers.get('x-sanctum-install') ?? '';
  if (installId.length < 8 || installId.length > 64) {
    // Not authentication. It is the key the rate limiter counts on, and
    // it is deliberately not a user account: Sanctum has none, and
    // `handoff.md` rejects adding one.
    return errorStream('bad_request', 400);
  }

  if (rateLimited(installId)) {
    return errorStream('rate_limited', 429);
  }

  let request: AdvisorRequest;
  try {
    request = parseRequest(await httpRequest.json());
  } catch (error) {
    // The message, never the body.
    console.log(
      JSON.stringify({
        event: 'advisor_rejected',
        reason: error instanceof BadRequest ? error.message : 'unparseable',
      }),
    );
    return errorStream('bad_request', 400);
  }

  let upstream: Response;
  try {
    upstream = await callModel(request);
  } catch (_error) {
    return errorStream('server', 502);
  }

  if (!upstream.ok || upstream.body === null) {
    console.log(
      JSON.stringify({ event: 'advisor_upstream', status: upstream.status }),
    );
    return errorStream(upstream.status === 429 ? 'rate_limited' : 'server', 502);
  }

  // Translate the vendor's stream into ours, chunk by chunk. Nothing is
  // buffered to completion: the whole point of streaming is that the
  // first words reach the phone while the rest is still being written.
  let characters = 0;
  const body = new ReadableStream({
    async start(controller) {
      const reader = upstream.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      try {
        for (;;) {
          const { done, value } = await reader.read();
          if (done) break;
          buffer += decoder.decode(value, { stream: true });

          const lines = buffer.split('\n');
          buffer = lines.pop() ?? '';

          for (const line of lines) {
            if (!line.startsWith('data:')) continue;
            const payload = line.slice(5).trim();
            if (payload === '' || payload === '[DONE]') continue;

            try {
              // OpenAI shape: choices[0].delta.content. Translated into
              // our own frame here so the app never learns a vendor's
              // event names.
              const event = JSON.parse(payload);
              const text = event.choices?.[0]?.delta?.content;
              if (typeof text === 'string' && text.length > 0) {
                characters += text.length;
                controller.enqueue(sse({ delta: text }));
              }
            } catch (_error) {
              // A malformed vendor event is not worth failing a whole
              // answer over.
            }
          }
        }
        controller.enqueue(sse({ done: true }));
      } catch (_error) {
        controller.enqueue(sse({ error: 'server' }));
      } finally {
        controller.close();
        // Metadata only. No prompt, no answer, no install id.
        console.log(
          JSON.stringify({
            event: 'advisor_answered',
            surface: request.surface,
            language: request.languageCode,
            characters,
            ms: Date.now() - startedAt,
          }),
        );
      }
    },
  });

  return new Response(body, {
    status: 200,
    headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-store',
    },
  });
});
