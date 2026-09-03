# Sanctum — roadmap

Written 2026-08-19, the day the first real Play purchase went through.
Ordered by expected revenue per week of work, not by what is most fun to
build. Read §1 before anything else: it is the only item here that
changes the shape of the revenue curve rather than its slope.

---

## 0. Where the money in this category actually is

The competitive read in `handoff.md` §1 has not changed, but it is worth
being blunt about the mechanics now that billing works.

A subscription caps a user at roughly £40/year. That is the whole
relationship. Nebula, Purple Garden, Sanctuary and every profitable app
in this category make most of their money somewhere else: **advisor chat
sold as consumable credits**, where the top few percent of users spend
hundreds a month and nothing caps them.

That is not a moral judgement in either direction; it is the arithmetic.
A subscription business here is a good small business. A credits business
is the one with a ceiling high enough to matter. Everything in §1 follows
from that.

**Sanctum's own handoff has said this since day one** — "the
relationship/astrology wedge — compatibility readings, AI advisor sold as
credits — is where the category's money actually is and is **not
built**." Compatibility is built now. The advisor is not.

---

## 1. The advisor — the one bet that changes the curve

**An AI astrologer you can ask questions, sold as credits, not included
in the subscription.**

### Why credits and not "premium unlocks chat"

Bundling chat into the subscription converts a variable-value product
into a fixed-price one and throws away the entire upside. The user who
would have asked forty questions this month pays the same £6.99 as the
one who asked none — and the forty-question user is the one funding the
business.

Credits also solve the cost problem honestly. Every message costs real
money in inference; a subscription that includes unlimited chat is a
business that loses more the more successful it is.

Suggested shape, to be tested rather than trusted:

- Credits sold as consumables through the store (RevenueCat handles
  consumables; `purchases_flutter` already supports them)
- One credit per question, packs of roughly 10 / 30 / 100 with the
  usual per-unit discount
- Subscribers get a small monthly allowance — enough to form the habit,
  not enough to satisfy it. This is the mechanic that makes the
  subscription *drive* credit sales rather than substitute for them.

### Why it fits this app specifically

Most AI astrology chat is a thin wrapper around a general model that
knows nothing about you. Sanctum computes real natal positions, real
transits and a real synastry model. Feeding those into the prompt makes
the advisor answer from *your chart* rather than from your star sign —
which is both a better product and the thing no wrapper can copy without
building the engine underneath it.

The compatibility feature also generates the questions for free. "Why is
our Trust only 43?" is a question a user already has, on a screen they
are already looking at, about numbers the app already computed. Put the
entry point there, not in a generic chat tab.

### The privacy gate is not optional

`handoff.md` §3 is explicit: the privacy promise survives analytics and
survives RevenueCat's anonymous IDs, and **it does not survive AI chat**.

This needs designing in from the start, not retrofitting:

- An explicit, separate consent screen the first time chat is opened,
  which states what leaves the device and to whom
- Send **computed positions and the question**, never the name, never
  the birth date, never journal text. The chart is derivable from the
  positions; the birth date is not needed by the model
- No conversation history on a server the app cannot delete from
- Update the privacy policy and the store data-safety declaration in the
  same change, not afterwards

Getting this wrong costs more than the feature earns. The privacy claim
is the one thing the product is differentiated on in a category
notorious for the opposite.

### Naming, and what it costs

The working title "AI Psychic" claims more than any feature shipped so
far, and this app's whole documented posture is the opposite: quiet days
are admitted, the reveal captions name work that actually happens, the
score range is honest but not cruel. It also invites App Store 3.1.2
scrutiny and consumer-protection attention in the EU, while the
entertainment disclaimer still is not at first launch (§6). The framing
already used above — an astrologer that reads *your* chart, from real
computed positions — is more honest, more defensible in review, and is
the differentiation no thin wrapper can copy.

Note also that the EU AI Act's Article 50 transparency duty (telling
users they are interacting with an AI) was scheduled to apply from
2 August 2026, with parts of the timeline under active discussion —
check its current status with counsel before shipping to any EU locale.

### Effort

The largest item on this list. A backend appears for the first time —
even a thin proxy — because the API key cannot ship in the binary.
Budget for the proxy, the consent flow, the credit ledger, rate limiting
and abuse handling, not just the prompt.

---

## 2. Cheap conversion work, before any new feature

