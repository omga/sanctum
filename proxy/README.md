# The advisor proxy

One Supabase Edge Function. It is the first backend Sanctum has had and
it is deliberately the smallest one that can exist.

**Not deployed.** Nothing in the app points at it: `ADVISOR_PROXY_URL` is
empty in every build, so `chatTransport` hands back the scripted
transport and the app makes no network call at all. See "Before this
ships" below — there is a consent screen that must exist first.

## Why it exists

The model API key cannot ship in the binary. That is the whole reason.
Not orchestration, not memory, not a user record — everything else about
the advisor is computed on the phone and travels with each request.

## Why Supabase

A stateless proxy is the easy backend, and it is not the one to choose
infrastructure for. Chat with real astrologers is on the roadmap, and
that needs server-side messages both people can read, realtime delivery,
and identity for the astrologers. Postgres + Realtime + Auth in one
account makes that second feature cheap.

`handoff.md` rejected Supabase for v1, on the grounds that
account-creation-before-paywall is funnel friction. That still holds and
this does not break it: **the function takes an install id, not a
Supabase user.** Sanctum still has no accounts.

## The model

DeepSeek `deepseek-v4-flash`, called at `/chat/completions` — DeepSeek's
API is OpenAI-compatible, so the vendor is two environment variables
rather than a code path. The system prompt travels as a `system`
message, which is the one shape difference from the Anthropic format
worth knowing about.

The proxy translates the vendor's stream into our own frames, so the
app never learns a vendor's event names and a change of model is a
server-only change.

## The contract

`POST /functions/v1/advisor`

```jsonc
{
  "surface": "match",        // match | report | today
  "languageCode": "uk",      // answer in this language
  "facts": { /* AdvisorContext.facts — numbers and enum names */ },
  "messages": [{ "author": "you", "body": "Why is it like this?" }]
}
```

Header `x-sanctum-install: <id>` keys the rate limiter. It is not a
login.

The response is `text/event-stream` in **our** format, not the vendor's,
so switching models never touches the app:

```text
data: {"delta":"some text"}
data: {"done":true}
data: {"error":"rate_limited"}   // rate_limited | bad_request | server
```

## Rules this function exists to keep

1. **Store nothing.** History arrives with every request and is dropped
   when the response ends. That is what makes "no conversation history
   on a server the app cannot delete from" true by construction rather
   than by policy.
2. **Log no prompt body.** Metadata only — latency, character counts,
   error class. A log line with somebody's question in it is the same
   leak as a database, with worse retention.
3. **Re-validate the payload.** `DENIED_KEYS` and the length check
   mirror `advisor_context_test.dart`. This is not defence against a
   hostile client; it is defence against *our own* future bug. If a
   later version of the app ever starts sending a name, this rejects it
   rather than forwarding it to a third party.

## Deploying

Every command runs **from `proxy/`** — that is where `supabase/` lives,
and the CLI resolves functions relative to the working directory.

```bash
brew install supabase/tap/supabase
```

Then, once:

```bash
cd proxy
supabase login
supabase link --project-ref <ref>
```

`<ref>` is the project reference from the Supabase dashboard URL. Create
a project there first if there is not one; the advisor needs no database,
no auth and no storage, so the free tier is the right size.

Deploy, and set the one real secret:

```bash
cd proxy
supabase secrets set DEEPSEEK_API_KEY=sk-...
supabase functions deploy advisor
```

Check it before pointing the app at it. This should stream frames back:

```bash
curl -N https://<ref>.supabase.co/functions/v1/advisor \
  -H "Authorization: Bearer <anon key>" \
  -H "x-sanctum-install: smoke-test-0001" \
  -H "content-type: application/json" \
  -d '{"surface":"today","languageCode":"en",
       "facts":{"quiet":true,"retrogrades":[]},
       "messages":[{"author":"you","body":"What is today about?"}]}'
```

A `{"error":"bad_request"}` means the payload was rejected — the
function logs the reason, and `supabase functions logs advisor` shows
it without ever showing a prompt body.

Then point a build at it:

```bash
flutter run \
  --dart-define=ADVISOR_PROXY_URL=https://<ref>.supabase.co/functions/v1/advisor \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

With `ADVISOR_PROXY_URL` unset — which is every build today — the app
uses the scripted transport and makes no network call.

### Why `verify_jwt` stays on

The anon key is a valid JWT, so the app passes and a bare `curl` without
one does not. It is **not** authentication: the key ships in the binary
and anybody can read it out. It is one cheap filter in front of an
endpoint that costs money per request, and the gates that matter are the
rate limiter and, once it exists, entitlement.

| variable | default | what it does |
|---|---|---|
| `DEEPSEEK_API_KEY` | — | the only real secret here |
| `ADVISOR_MODEL` | `deepseek-v4-flash` | swap models without a code change |
| `ADVISOR_API_BASE` | `https://api.deepseek.com` | any OpenAI-compatible host |
| `ADVISOR_RATE_LIMIT` | `40` | answered turns per install per hour |
| `ADVISOR_MAX_TOKENS` | `700` | ceiling on one answer |

## Before this ships to anyone

- [ ] **The consent screen exists** (`advisor.md` §8 step 5). Compiling
      a URL into a release build without it means a chart reaches a
      third party with nobody having been told.
- [ ] Privacy policy and store data-safety declaration updated in the
      same change.
- [ ] `README.md` no longer opens with "There is no backend and no
      account" — half of that stops being true here.
- [ ] **Entitlement is enforced.** Today the only gate is a rate limit
      keyed on a header the client chooses. A turn should cost a
      verified receipt (`advisor.md` §8 step 6); until then, the real
      ceiling is the spend cap on the vendor account, and it should be
      set low.
- [ ] Rate limiting survives more than one isolate. The in-memory map is
      per-isolate and Deno Deploy runs many; a shared counter (Postgres,
      or Supabase's own rate limiting) replaces it when this matters.

## Testing it

There are no Deno tests in the repo — Deno is not installed on the
development machine, and adding a second test runner to CI for one file
was not worth it while the function is undeployed. The client half is
covered thoroughly in `test/data/proxy_chat_transport_test.dart`, which
runs a real HTTP server and asserts on the bytes.

The validation logic here is the part worth testing on the day this
deploys. It is written as pure functions (`validateFacts`,
`parseRequest`) precisely so that is a small job.
