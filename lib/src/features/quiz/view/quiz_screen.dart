import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/atoms/date_wheel.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/time_wheel.dart';
import 'package:sanctum/src/design_system/atoms/zodiac_wheel.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_typography.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/zodiac.dart';
import 'package:sanctum/src/features/quiz/view/widgets/quiz_option_card.dart';
import 'package:sanctum/src/features/quiz/view_model/quiz_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// The onboarding quiz.
///
/// One question per screen with a progress bar, because a flow that
/// shows how much is left gets finished and one that does not gets
/// abandoned. Questions cross-fade and slide rather than cutting: the
/// motion is what separates this from a form.
class QuizScreen extends ConsumerWidget {
  /// Creates the quiz.
  const QuizScreen({required this.onFinished, super.key});

  /// Called once every visible question is answered.
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      body: AuroraBackground(
        intensity: 0.85,
        child: Starfield(
          child: SafeArea(
            child: state.when(
   skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (data) => _QuizBody(state: data, onFinished: onFinished),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizBody extends ConsumerWidget {
  const _QuizBody({required this.state, required this.onFinished});

  final QuizUiState state;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final controller = ref.read(quizControllerProvider.notifier);
    final question = state.current;

    if (question == null) {
      // Everything answered — hand off to the payoff screen.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await controller.finish();
        await ref.read(settingsRepositoryProvider).setOnboarded();
        onFinished();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SanctumSpacing.lg,
            SanctumSpacing.sm,
            SanctumSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              Opacity(
                opacity: state.canGoBack ? 1 : 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: colors.textSecondary,
                  onPressed: state.canGoBack
                      ? () => unawaited(controller.back())
                      : null,
                ),
              ),
              Expanded(
                child: _Progress(value: state.progress),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: SanctumMotion.calm,
            switchInCurve: SanctumMotion.enter,
            switchOutCurve: SanctumMotion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _Question(
              key: ValueKey(question.id),
              question: question,
              answers: state.answers,
              questions: state.questions,
              controller: controller,
            ),
          ),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: SanctumMotion.calm,
      curve: SanctumMotion.ease,
      builder: (context, progress, _) => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 3,
          backgroundColor: colors.glassBorder,
          valueColor: AlwaysStoppedAnimation(colors.gold),
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.answers,
    required this.questions,
    required this.controller,
    super.key,
  });

  final QuizQuestion question;
  final QuizAnswers answers;
  final List<QuizQuestion> questions;
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.xl,
        SanctumSpacing.xl,
        SanctumSpacing.xxl,
      ),
      children: [
        Text(question.title, style: type.displaySmall)
            .animate()
            .fadeIn(duration: SanctumMotion.quick)
            .slideY(begin: 0.15, end: 0),
        if (question.subtitle case final subtitle?) ...[
          const SizedBox(height: SanctumSpacing.sm),
          Text(subtitle, style: type.bodyMedium)
              .animate(delay: const Duration(milliseconds: 60))
              .fadeIn(duration: SanctumMotion.quick),
        ],
        const SizedBox(height: SanctumSpacing.xl),
        _Body(
          question: question,
          answers: answers,
          questions: questions,
          controller: controller,
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.question,
    required this.answers,
    required this.questions,
    required this.controller,
  });

  final QuizQuestion question;
  final QuizAnswers answers;
  final List<QuizQuestion> questions;
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    switch (question.kind) {
      case QuizQuestionKind.single:
      case QuizQuestionKind.multi:
        return _Choices(
          question: question,
          answers: answers,
          controller: controller,
        );
      case QuizQuestionKind.date:
        return _BirthDate(question: question, controller: controller);
      case QuizQuestionKind.time:
        return _BirthTimeStep(
          question: question,
          // Seeded from the stored answer so stepping back shows what
          // the user actually said, rather than silently resetting them
          // to "I do not know" and making them answer twice.
          initial: answers.times[question.id],
          controller: controller,
        );
      case QuizQuestionKind.text:
        return _TextEntry(question: question, controller: controller);
      case QuizQuestionKind.interstitial:
        return _Interstitial(
          question: question,
          answers: answers,
          questions: questions,
          controller: controller,
        );
    }
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.question,
    required this.answers,
    required this.controller,
  });

