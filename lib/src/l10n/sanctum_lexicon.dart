import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/l10n/generated/app_localizations.dart';

/// How the domain's enums are spoken to a user.
///
/// ## Why the names are not on the enums
///
/// `domain/` is pure Dart — no Flutter — which is the rule the whole
/// architecture rests on. `AppLocalizations` is a Flutter class, so a
/// localised name simply cannot live on `ZodiacSign`.
///
/// That constraint turns out to be the right design anyway. An enum's
/// job is to be a stable identity; how it is *said* is presentation, and
/// it changes with the reader. The enums keep their English
/// `displayName` as the authoring source and a debug label — it is what
/// the ARB was written from — and everything a user reads comes through
/// here.
///
/// ## The rule
///
/// **No widget calls `.displayName`.** If one does, that string is
/// invisible to translation and will ship in English inside an otherwise
/// translated screen — the failure is silent, looks like a typo, and is
/// found by users rather than by tests.
///
/// Every switch below is exhaustive on purpose. Adding a value to any of
/// these enums breaks compilation here, which is the cheapest possible
/// reminder that it also needs a line in `app_en.arb`.
extension ZodiacSignL10n on ZodiacSign {
  /// The sign's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    ZodiacSign.aries => l10n.signAries,
    ZodiacSign.taurus => l10n.signTaurus,
    ZodiacSign.gemini => l10n.signGemini,
    ZodiacSign.cancer => l10n.signCancer,
    ZodiacSign.leo => l10n.signLeo,
    ZodiacSign.virgo => l10n.signVirgo,
    ZodiacSign.libra => l10n.signLibra,
    ZodiacSign.scorpio => l10n.signScorpio,
    ZodiacSign.sagittarius => l10n.signSagittarius,
    ZodiacSign.capricorn => l10n.signCapricorn,
    ZodiacSign.aquarius => l10n.signAquarius,
    ZodiacSign.pisces => l10n.signPisces,
  };
}

/// Names for the four classical elements.
extension ZodiacElementL10n on ZodiacElement {
  /// The element's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    ZodiacElement.fire => l10n.elementFire,
    ZodiacElement.earth => l10n.elementEarth,
    ZodiacElement.air => l10n.elementAir,
    ZodiacElement.water => l10n.elementWater,
  };
}

/// Names for the eight moon phases.
extension MoonPhaseL10n on MoonPhase {
  /// The phase's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    MoonPhase.newMoon => l10n.moonPhaseNewMoon,
    MoonPhase.waxingCrescent => l10n.moonPhaseWaxingCrescent,
    MoonPhase.firstQuarter => l10n.moonPhaseFirstQuarter,
    MoonPhase.waxingGibbous => l10n.moonPhaseWaxingGibbous,
    MoonPhase.fullMoon => l10n.moonPhaseFullMoon,
    MoonPhase.waningGibbous => l10n.moonPhaseWaningGibbous,
    MoonPhase.lastQuarter => l10n.moonPhaseLastQuarter,
    MoonPhase.waningCrescent => l10n.moonPhaseWaningCrescent,
  };
}

/// Names for the seven sign-to-sign aspects.
extension ZodiacAspectL10n on ZodiacAspect {
  /// The chip that names the reading, e.g. "Magnetic".
  String label(AppLocalizations l10n) => switch (this) {
    ZodiacAspect.conjunction => l10n.aspectConjunction,
    ZodiacAspect.semiSextile => l10n.aspectSemiSextile,
    ZodiacAspect.sextile => l10n.aspectSextile,
    ZodiacAspect.square => l10n.aspectSquare,
    ZodiacAspect.trine => l10n.aspectTrine,
    ZodiacAspect.quincunx => l10n.aspectQuincunx,
    ZodiacAspect.opposition => l10n.aspectOpposition,
  };
}

/// Names for the six compatibility facets.
extension CompatibilityFacetL10n on CompatibilityFacet {
  /// The hexagon axis label. One short word in every language.
  String label(AppLocalizations l10n) => switch (this) {
    CompatibilityFacet.spark => l10n.facetSpark,
    CompatibilityFacet.vibe => l10n.facetVibe,
    CompatibilityFacet.trust => l10n.facetTrust,
    CompatibilityFacet.drama => l10n.facetDrama,
    CompatibilityFacet.depth => l10n.facetDepth,
    CompatibilityFacet.future => l10n.facetFuture,
  };
}

/// Headings for the two directional readings.
extension DirectionKindL10n on DirectionKind {
  /// The row heading over a lopsided split.
  String label(AppLocalizations l10n) => switch (this) {
    DirectionKind.pull => l10n.directionPull,
    DirectionKind.power => l10n.directionPower,
  };
}

/// Names for the five energy levels.
extension EnergyLevelL10n on EnergyLevel {
  /// The level's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    EnergyLevel.depleted => l10n.energyDepleted,
    EnergyLevel.low => l10n.energyLow,
    EnergyLevel.steady => l10n.energySteady,
    EnergyLevel.open => l10n.energyOpen,
    EnergyLevel.radiant => l10n.energyRadiant,
  };
}

/// Names for the four journal entry kinds.
extension JournalKindL10n on JournalKind {
  /// The kind's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    JournalKind.gratitude => l10n.journalKindGratitude,
    JournalKind.manifestation => l10n.journalKindManifestation,
    JournalKind.reflection => l10n.journalKindReflection,
    JournalKind.ritual => l10n.journalKindRitual,
  };
}

/// Section headings in the celebrity picker.
extension CelebrityGroupL10n on CelebrityGroup {
  /// The group's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    CelebrityGroup.music => l10n.celebrityGroupMusic,
    CelebrityGroup.screen => l10n.celebrityGroupScreen,
    CelebrityGroup.influencer => l10n.celebrityGroupInfluencer,
    CelebrityGroup.sport => l10n.celebrityGroupSport,
  };
}

/// Names for the seven chakras.
extension ChakraL10n on Chakra {
  /// The chakra's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    Chakra.root => l10n.chakraRoot,
    Chakra.sacral => l10n.chakraSacral,
    Chakra.solarPlexus => l10n.chakraSolarPlexus,
    Chakra.heart => l10n.chakraHeart,
    Chakra.throat => l10n.chakraThroat,
    Chakra.thirdEye => l10n.chakraThirdEye,
    Chakra.crown => l10n.chakraCrown,
  };
}

/// Names for the six bodies the ephemeris computes.
extension PlanetL10n on Planet {
  /// The planet's name in the reader's language.
  String label(AppLocalizations l10n) => switch (this) {
    Planet.sun => l10n.planetSun,
    Planet.mercury => l10n.planetMercury,
    Planet.venus => l10n.planetVenus,
    Planet.mars => l10n.planetMars,
    Planet.jupiter => l10n.planetJupiter,
    Planet.saturn => l10n.planetSaturn,
  };
}

/// The unit a subscription is billed in.
extension BillingPeriodL10n on BillingPeriod {
  /// The word after the slash in "£6.99 / month".
  String unitLabelIn(AppLocalizations l10n) => switch (this) {
    BillingPeriod.monthly => l10n.billingPeriodMonth,
    BillingPeriod.yearly => l10n.billingPeriodYear,
    BillingPeriod.lifetime => l10n.billingPeriodOnce,
  };
}
