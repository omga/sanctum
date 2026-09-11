# Sanctum — roadmap

Written 2026-08-19, the day the first real Play purchase went through.
Restructured 2026-09-04, when a third revenue tier turned up.
**§1 shipped the same day** — see the note on it below.

Sections are ranked by how much each changes the business. That is **not
the order to build them in** — the item with the highest ceiling (§2) is
the one that should not be started next.

### Order of work

1. ~~**§3, the days-not-weeks items.**~~ **Still the next thing.** §1 was
   built ahead of it, which was out of order — the reframing, the
   paywall headline personalised from quiz answers, the price test and
   the trial-length test are all still open, all still days rather than
   weeks, and all still multiply whatever traffic §4 produces. The
   funnel inversion was considered and deferred; see §3.1.
2. ~~**§1, the relationship one-off.**~~ **Shipped 2026-09-04.** One
   consumable SKU, no backend, no ledger. It has produced no revenue
   data yet, so the question it was built to answer — whether
   relationship intent monetises beyond the subscription — is still
   open.
3. **§2, the advisor.** The largest build here. Worth starting once §1
   has shown the intent is real and has produced actual user questions
   to design a prompt around. It has not yet done either.

Doing §3 and §1 first is not a delay to §2. It is what turns §2 from a
guess into a decision — and if the intent turns out not to be there, it
is the cheapest possible way to find out before building a backend, a
ledger, a consent flow and an AI Act exposure.

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
is the one with a ceiling high enough to matter. Everything in §2 follows
from that.

**Sanctum's own handoff has said this since day one** — "the
relationship/astrology wedge — compatibility readings, AI advisor sold as
credits — is where the category's money actually is and is **not
built**." Compatibility is built now. The advisor is not.

### There is a second ceiling, and it is cheaper

Added 2026-09-04. Sure sells one-, three-, five- and ten-year
relationship reports, the ten-year listed near $150 and the five-year
near $80.

A listed price is a hypothesis, not a result: nothing public says those
SKUs convert at volume, and it would be a mistake to read them as proof.
What they *are* good evidence of is that the category believes
**relationship analysis carries one-off pricing power that a
subscription does not capture** — enough to price an order of magnitude
above a monthly plan and see who bites.

That argues for three tiers rather than two:

- **Free** — the daily card and one compatibility reading, still gated
  by an invite, because the gate is the viral loop and not a paywall
  accident.
- **Subscription** — unlimited compatibility, forecasts, rituals, sound.
  This is the habit, and it caps at roughly £40/year.
- **One-off** — a deep report about one named person. This is the
  intent, it is uncapped, and it is new to this document.

The intent tier is worth more than its price suggests, because it is
bought at a different moment. Somebody opening a natal chart came to
learn astrology. Somebody typing a specific name came with a person and
a question about that person, and wants an answer now rather than a
monthly plan.

---

## 1. The relationship one-off — the near-term revenue line

**A deep "You & X" report about one named person, sold once.**

> **Shipped 2026-09-04.** `sanctum.report.relationship`, a consumable,
> priced from the store. What follows is the reasoning it was built on,
> kept because the decisions are still live. Three things changed on
> contact with reality:
>
> - **A subscriber's first report is included.** Not planned, and not
>   generosity: the compatibility lock card sells Premium as "reads you
>   against anyone, as often as you like", so a second price at the foot
>   of the reading they just paid for reads as a bait and switch. One
>   included report removes that moment; the second onwards is still
>   sold, so subscribers still meet the price. See `handoff.md`.
> - **The offer is never shown on a first reveal.** That one is bought
>   with an invite, and the invite is the acquisition mechanic — putting
>   a purchase ask on the same screen cannibalises it.
> - **Consumables do not restore.** A reinstall loses every purchased
>   report. The locked screen says so before the money changes hands,
>   which is the honest minimum and not a solution. Deciding between a
>   backend that maps customers to pairings and granting on request is
>   still open, and should be settled before the volume makes it support
>   work.
>
> Nothing about the revenue question is answered yet — no report has
> been sold to a real user.

### Why this ranks above the advisor

Same buying intent, a fraction of the build:

- **No backend.** No proxy, no API key to keep out of the binary, no
  per-message inference cost.
- **No credit ledger.** A report is one consumable SKU. No balances, no
  top-ups, no expiry policy, no "what happens on a refund", no "what
  happens when it restores on a second device". RevenueCat handles
  consumables and `purchases_flutter` already supports them.
- **No new engine.** `CompatibilityCalculator` already produces the
  aspect, six facets, both directional splits and — when both birth
  times are known — the Moon. The report is depth and copy on top of
  numbers the app computes today, for free, offline.
- **No consent screen**, because nothing leaves the device.

If it sells, §2 gains a proven high-intent surface to attach to and a
corpus of real questions to design its prompt around. If it does not
sell, this is the cheapest available way to learn that relationship
intent does not monetise past the subscription — and it saves the
largest build on this list.

### Sell depth, not prophecy

