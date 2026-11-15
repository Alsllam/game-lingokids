import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/speaker.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/item_visual_view.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../../../catalog/domain/entities/catalog.dart';
import '../cubit/choice_cubit.dart';
import '../cubit/game_feedback.dart';
import 'game_template.dart';

/// Template 1: the mascot names something, the child taps the right picture.
class ChoiceGame extends StatelessWidget {
  const ChoiceGame({
    super.key,
    required this.bundle,
    required this.onFeedback,
    required this.onFinished,
  });

  final ActivityBundle bundle;
  final GameFeedbackCallback onFeedback;
  final GameFinishedCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChoiceCubit(bundle: bundle, random: Random()),
      child: _ChoiceView(onFeedback: onFeedback, onFinished: onFinished),
    );
  }
}

class _ChoiceView extends StatefulWidget {
  const _ChoiceView({required this.onFeedback, required this.onFinished});

  final GameFeedbackCallback onFeedback;
  final GameFinishedCallback onFinished;

  @override
  State<_ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<_ChoiceView> {
  /// How long the child may hesitate before getting a clue.
  static const _hintAfter = Duration(seconds: 7);

  Timer? _idleTimer;

  /// True while the right answer is gently pulsing as a clue.
  bool _hint = false;

  @override
  void initState() {
    super.initState();
    // Say the first word once the screen is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sayTarget(context.read<ChoiceCubit>().state);
      _restartIdleTimer();
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _sayTarget(ChoiceState state) {
    final language = context.languageCode;
    context.read<Speaker>().speak(
      state.round.target.name.of(language),
      languageCode: language,
    );
    widget.onFeedback(GameFeedback.prompt);
  }

  /// Any activity (a tap, a new round) pushes the clue further away.
  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_hint) setState(() => _hint = false);
    _idleTimer = Timer(_hintAfter, _giveHint);
  }

  /// The child has been stuck for a while: repeat the word and make the
  /// right answer pulse. It costs no stars; the aim is to keep them playing.
  void _giveHint() {
    if (!mounted) return;
    final state = context.read<ChoiceCubit>().state;
    if (state.solved || state.finished) return;
    setState(() => _hint = true);
    _sayTarget(state);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        // A new round started: say the new word.
        BlocListener<ChoiceCubit, ChoiceState>(
          listenWhen: (previous, current) => previous.index != current.index,
          listener: (context, state) {
            _sayTarget(state);
            _restartIdleTimer();
          },
        ),
        // Right / wrong / finished: let the host screen react.
        BlocListener<ChoiceCubit, ChoiceState>(
          listenWhen: (previous, current) =>
              previous.feedbackTick != current.feedbackTick,
          listener: (context, state) {
            widget.onFeedback(state.feedback);
            if (state.finished) {
              _idleTimer?.cancel();
              widget.onFinished(state.stars);
            } else if (state.solved) {
              _idleTimer?.cancel();
              if (_hint) setState(() => _hint = false);
            } else {
              _restartIdleTimer();
            }
          },
        ),
      ],
      child: BlocBuilder<ChoiceCubit, ChoiceState>(
        builder: (context, state) {
          final round = state.round;
          final name = round.target.name.of(context.languageCode);
          return Column(
            children: [
              RoundDots(total: state.rounds.length, current: state.index),
              const SizedBox(height: AppSpacing.s8),
              PromptBar(
                text: l10n.findPrompt(name),
                trailing: RoundIconButton(
                  icon: Icons.volume_up_rounded,
                  label: l10n.listenAgain,
                  size: 48,
                  color: context.tokens.primary,
                  onTap: () {
                    _sayTarget(state);
                    _restartIdleTimer();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Expanded(
                child: Row(
                  // Keyed by round so the cards pop in again per question.
                  key: ValueKey(state.index),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, option) in round.options.indexed)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8,
                          ),
                          child: PopIn(
                            delay: Duration(milliseconds: 90 * i),
                            child: _OptionCard(
                              item: option,
                              eliminated: state.eliminated.contains(option.id),
                              celebrated:
                                  state.solved && option.id == round.target.id,
                              hinted: _hint && option.id == round.target.id,
                              onTap: () =>
                                  context.read<ChoiceCubit>().pick(option),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.item,
    required this.eliminated,
    required this.celebrated,
    required this.hinted,
    required this.onTap,
  });

  final LearningItem item;
  final bool eliminated;
  final bool celebrated;

  /// Pulses to point the child at the right answer.
  final bool hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // The trigger flips 0 -> 1 the moment this option is ruled out.
    return Shaker(
      trigger: eliminated ? 1 : 0,
      child: AnimatedScale(
        scale: celebrated ? 1.08 : 1,
        duration: tokens.motionMedium,
        curve: Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: eliminated ? 0.35 : 1,
          duration: tokens.motionMedium,
          child: Pulse(
            active: hinted,
            child: Pressable(
              onTap: eliminated ? null : onTap,
              semanticLabel: item.name.of(context.languageCode),
              child: AspectRatio(
                aspectRatio: 1,
                child: KidCard(
                  color: celebrated ? tokens.success : null,
                  child: ItemVisualView(visual: item.visual),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
