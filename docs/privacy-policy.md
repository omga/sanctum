# Privacy policy — where it lives

**The published policy is not in this repository.** It is:

    ~/Documents/morphostudio/lib/legal/sanctum.ts

served at the permanent `/legal/sanctum/privacy` URL the App Store and
Play listings point at. That file is the only copy, and it is the one to
edit.

This file used to hold a second draft written from the code. Two copies
of a disclosure drift — which is the same argument the app makes for
Settings opening the consent screen itself rather than paraphrasing it —
so the draft was folded into the real document and this is a pointer.

## What has to move together

A change to what leaves the device is four edits, and shipping three of
them is worse than shipping none:

1. **The consent screen** — `advisorConsent*` in `lib/src/l10n/app_*.arb`,
   in all four locales. This is what the user actually reads.
2. **`AdvisorDisclosure.current`** in
   `lib/src/domain/models/advisor_consent.dart`. Bumping it re-asks
   everyone who already agreed, which is the point: their agreement was
   to the old facts.
3. **The policy**, at the path above. Bump its `updated` date.
4. **`store-data-safety.md`**, next to this file, and then the forms
   themselves in both consoles.

The store forms and the policy have to agree line for line. A review
that finds them disagreeing treats it as a misrepresentation rather than
a typo.

## Still open

- **The DeepSeek transfer.** The policy states explicit consent under
  GDPR Article 49(1)(a) as the mechanism for sending a question to be
  processed in China, and carries a `[TODO]` asking counsel to confirm
  that. It is the one paragraph in the document that is a legal
  judgement rather than a description of what the app does.
- **Governing law** in the terms is still a `[TODO]`, and until it is
  filled in the documents are correctly marked `draft: true` — which
  renders a banner saying they must not be submitted to a store.
- **Advisor analytics.** The policy lists every event by name and the
  advisor emits none yet. When it does, that list changes in the same
  commit.
