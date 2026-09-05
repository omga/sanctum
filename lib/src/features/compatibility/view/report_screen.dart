import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/relationship_report.dart';
import 'package:sanctum/src/features/advisor/view/advisor_entry_card.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/direction_bar.dart';
import 'package:sanctum/src/features/compatibility/view_model/report_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// The deep "You & X" report.
///
/// ## Why it reads as a document, not as a second reveal
///
/// The reveal screen is theatre: a dial that counts up, a hexagon that
/// draws itself, a three-second wait that earns the number. Repeating
/// any of that here would make the paid thing look like the free thing
/// with more words. So this is typographic — headings, paragraphs,
/// evidence under each claim — because the value on sale is depth, and
/// depth reads as a document. The only borrowed component is
/// [DirectionBar], which is the one figure the reader already knows how
/// to parse.
///
/// ## Why it is pushed with an object rather than routed
///
/// Same reason `MatchResultScreen.openPair` is: `match.id` is built from
/// both people's names and birth dates, so routing to it by id would put
/// exactly that in a URL, which reaches crash breadcrumbs and OS logs.
/// The handoff already names the existing query-parameter route as a
/// standing hazard; this does not add a second one. Nothing about a
/// purchased report needs deep-linking.
class ReportScreen extends ConsumerWidget {
  /// Creates the screen for [match].
  const ReportScreen({required this.match, super.key});

