# The advisor proxy

One Supabase Edge Function. It is the first backend Sanctum has had and
it is deliberately the smallest one that can exist.

**Deployed and answering** as of 2026-09-05, verified by the `curl`
below: DeepSeek streams real deltas back in our frame format.

**The app is not pointed at it.** `ADVISOR_PROXY_URL` is empty in every
build, so `chatTransport` hands back the scripted transport and the app
makes no network call at all.

Since the consent screen landed, a URL is no longer sufficient on its
own: `chatTransport` also requires a granted consent, so the first build
that compiles a URL still sends nothing until a user has read the
disclosure and agreed. What remains before pointing a *release* build at
this is the policy work and entitlement — see "Before this ships"
below.

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
  "surface": "match",        // match | report | today | self
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
  -H "apikey: sb_publishable_..." \
  -H "x-sanctum-install: smoke-test-0001" \
  -H "content-type: application/json" \
  -d '{"surface":"today","languageCode":"en",
       "facts":{"quiet":true,"retrogrades":[]},
       "messages":[{"author":"you","body":"What is today about?"}]}'
```

A `{"error":"bad_request"}` means the payload was rejected — the
function logs the reason, and `supabase functions logs advisor` shows
it without ever showing a prompt body.

**`self` is newer than the first deployment.** A build asking about the
reader's own chart sends `surface: "self"`, and a function deployed
before that surface existed rejects it as an unknown surface. Redeploy
before testing the You row in the Ask tab.

Then point a build at it:

```bash
flutter run \
  --dart-define=ADVISOR_PROXY_URL=<project url>/functions/v1/advisor \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

### Which key, from where

The dashboard shows three things that matter here:

| Dashboard | Goes where | Notes |
|---|---|---|
| **Project URL** | `ADVISOR_PROXY_URL`, with `/functions/v1/advisor` appended | |
| **Publishable key** (`sb_publishable_…`) | `SUPABASE_PUBLISHABLE_KEY` | Ships in the binary. Not a secret and never treated as one. |
| **Secret key** (`sb_secret_…`) | **Nowhere in the app.** A Supabase secret, for the function itself, once the entitlement table exists. | |

Publishable keys are short strings, **not JWTs**, so they travel on the
`apikey` header — anything verifying one as a JWT fails.
`ProxyChatTransport` sends `apikey` always and adds
`Authorization: Bearer` only when the key is a legacy `anon` JWT, which
is what makes both key systems work. There is a test per branch.

With `ADVISOR_PROXY_URL` unset — which is every build today — the app
uses the scripted transport and makes no network call.

### Project security settings

Three toggles in the Supabase dashboard, and what they are set to:

| Setting | Value | Why |
|---|---|---|
| Enable Data API | **off** | Nothing here talks to PostgREST. The app talks to this function; the function talks to DeepSeek. On, it publishes the `public` schema to anyone holding the anon key — which ships in the binary and can be read out of any APK. |
| Automatically expose new tables | **off** | The next table created here is the entitlement balance. Auto-exposed, that is a table anybody can read and write with a key extracted from the app. |
| Enable automatic RLS | **on** | Free insurance. Turns "somebody forgot" from a breach into a query returning no rows. |

**The entitlement table, when it exists, gets RLS on and no policies at
all** — not a permissive one, none. This function reaches it with the
service-role key, which bypasses RLS; nothing else can touch it. That
key is a Supabase secret and must never reach a `--dart-define`.

Data API stops being off the day astrologer chat reads messages from the
client with `supabase-js`. Realtime does not need it — `postgres_changes`,
broadcast and presence are separate services — so even that feature's
live half works with it off. Turn it on when a client genuinely needs to
query tables, and write the policies in the same change.

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

- [x] **The consent screen exists** (`advisor.md` §8 step 5). It names
      DeepSeek, and a granted consent is required in two places — the
      screen shows the disclosure instead of a composer, and
      `chatTransport` will not build a `ProxyChatTransport` without one.
      `test/features/advisor_consent_test.dart` pins both, including the
      case that matters here: a build *with* a URL compiled in still
      gets the scripted transport until the answer is yes.
- [x] **Privacy policy and terms published.** They live in the
      `morphostudio` repository, not this one — `docs/privacy-policy.md`
      has the path and the list of four things that change together.
      Both name DeepSeek, state the transfer to China, and state
      explicit consent as the mechanism.
- [ ] **Store data-safety forms submitted**, and agreeing with the
      published policy line for line. Play's Data safety and Apple's App
      Privacy both need the advisor rows added — `docs/store-data-safety.md`
      has the answers and the reasoning. A review that finds the forms
      and the policy disagreeing treats it as a misrepresentation.
- [x] `README.md` no longer opens with "There is no backend and no
      account", and the in-app privacy claims are gone.
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