The competitor's headline SKU is a *ten-year* report. Do not copy that
shape.

A decade-long forecast about a named private individual is the most
overclaiming product available to this app, and it runs straight into
the posture everything else is built on: quiet days are admitted, the
reveal captions name work that actually happens, the score range is
honest but not cruel. One prophecy SKU would make all of that a
marketing position rather than a principle.

The honest version of the same value is **specificity, not horizon**.
"You & Alex" at real length — every facet explained, both directional
splits, what each planet contact actually does between these two charts,
what to watch and when it will show up — is defensible, differentiated,
and requires no claim about 2036. Price it on depth.

### The consent problem this creates

A report reads a **named private person who never agreed to it**. That is
already true of `PartnerEntryScreen` and is currently defensible on one
specific ground: the data never leaves the phone.

That ground disappears the moment the same person's birth data is sent
to a model. §2's privacy gate has to cover the third party explicitly,
not just the user — and this is a reason to ship the offline report
first and let it establish the norm.


### A second one-off: the palm report

Decided 2026-09-11, not built. The palm scan and its short reading are free
for everyone; a **full palm report** is sold as a one-time purchase and
included for subscribers. It is a **non-consumable**, unlike this section's
report, because a palm scan is never stored — a report bought per scan would
vanish when the screen closes, and consumables do not restore. Reasoning,
honesty limits and other experiments are in `.claude/palm.md` §6.

---

## 2. The advisor — the one bet that changes the curve

> **Built, 2026-09. See `.claude/advisor.md`** for the design, the
> running order and what is left. This section is kept as the argument
> that justified it; where the two disagree, `advisor.md` is what
> shipped.
>
> Three things here were decided differently in the end:
> **the economy is a shared message balance**, not per-conversation
> credits — five free a week for subscribers, $2.99 for five more;
> **there is an Ask tab**, added after seeing on a device that entry
> points at the foot of scrolled screens are undiscoverable, though the
> contextual cards remain the routes that convert; and **the model is
> DeepSeek**, behind a Supabase Edge Function.

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

### Build the economy last

Credits are the right primitive for chat and the wrong one for a *first*
purchase. A ledger is infrastructure — balances, top-ups, expiry, what
happens on a refund, what happens when a purchase restores on a second
device — and none of it answers whether anybody wants to ask an
astrologer anything.

§1 buys that answer with a single consumable and no ledger at all. Build
the economy on the day there is more than one variable-cost thing to
spend it on, which is the day chat ships and not before.

One consequence worth holding onto: **price reports in money and chat in
credits.** Virtual currency obscures unit cost — that is precisely what
makes it work commercially and precisely what sits badly with an app
whose differentiation is not overclaiming. EU consumer-protection
attention on virtual currencies has also been sharpening. A report with
a real price attached is consistent with everything else this product
says about itself; a report priced at "40 crystals" is not.

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

§1's report is the better version of that surface still: somebody who
has just paid for a deep read on one named person is the single most
likely user in the app to have a follow-up question about that person,
and they are holding the answer to "what should the prompt contain"
while they ask it.

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
entertainment disclaimer still is not at first launch (§7). The framing
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

## 3. Cheap conversion work, before any new feature

These are days, not weeks, and they multiply whatever traffic the
content produces. Do them first.

1. **Invert the funnel: their name first, not yours.** The app opens by
   asking for the user's own birth date and building a natal chart. The
   stronger opening asks for *someone else's* name and birthday.

   One version starts with astrology, the other starts with a person and
   a feeling, and only the second is a hook somebody films. It is also
   days of work rather than weeks: `PartnerEntryScreen`, the match
   engine, the reveal sequence and the carousel all exist already. What
   changes is order and copy, not computation.

   A birth date on its own already buys a real teaser — their sign,
   element, Venus and Mars are all computable with no input from the
   user at all. So: their name and date → a genuine read on *them* →
   "now add yours to see what happens between you." Value first, then
   the ask, which is also what makes the ask land.

   **Keep the invite gate.** The first reading currently costs an invite
   rather than nothing (`handoff.md` §3) and that is an acquisition
   mechanic, not a paywall accident. A crush funnel that ends in a plain
   free reading throws away the loop it should be feeding.

2. **Reframe compatibility as investigation, not analysis.** "You are
   78% compatible" is a verdict. "Why can't I stop thinking about Alex?"
   is a question the reader already arrived with. The second is what
   makes somebody tap — and the engine already answers it.

   `DirectionalReading` computes who wants it more and who holds the
   power, and the copy is already written, in four languages:

   > You want this more than they do. That is not a flaw, but it is a
   > fact, and pretending otherwise is where the trouble starts.

   > One of you has already told their friends.

   That is the emotional-investigation product, shipping today, filed as
   a supporting detail underneath a hexagon chart. Promoting it to the
   headline is a reordering of `match_result_screen.dart` plus new copy
   keys. There is no engine work in it at all.

   The score keeps its place as *evidence* rather than as the headline.
   It is what makes the claim feel measured instead of invented, which
   is the entire reason the numbers were made honest in the first place.