  /// Opens the report for [match].
  static Future<void> open(BuildContext context, CompatibilityMatch match) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReportScreen(match: match)),
    );
  }

  /// The revealed reading this deepens.
  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final report = ref.watch(relationshipReportProvider(match));

    final access = ref.watch(reportControllerProvider(match));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      // Both the document and the entitlement have to be in before
      // anything renders. Showing the report while access is still
      // loading would flash the paid content at somebody who has not
      // bought it, which is worse than a spinner.
      body: switch ((report, access)) {
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
          Center(
            child: Padding(
              padding: const EdgeInsets.all(SanctumSpacing.xl),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
        (AsyncData(value: final data), AsyncData(value: final state)) =>
          state.isOwned
              ? _Document(report: data)
              : _Locked(
                  report: data,
                  state: state,
                  onUnlock: () {
                    final controller = ref.read(
                      reportControllerProvider(match).notifier,
                    );
                    // A subscriber's included report is claimed, not
                    // bought: no store sheet, no purchase event.
                    return state.isIncluded
                        ? controller.claimIncluded()
                        : controller.buy();
                  },
                ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The offer, shown in place of the document until it is bought.
///
/// ## Why it shows nothing of the report itself
///
/// The reveal screen blurs its locked content deliberately — the user
/// can see a real reading with real numbers waiting, which is what makes
/// them send the invite. That works there because the thing behind the
/// blur is a *page*, and a blurred page still reads as substantial.
///
/// A blurred wall of body text reads as a wall of text. Worse, the value
/// of this SKU is that it is specific, and blurred specificity is
/// indistinguishable from blurred filler. So the offer states plainly
/// what is inside and shows none of it, and the reveal above it — which
/// the user has already read for free — is the evidence that the writing
/// is worth paying for.
class _Locked extends StatefulWidget {
  const _Locked({
    required this.report,
    required this.state,
    required this.onUnlock,
  });

  final RelationshipReport report;
  final ReportUiState state;
  final Future<bool> Function() onUnlock;

  @override
  State<_Locked> createState() => _LockedState();
}

class _LockedState extends State<_Locked> {
  bool _busy = false;

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onUnlock();
    // The provider invalidates itself on success, which rebuilds this
    // widget out of existence — so only a cancellation or a failure
    // reaches here with the widget still mounted.
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final product = widget.state.product;
    final included = widget.state.isIncluded;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        0,
        SanctumSpacing.xl,
        context.navBarClearance,
      ),
      children: [
        Text(
          l10n.reportLockedTitle(widget.report.match.them.name),
          style: type.displaySmall,
        ),
        const SizedBox(height: SanctumSpacing.xs),
        Text(
          l10n.reportSubtitle(
            widget.report.match.pairing,
            widget.report.match.overall,
            verdictLabel(widget.report.match.verdict, l10n),
          ),
          style: type.label.copyWith(color: colors.gold),
        ),
        const SizedBox(height: SanctumSpacing.xl),
        Text(
          // The free-tier line ends on "Yours to keep — no subscription",
          // which is a fine thing to say to somebody deciding whether to
          // subscribe and an insult to somebody who just did.
          included ? l10n.reportLockedBodySubscriber : l10n.reportLockedBody,
          style: type.bodyLarge,
        ),
        const SizedBox(height: SanctumSpacing.xxl),
        if (included) ...[
          Text(
            l10n.reportIncludedBadge.toUpperCase(),
            textAlign: TextAlign.center,
            style: type.caption.copyWith(
              color: colors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          SanctumButton(
            label: l10n.reportIncludedOpen,
            icon: Icons.menu_book_outlined,
            expand: true,
            onPressed: _busy ? null : _unlock,
          ),
          const SizedBox(height: SanctumSpacing.md),
          Text(
            // Says it is being spent, before it is spent. They only get
            // one, and finding that out afterwards is the bad version.
            l10n.reportIncludedNote,
            textAlign: TextAlign.center,
            style: type.caption,
          ),
        ] else if (product == null)
          Text(
            l10n.reportUnavailable,
            style: type.bodyMedium.copyWith(color: colors.textSecondary),
          )
        else ...[
          SanctumButton(
            label: l10n.reportBuy(product.displayPrice),
            icon: Icons.menu_book_outlined,
            expand: true,
            onPressed: _busy ? null : _unlock,
          ),
          const SizedBox(height: SanctumSpacing.md),
          Text(
            l10n.reportLockedNote,
            textAlign: TextAlign.center,
            style: type.caption,
          ),
        ],
      ],
    );
  }
}

class _Document extends StatelessWidget {
  const _Document({required this.report});

  final RelationshipReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final match = report.match;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        0,
        SanctumSpacing.xl,
        // Clears the shell's floating nav pill, which this screen draws
        // underneath. This document ends on a centred caption that wraps
        // to two lines on a 390pt phone, so it is one of the screens
        // where getting the inset wrong is immediately visible.
        context.navBarClearance,
      ),
      children: [
        Text(l10n.reportTitle(match.them.name), style: type.displaySmall),
        const SizedBox(height: SanctumSpacing.xs),
        Text(
          l10n.reportSubtitle(
            match.pairing,
            match.overall,
            verdictLabel(match.verdict, l10n),
          ),
          style: type.label.copyWith(color: colors.gold),
        ),
        const SizedBox(height: SanctumSpacing.xl),
        Text(report.opening, style: type.bodyLarge),

        for (final facet in report.facets) ...[
          const SizedBox(height: SanctumSpacing.xxl),
          _FacetSection(facet: facet),
        ],

        for (final direction in report.directions) ...[
          const SizedBox(height: SanctumSpacing.xxl),
          _Heading(direction.kind.label(l10n)),
          const SizedBox(height: SanctumSpacing.lg),
          DirectionBar(
            reading: match.directions.firstWhere(
              (one) => one.kind == direction.kind,
            ),
            yourName: match.you.name,
            theirName: match.them.name,
            animate: false,
          ),
          const SizedBox(height: SanctumSpacing.lg),
          Text(direction.reading, style: type.bodyMedium),
        ],

        const SizedBox(height: SanctumSpacing.xxl),
        _Heading(l10n.reportSectionMoon),
        const SizedBox(height: SanctumSpacing.xs),
        Text(
          switch (report.moon) {
            final moon? => l10n.reportMoonSigns(
              moon.yourSign.label(l10n),
              moon.theirSign.label(l10n),
            ),
            null => l10n.reportMoonMissing,
          },
          style: type.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: SanctumSpacing.md),
        Text(
          report.moon?.reading ?? report.moonAbsence!,
          style: type.bodyMedium,
        ),

        const SizedBox(height: SanctumSpacing.xxl),
        _Heading(l10n.reportSectionWatch),
        const SizedBox(height: SanctumSpacing.md),
        Text(report.watchFor, style: type.bodyMedium),

        const SizedBox(height: SanctumSpacing.xxl),
        _Heading(l10n.reportSectionClosing),
        const SizedBox(height: SanctumSpacing.md),
        Text(report.closing, style: type.quote),

        // The best surface in the app for this: somebody holding a
        // document they paid for, about one named person, is the most
        // likely user here to have a follow-up question about them.
        const SizedBox(height: SanctumSpacing.xxl),
        AdvisorEntryCard(match: report.match),

        const SizedBox(height: SanctumSpacing.xxl),
        Text(
          l10n.reportDisclaimer,
          textAlign: TextAlign.center,
          style: type.caption,
        ),
      ],
    );
  }
}