  final QuizQuestion question;
  final QuizAnswers answers;
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final multi = question.kind == QuizQuestionKind.multi;
    final chosen = answers.optionsFor(question.id);

    return Column(
      children: [
        for (final (index, option) in question.options.indexed) ...[
          QuizOptionCard(
                option: option,
                multi: multi,
                selected: chosen.contains(option.id),
                // Single-select answers and advances on the tap.
                // Multi-select only ticks: the question is not finished
                // until Continue, so ticking must leave the user where
                // they are however many options they go on to add.
                onTap: () => unawaited(
                  multi
                      ? controller.toggle(question.id, option.id)
                      : controller.choose(question.id, [option.id]),
                ),
              )
              .animate(delay: Duration(milliseconds: 40 * index))
              .fadeIn(duration: SanctumMotion.quick)
              .slideY(begin: 0.12, end: 0),
          const SizedBox(height: SanctumSpacing.md),
        ],
        if (multi) ...[
          const SizedBox(height: SanctumSpacing.md),
          SanctumButton(
            label: context.l10n.commonContinue,
            expand: true,
            // Nothing chosen is a real answer to "what are you here
            // for?" — but it personalises nothing, so require one.
            onPressed: chosen.isEmpty
                ? null
                : () => unawaited(controller.advance()),
          ),
        ],
      ],
    );
  }
}

class _Interstitial extends StatelessWidget {
  const _Interstitial({
    required this.question,
    required this.answers,
    required this.questions,
    required this.controller,
  });

  final QuizQuestion question;
  final QuizAnswers answers;
  final List<QuizQuestion> questions;
  final QuizController controller;

  /// The labels the user actually chose, in the order they were offered.
  ///
  /// Echoing their own words back is the whole job of this screen. A
  /// generic "we'll work on it" reads as filler; their own three answers
  /// listed back read as being heard.
  List<String> get _echo {
    final goals = questions.where((q) => q.id == 'goals').firstOrNull;
    if (goals == null) return const [];

    final chosen = answers.optionsFor('goals');
    return goals.options
        .where((o) => chosen.contains(o.id))
        .map((o) => o.label)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final echoed = _echo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, label) in echoed.indexed)
          Padding(
                padding: const EdgeInsets.only(bottom: SanctumSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: colors.gold,
                      size: 22,
                    ),
                    const SizedBox(width: SanctumSpacing.md),
                    Expanded(child: Text(label, style: type.bodyLarge)),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 140 * index))
              .fadeIn(duration: SanctumMotion.calm)
              .slideX(begin: 0.08, end: 0),
        SizedBox(height: SanctumSpacing.lg + echoed.length * 4),
        SanctumButton(
              label: context.l10n.commonContinue,
              expand: true,
              onPressed: () => unawaited(controller.acknowledge(question.id)),
            )
            .animate(delay: Duration(milliseconds: 140 * echoed.length + 120))
            .fadeIn(),
      ],
    );
  }
}

class _TextEntry extends StatefulWidget {
  const _TextEntry({required this.question, required this.controller});

  final QuizQuestion question;
  final QuizController controller;

  @override
  State<_TextEntry> createState() => _TextEntryState();
}

class _TextEntryState extends State<_TextEntry> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        TextField(
          controller: _field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          style: context.type.displaySmall,
          onChanged: (_) => setState(() {}),
          onSubmitted: _submit,
          decoration: InputDecoration(
            hintText: context.l10n.quizNameHint,
            hintStyle: context.type.displaySmall.copyWith(
              color: colors.textTertiary,
            ),
            filled: true,
            fillColor: colors.glassFill,
            border: const OutlineInputBorder(
              borderRadius: SanctumRadii.mdAll,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: SanctumSpacing.xl),
        SanctumButton(
          label: context.l10n.commonContinue,
          expand: true,
          onPressed: _field.text.trim().isEmpty
              ? null
              : () => _submit(_field.text),
        ),
      ],
    );
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    unawaited(widget.controller.chooseText(widget.question.id, value));
  }
}