These are days, not weeks, and they multiply whatever traffic the
content produces. Do them first.

1. **Personalise the paywall headline from the quiz.** Already the
   highest-value remaining conversion work in the old next-steps list.
   The answers are persisted and `ReadingComposer` already selects copy
   from them; the paywall simply does not read them. Someone who ticked
   "I keep repeating a pattern" should see that sentence back at the
   moment they are asked to pay.
2. **Run a price test.** RevenueCat Experiments can serve different
   offerings to different cohorts with no app update. The current
   £6.99/£39.99 are placeholders that have never been tested against
   anything. Test the annual price first — annual mix is the single
   biggest lever on LTV in a subscription business this size.
3. **Test trial length.** 7 days is a default, not a decision.
4. **Fix the store title.** `Sanctum` alone wastes 22 of 30 characters
   of the most heavily weighted keyword field on Play. Something like
   `Sanctum: Zodiac Compatibility` indexes for the term the app is
   actually about.
5. **Screenshots.** The first two drive most of the install decision.
   They should be the compatibility reveal and the "who wants it more"
   split, not the Today screen — lead with the thing people share.
6. **Win-back offers.** RevenueCat supports them on iOS; a lapsed
   subscriber is the cheapest customer available.

---

## 3. Acquisition

1. **Post twenty videos.** Still the riskiest untested assumption, and
   still free. The carousel works end to end on TikTok. Nothing else on
   this list matters if the content does not move.
2. **9:16 video export of the reveal.** The carousel is the still
   version and shipped first deliberately. Video only after carousels
   show the format travels — building a video encoder for an unproven
   format is the wrong order.
3. **Instagram.** Feed carousels cap at 4:5, so the current 9:16 frames
   need a second aspect. Stories fit natively but reach existing
   followers only. Worth doing once TikTok is proven, not before.
4. **Localise.** The engineering is routine, and the copy is far
   smaller than this section used to assume. Measured 2026-08-31: the
   whole translatable surface is **~2,900 words of prose plus ~250 short
   UI strings** — content JSON, the three composers, and feature-layer
   text. At creative-transcreation rates that is roughly **€400–800 per
   language**, review included; all eight on the shortlist come to
   €3–6k once. Both bundled fonts (Cormorant Garamond, Inter) already
   carry Cyrillic including the Ukrainian extended set, plus every
   Romance and German diacritic, so there is no font work.

   Machine translation still strips the quality people are paying for —
   budget a human per language. But translation is **not** the binding
   constraint. **A locale is a content pipeline**, and the decision
   recorded in `handoff.md` §1 applies with more force to eight
   languages than it did to two apps: splitting a two-person team's
   posting volume is the one cost the organic strategy cannot absorb.

   > Ship a locale when someone will post in it and maintain a store
   > listing in it — not when the translation is done.

   A locale translated but never fed is worse than none: stores surface
   reviews per language, and a stale listing collects one-star reviews
   nobody on the team can read.

   Suggested order, gated on that rule rather than on translation:

   1. ~~**Infrastructure plus English as a real locale.**~~ **Done
      2026-08-31.** 241 ARB keys, 173 content keys, per-locale content
      directories with per-file English fallback, and the carousel
      hardened against longer strings. The reading copy moved out of the
      composers into `assets/content/en/copy.json` — see `handoff.md` §3
      for the two-store split and the rules that keep it honest.
   2. ~~**Ukrainian and Russian.**~~ **Translated 2026-08-31**, first
      draft, in review. See `handoff.md` §3 for the voice rules (ти,
      feminine, first-person app) and for what Slavic grammar broke that
      English had hidden.

      Original reasoning kept below, because the billing caveat still
      governs whether this is ever a revenue bet. Free to translate, free to judge, free
      to produce content in, and one Cyrillic typography pass covers
      both. Treat this as validation of the localised organic loop, not
      as a revenue bet: Google Play and the App Store both suspended
      in-app purchases for users in Russia in 2022, so Russian-language
      is the diaspora — Kazakhstan, Germany, Israel, the Baltics, the US
      — not the Russian market. Verify the current billing position
      before counting on it.
   3. ~~**Spanish (es-419).**~~ **Translated 2026-08-31** as plain
      `es`, LatAm-neutral, unreviewed by a native speaker. Shipped as
      one locale covering every Spanish market — see `handoff.md` §3.
      The creator half of this bet is untouched and is still the real
      gate.

      Original reasoning below. Where the money starts. Needs a paid
      translator *and* a native creator; the creator is the harder half
      and the real gate.
   4. **Portuguese (BR).** Highest-volume astrology market on the list.
      Same shape as Spanish, usually the same LatAm creator strategy.
   5. **French, Italian, German — as one batch, or never.** No team
      language advantage, no free creator, high-CPM markets already
      saturated by funded competitors, and German is the worst case for
      the export layout. Only once a *paid* locale has earned back its
      cost, and pick by which one you can find a creator for.

   **On sequencing this against §1:** localisation is a bet on traffic,
   the advisor is a bet on ARPU, and nobody yet knows which is the
   constraint — because "post twenty videos" is still undone. The
   infrastructure plus the two free languages is the cheap, diagnostic
   bet and should come first; it is also the cheapest way to run the
   experiment this list already calls the riskiest. Doing it first has a
   second benefit: the advisor adds the most legally sensitive strings
   in the product — a consent screen making a claim about what leaves
   the device — and those are far better translated into a codebase that
   already has the discipline than retrofitted across eight languages.