/// One facet: the score, what drives it, what it means, and the angles.
class _FacetSection extends StatelessWidget {
  const _FacetSection({required this.facet});

  final ReportFacet facet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: _Heading(facet.facet.label(l10n))),
            Text(
              l10n.matchPercent(facet.score),
              style: type.title.copyWith(color: colors.gold),
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.sm),
        // The standing claim about the axis, identical for everyone. It
        // is what makes the number legible rather than magical, and it
        // is set apart from the reading so nobody mistakes the general
        // for the personal.
        Text(
          facet.mechanism,
          style: type.bodySmall.copyWith(
            color: colors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: SanctumSpacing.md),
        Text(facet.reading, style: type.bodyMedium),
        const SizedBox(height: SanctumSpacing.lg),
        _Contacts(contacts: facet.contacts),
      ],
    );
  }
}

/// The angles a facet's score was computed from.
///
/// Every contact is listed with its real separation, in orb or not.
/// About two facet sections in five have nothing in orb at all, and
/// showing those as bare "no contact" lines would leave a paragraph
/// explaining a score above an empty table — a document that promises to
/// show its working and then shows none. The angle is real either way;
/// only the *name* needs an orb, so the named ones are simply marked.
class _Contacts extends StatelessWidget {
  const _Contacts({required this.contacts});

  final List<ReportContact> contacts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;

    return GlassCard.flat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reportContacts,
            style: type.caption.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          for (final contact in contacts) ...[
            const SizedBox(height: SanctumSpacing.md),
            // A `Wrap` rather than a two-ended `Row`, because both halves
            // are translated and neither has a bound. "your Venus ·
            // their Mars" beside "Square · 4.6° off exact" fits on one
            // line in English on most phones and overflows a 375pt
            // screen the moment either side gets longer — which Russian
            // and Ukrainian both do. This keeps the single line where it
            // fits and drops to two where it does not, so no translator
            // is working to a character budget that is invisible to
            // them.
            Wrap(
              spacing: SanctumSpacing.sm,
              runSpacing: SanctumSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  l10n.reportContactPair(
                    contact.yourPoint.label(l10n),
                    contact.theirPoint.label(l10n),
                  ),
                  style: type.bodySmall,
                ),
                Text(
                  switch (contact) {
                    ReportContact(aspect: final aspect?) =>
                      l10n.reportContactNamed(
                        aspect.aspect.geometry(l10n),
                        aspect.orb.toStringAsFixed(1),
                      ),
                    ReportContact(separation: final degrees?) =>
                      l10n.reportContactApart('${degrees.round()}'),
                    // Only reachable for a body that could not be placed
                    // at all, which today means a Moon with no birth
                    // time — and those contacts are never emitted.
                    _ => '',
                  },
                  style: type.bodySmall.copyWith(
                    color: contact.isInContact
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A small-caps section heading, matching the reveal's `WHAT WORKS`.
class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Text(
      label.toUpperCase(),
      style: type.caption.copyWith(
        color: context.colors.gold,
        letterSpacing: 2,
      ),
    );
  }
}