class _BirthDate extends StatefulWidget {
  const _BirthDate({required this.question, required this.controller});

  final QuizQuestion question;
  final QuizController controller;

  @override
  State<_BirthDate> createState() => _BirthDateState();
}

class _BirthDateState extends State<_BirthDate> {
  DateTime _date = DateTime(1996, 6, 15);

  ZodiacSign get _sign => Zodiac.signFor(_date);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Column(
      children: [
        ZodiacWheel(
          glyphs: [for (final sign in ZodiacSign.values) sign.glyph],
          activeIndex: ZodiacSign.values.indexOf(_sign),
        ),
        const SizedBox(height: SanctumSpacing.md),
        // The payoff, updating live as they scroll. This lands before we
        // have asked for anything, which is the entire point of putting
        // the birth date here rather than after the paywall.
        AnimatedSwitcher(
          duration: SanctumMotion.quick,
          child: Column(
            key: ValueKey(_sign),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _sign.glyph,
                    style: SanctumTypography.symbol(30, colors.gold),
                  ),
                  const SizedBox(width: SanctumSpacing.md),
                  Text(
                    _sign.label(context.l10n),
                    style: type.displaySmall,
                  ),
                ],
              ),
              Text(
                context.l10n.quizElementSign(_sign.element.label(context.l10n)),
                style: type.caption.copyWith(color: colors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SizedBox(
          height: 170,
          child: BirthDateWheels(
            date: _date,
            onChanged: (date) => setState(() => _date = date),
          ),
        ),
        const SizedBox(height: SanctumSpacing.lg),
        SanctumButton(
          label: context.l10n.commonContinue,
          expand: true,
          onPressed: () => unawaited(
            widget.controller.chooseDate(widget.question.id, _date),
          ),
        ),
      ],
    );
  }
}

/// The birth time question.
///
/// Sits immediately after the birth date, while the user is still in the
/// frame of mind of answering factual questions about themselves, and
/// before the flow turns back to preferences.
///
/// It opens on "I do not know" rather than on a set of wheels. That is
/// the honest default — most people genuinely do not know — and it means
/// the fast path through this screen is one tap for the majority, with
/// the wheels appearing only for the minority who can actually answer.
class _BirthTimeStep extends StatefulWidget {
  const _BirthTimeStep({
    required this.question,
    required this.controller,
    this.initial,
  });

  final QuizQuestion question;
  final QuizController controller;

  /// What the user said last time, if they have been here before.
  final BirthTime? initial;

  @override
  State<_BirthTimeStep> createState() => _BirthTimeStepState();
}

class _BirthTimeStepState extends State<_BirthTimeStep> {
  late int? _minuteOfDay = widget.initial?.minuteOfDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final minutes = _minuteOfDay;

    return Column(
      children: [
        Icon(Icons.nightlight_round, color: colors.gold, size: 40),
        const SizedBox(height: SanctumSpacing.md),
        Text(
          minutes == null
              ? context.l10n.quizBirthTimeUnknownHint
              : context.l10n.quizBirthTimeKnownHint,
          textAlign: TextAlign.center,
          style: type.bodyMedium,
        ),
        const SizedBox(height: SanctumSpacing.lg),
        BirthTimeField(
          minuteOfDay: minutes,
          onChanged: (value) => setState(() => _minuteOfDay = value),
        ),
        const SizedBox(height: SanctumSpacing.xl),
        SanctumButton(
          label: context.l10n.commonContinue,
          expand: true,
          onPressed: () => unawaited(
            widget.controller.chooseTime(
              widget.question.id,
              minutes == null
                  ? BirthTime.unknown
                  : BirthTime(minuteOfDay: minutes),
            ),
          ),
        ),
      ],
    );
  }
}