3. **Personalise the paywall headline from the quiz.** Already the
   highest-value remaining conversion work in the old next-steps list.
   The answers are persisted and `ReadingComposer` already selects copy
   from them; the paywall simply does not read them. Someone who ticked
   "I keep repeating a pattern" should see that sentence back at the
   moment they are asked to pay.
4. **Run a price test.** RevenueCat Experiments can serve different
   offerings to different cohorts with no app update. The current
   £6.99/£39.99 are placeholders that have never been tested against
   anything. Test the annual price first — annual mix is the single
   biggest lever on LTV in a subscription business this size.
5. **Test trial length.** 7 days is a default, not a decision.
6. **Fix the store title.** `Sanctum` alone wastes 22 of 30 characters
   of the most heavily weighted keyword field on Play. Something like
   `Sanctum: Zodiac Compatibility` indexes for the term the app is
   actually about.
7. **Screenshots.** The first two drive most of the install decision.
   They should be the compatibility reveal and the "who wants it more"
   split, not the Today screen — lead with the thing people share.
8. **Win-back offers.** RevenueCat supports them on iOS; a lapsed
   subscriber is the cheapest customer available.

---

## 4. Acquisition

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

   **On sequencing this against §2:** localisation is a bet on traffic,
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

## 5. Premium features worth building, ranked

Only after §1–§3.

1. **Full birth chart report**, sold as a one-off unlock rather than
   bundled. The ephemeris already computes everything needed; this is
   presentation plus copy, and one-off unlocks convert people who will
   never take a subscription.

   **Ships after §1, not before it.** It is the same product shape
   pointed at weaker intent: a report about *you* is bought by somebody
   already interested in astrology, a report about *you and a named
   person* is bought by somebody with a question about that person.
   Build the higher-intent one first and this reuses its layout, its
   export and its purchase plumbing.
2. **Compatibility history and comparison.** "You have read eleven
   people. Here is who scores highest, and what your pattern is." Uses
   only data already stored, and it is the kind of summary people
   screenshot.
3. **Transit calendar** — the next month of notable transits, with the
   good days marked. `TransitCalculator` already knows this; the app
   just never shows more than tomorrow. This is the strongest retention
   surface that requires no new engine.

   Asked about again 2026-09-04 as "yesterday, tomorrow, week, month on
   the main screen, all Premium". **Week and month, yes — this item.
   Yesterday, no, and tomorrow is not yours to sell.**

   *Yesterday* has close to negative value: nobody needs telling what
   yesterday was going to be like, and a prediction shown after the fact
   invites the reader to check it against what happened. Every other
   honesty decision in this app — quiet days admitted, captions naming
   real work, a score floor that is kind but not a lie — exists to avoid
   exactly that.

   *Tomorrow already ships, free.* `transit_panel.dart` calls it "the
   only honest open loop the app has"; it is why there is a point in
   opening the app on a particular day. Moving it behind the paywall
   takes something users already have, which is how a retention feature
   becomes a one-star review.

   Worth naming why a month of transits is fine when §1 refuses a
   ten-year relationship forecast: **a transit is where Saturn will be.**
   That is astronomy, pinned in tests against documented events. A
   long-range relationship forecast is a claim about two people. Same
   shape on screen, completely different epistemics.
4. **Energy insights over time.** The paywall already advertises
   "insights" and `EnergyPatternCalculator` already refuses to speak
   without enough data, which is the hard part. What is missing is a
   chart.
5. **Palm and face reading.** Ranked #1 for virality in `handoff.md` —
   "the camera is on the person, the filming *is* the content". Also the
   largest build on this list and the one with the most obvious
   accuracy-honesty tension. Evaluate after video export.

---

## 6. Explicitly not worth building

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
- **Profiles for other people, with their own daily horoscope.**
  Proposed 2026-09-04 as avatars at the top of Today, switching whose
  day you are reading. Declined, for the reason §5.1 already gives about
  the solo birth-chart report: it takes the input that produces the
  highest-intent product in the app — their birth date, inside a
  compatibility reading — and points it at a weaker one. Somebody
  checking their partner's horoscope is a lower-intent buyer than
  somebody asking about *them and their partner*.

  It also breaks the retention machinery rather than extending it. The
  daily notification carries one composed transit line and fires at the
  hour one `rhythm` answer chose; streaks are one person's. With N
  profiles, neither has an answer. And Today leads with the transit
  precisely because "it is the only thing on this screen that is true of
  *this* user on *this* day" — a switcher turns a ritual into a lookup.

  **The narrow version is worth building instead:** a "their day" section
  inside a compatibility reading, where the chart is already loaded and
  the intent is already higher. No profile system, no notification
  redesign, no change to Today. If avatars are wanted, source them from
  `CompatibilityState.matches` — the people already checked — rather
  than inventing a profile concept to hold them.

---

## 7. Engineering debt that will bite

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