5. **Refresh the celebrity catalogue quarterly.** New names are a
   content update with no code change, they match what people search,
   and `tool/verify_celebrities.py` makes adding them safe.

---

## 4. Premium features worth building, ranked

Only after §1 and §2.

1. **Full birth chart report**, sold as a one-off unlock rather than
   bundled. The ephemeris already computes everything needed; this is
   presentation plus copy, and one-off unlocks convert people who will
   never take a subscription.
2. **Compatibility history and comparison.** "You have read eleven
   people. Here is who scores highest, and what your pattern is." Uses
   only data already stored, and it is the kind of summary people
   screenshot.
3. **Transit calendar** — the next month of notable transits, with the
   good days marked. `TransitCalculator` already knows this; the app
   just never shows more than tomorrow. This is the strongest retention
   surface that requires no new engine.
4. **Energy insights over time.** The paywall already advertises
   "insights" and `EnergyPatternCalculator` already refuses to speak
   without enough data, which is the hard part. What is missing is a
   chart.
5. **Palm and face reading.** Ranked #1 for virality in `handoff.md` —
   "the camera is on the person, the filming *is* the content". Also the
   largest build on this list and the one with the most obvious
   accuracy-honesty tension. Evaluate after video export.

---

## 5. Explicitly not worth building

Being clear about these saves more time than any item above.

- **More meditation and sound content.** The owner's own feature ranking
  put meditation audio last — "commodity, near-zero conversion lift" —
  and nothing since has contradicted it. Nine synthesised tones are
  enough to justify the category tag. Adding a tenth converts nobody.
- **AI-voiced affirmations.** This is meditation content with an extra
  cloud dependency, a per-generation cost, and a loss of the offline
  guarantee, competing in the segment already ranked last. The
  interesting variant is narrower: **a spoken version of the user's own
  daily transit**, which is differentiated because the content is
  personal. Even then it ranks below the advisor, and it should reuse
  whatever TTS the advisor work introduces rather than justify its own.
- **A human psychic marketplace.** The highest ARPU product in the
  category and the reason Nebula is worth what it is — and it is a
  *company*, not a feature: advisor recruitment, vetting, scheduling,
  payouts, dispute handling, moderation, and consumer-protection
  exposure in every market. Two people cannot run it alongside building
  the app. If the demand signal appears, the realistic route is an
  affiliate or white-label partnership, not building it.
- **A second app.** Already decided against on 2026-08-16 and still
  right: splitting a two-person team's posting volume is the one cost
  the organic strategy cannot absorb.

---

## 6. Engineering debt that will bite

Not revenue, but each one is cheaper now than later.

- **`MatchResultRoute` carries `name` and `birth` as query parameters.**
  Both analytics navigation observers are disabled specifically because
  of it. Replace with an opaque id before adding any new observability
  tool.
- **No entertainment disclaimer at first launch.** Present on the payoff
  screen and the carousel's closing frame only. Store review for
  divination content generally expects it earlier.
- **Placeholder launcher icon.**
- **No golden tests**, though `alchemist` is installed.
- **iOS billing is untested.** Everything in the RevenueCat integration
  has only ever run against Google Play.
