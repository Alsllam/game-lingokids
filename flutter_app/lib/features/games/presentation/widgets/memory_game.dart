import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/audio/sound_player.dart';
import '../../../../core/audio/speaker.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/item_visual_view.dart';
import '../../../../core/widgets/kid_widgets.dart';
import '../../../catalog/domain/entities/catalog.dart';
import '../../domain/game_engines.dart';
import '../cubit/memory_cubit.dart';
import 'game_template.dart';

/// Template 2: turn over cards two at a time and find the pairs.
class MemoryGame extends StatelessWidget {
  const MemoryGame({
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
      create: (_) => MemoryCubit(bundle: bundle, random: Random()),
      child: BlocConsumer<MemoryCubit, MemoryState>(
        listenWhen: (previous, current) =>
            previous.feedbackTick != current.feedbackTick,
        listener: (context, state) {
          onFeedback(state.feedback);
          if (state.finished) onFinished(state.stars);
        },
        builder: (context, state) {
          return Column(
            children: [
              PromptBar(text: context.l10n.memoryPrompt),
              const SizedBox(height: AppSpacing.s12),
              Expanded(child: _MemoryGrid(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _MemoryGrid extends StatelessWidget {
  const _MemoryGrid({required this.state});

  final MemoryState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = state.cards.length;
        // Pick the column count that gives the largest square cells.
        var bestColumns = count;
        var bestCell = 0.0;
        for (var columns = 2; columns <= count; columns++) {
          final rows = (count / columns).ceil();
          final cell = min(
            constraints.maxWidth / columns,
            constraints.maxHeight / rows,
          );
          if (cell > bestCell) {
            bestCell = cell;
            bestColumns = columns;
          }
        }
        final rows = (count / bestColumns).ceil();
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < rows; row++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  // Card order must not mirror in RTL: positions are the
                  // thing being memorised.
                  textDirection: TextDirection.ltr,
                  children: [
                    for (
                      var index = row * bestColumns;
                      index < min((row + 1) * bestColumns, count);
                      index++
                    )
                      SizedBox.square(
                        dimension: bestCell,
                        child: Padding(
                          padding: EdgeInsets.all(bestCell * 0.06),
                          child: PopIn(
                            delay: Duration(milliseconds: 35 * index),
                            child: _MemoryCardView(
                              card: state.cards[index],
                              faceUp: state.isFaceUp(index),
                              matched: state.matched.contains(index),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryCardView extends StatelessWidget {
  const _MemoryCardView({
    required this.card,
    required this.faceUp,
    required this.matched,
  });

  final MemoryCard card;
  final bool faceUp;
  final bool matched;

  void _flip(BuildContext context) {
    final cubit = context.read<MemoryCubit>();
    if (cubit.state.busy || cubit.state.finished) return;
    final language = context.languageCode;
    context.read<SoundPlayer>().play(Sfx.flip);
    context.read<Speaker>().speak(
      card.item.name.of(language),
      languageCode: language,
    );
    cubit.flip(card.index);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Pressable(
      onTap: faceUp ? null : () => _flip(context),
      semanticLabel: faceUp ? card.item.name.of(context.languageCode) : '?',
      child: FlipCard(
        showFront: faceUp,
        front: KidCard(
          color: matched ? Color.lerp(tokens.success, Colors.white, 0.75) : null,
          edgeColor: matched ? tokens.success : null,
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: ItemVisualView(visual: card.visual),
        ),
        back: KidCard(
          color: tokens.primary,
          padding: EdgeInsets.zero,
          child: const Center(child: StarIcon(filled: true, size: 36)),
        ),
      ),
    );
  }
}
