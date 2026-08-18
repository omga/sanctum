import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/date_wheel.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/celebrity_tile.dart';
import 'package:sanctum/src/features/compatibility/view_model/compatibility_view_model.dart';

/// Picks one person — from the catalogue, or typed in.
///
/// Pops with the chosen [MatchPerson], or null if the user backs out. It
/// is a route rather than a sheet because it has to hold a search field,
/// a long list and a date wheel, and a sheet tall enough for all three
/// is a screen wearing a disguise.
class PersonPickerScreen extends ConsumerStatefulWidget {
  /// Creates the picker.
  const PersonPickerScreen({required this.title, super.key});

  /// What we are asking for, e.g. "First person".
  final String title;

  /// Opens the picker and resolves to the chosen person, if any.
  static Future<MatchPerson?> open(BuildContext context, String title) {
    return Navigator.of(context).push<MatchPerson>(
      MaterialPageRoute<MatchPerson>(
        builder: (_) => PersonPickerScreen(title: title),
      ),
    );
  }

  @override
  ConsumerState<PersonPickerScreen> createState() => _PersonPickerState();
}

class _PersonPickerState extends ConsumerState<PersonPickerScreen> {
  final _name = TextEditingController();
  String _query = '';
  DateTime _date = DateTime(1996, 6, 15);
  bool _manual = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(MatchPerson person) => Navigator.of(context).pop(person);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final state = ref.watch(compatibilityControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title, style: type.title),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: AuroraBackground(
        child: Starfield(
          child: SafeArea(
            child: state.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (data) => _manual
                  ? _manualEntry(colors, type)
                  : _catalogue(data.celebrities, type),
            ),
          ),
        ),
      ),
    );
  }

  Widget _catalogue(List<Celebrity> celebrities, SanctumTypography type) {
    final needle = _query.trim().toLowerCase();
    final matching = [
      for (final one in celebrities)
        if (needle.isEmpty || one.name.toLowerCase().contains(needle)) one,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        0,
        SanctumSpacing.xl,
        SanctumSpacing.huge + SanctumSpacing.xxl,
      ),
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search by name',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SanctumButton(
          label: 'Enter a name and birth date',
          icon: Icons.edit_outlined,
          variant: SanctumButtonVariant.ghost,
          expand: true,
          onPressed: () => setState(() => _manual = true),
        ),
        const SizedBox(height: SanctumSpacing.xl),
        for (final one in matching) ...[
          CelebrityTile(
            celebrity: one,
            onTap: () => _pick(
              MatchPerson(
                name: one.name,
                birthDate: one.birthDate,
                celebrityId: one.id,
              ),
            ),
          ),
          const SizedBox(height: SanctumSpacing.sm),
        ],
        if (matching.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: SanctumSpacing.xxl),
            child: Text(
              'Nobody by that name. Enter their birth date instead.',
              textAlign: TextAlign.center,
              style: type.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _manualEntry(SanctumColors colors, SanctumTypography type) {
    final sign = Zodiac.signFor(_date);
    final ready = _name.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(SanctumSpacing.xl),
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Their name'),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        Center(
          child: Text(
            '${sign.displayName} · ${sign.element.displayName}',
            style: type.caption.copyWith(color: colors.gold, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: SanctumSpacing.md),
        SizedBox(
          height: 190,
          child: BirthDateWheels(
            date: _date,
            onChanged: (date) => setState(() => _date = date),
          ),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SanctumButton(
          label: 'Use this person',
          expand: true,
          onPressed: ready
              ? () => _pick(
                  MatchPerson(name: _name.text.trim(), birthDate: _date),
                )
              : null,
        ),
        const SizedBox(height: SanctumSpacing.sm),
        SanctumButton(
          label: 'Back to the catalogue',
          variant: SanctumButtonVariant.quiet,
          expand: true,
          onPressed: () => setState(() => _manual = false),
        ),
      ],
    );
  }
}
