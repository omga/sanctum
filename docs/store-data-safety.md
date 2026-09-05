# Store data-safety declarations

What to enter in **Google Play → Data safety** and **App Store Connect →
App Privacy**, and the reasoning behind each answer, so the next person
filling the form does not have to re-derive it from the source.

**Status: drafted from what the code does, not yet submitted.** It has
to go in with the same release that first compiles `ADVISOR_PROXY_URL`,
and it has to agree line for line with the published policy — which
lives in the `morphostudio` repository, not this one; see
`privacy-policy.md` next to this file for the path. A store review that
finds the two disagreeing treats it as a misrepresentation, not a typo.

Both forms describe **the shipped binary**. Until a build compiles a
proxy URL, the advisor rows below are not true of the app and must not
be declared; from the build that does, they are, and must be.

---

## Google Play — Data safety

Account creation: **no**. Sanctum has no accounts.

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| App interactions | Yes | No | Analytics | No |
| Crash logs | Yes | No | Crash reporting | No |
| Diagnostics | Yes | No | Crash reporting, analytics | No |
| Purchase history | Yes | No | App functionality | No |
| Other user-generated content (a question asked of the advisor) | Yes | Yes | App functionality | **Yes** — the advisor is off until the user agrees |
| Other info (computed astrological positions) | Yes | Yes | App functionality | **Yes** — as above |

Declared as **collected** rather than "processed ephemerally" for the
advisor rows: the request does leave the device, and the ephemerality is
on our server, not on the vendor's. The conservative answer is the one
to give.

**Not** declared, because the app does not send them anywhere: name,
date of birth, contacts, location, photos, files, messages, health data,
or any other personal identifier. All of that stays on the device.

Data is encrypted in transit: **yes**. Users can request deletion:
**yes** — in-app for everything stored on the device; nothing about a
conversation is retained on our server to delete.

## Apple — App Privacy

**Data Not Linked to You**, for all of the below: none of it is tied to
an identity, because there is no account and no identifier that resolves
to a person.

| Category | Collected | Used for | Tracking? |
|---|---|---|---|
| Product interaction | Yes | Analytics | No |
| Crash data, performance data | Yes | App functionality | No |
| Purchases | Yes | App functionality | No |
| Other data — a question asked of the advisor, and the computed positions behind it | Yes | App functionality | No |

**Tracking: no** for every row. Nothing here follows a user across apps
or websites, there is no advertising identifier, and no data goes to a
data broker.

The random per-install identifiers (analytics, advisor rate limiting,
RevenueCat's anonymous app user ID) are declared as **Device ID → Not
Linked to You** if the reviewer asks how a per-install value is
classified. They are generated on the device, are meaningless anywhere
else, and are not joined to each other.

## Third parties named in both listings

| Vendor | What it receives |
|---|---|
| PostHog | Typed product events, a per-install id |
| Sentry | Crash and handled-failure reports |
| RevenueCat | Purchase state, an anonymous app user ID |
| Supabase | The advisor request, in transit, stored nowhere |
| DeepSeek | The advisor request: positions, the redacted question, the answer language |

## The thing most likely to be got wrong

Declaring the advisor rows as **optional** is only honest while consent
actually gates the feature. The gate is enforced in two places —
`AdvisorScreen` will not show a composer, and `chatTransport` will not
build a proxy transport — and both are covered by
`test/features/advisor_consent_test.dart`. If a future change makes the
advisor send anything before that screen is answered, these forms become
false and have to be resubmitted.
