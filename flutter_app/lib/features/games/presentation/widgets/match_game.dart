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
import '../cubit/match_cubit.dart';
import 'game_template.dart';

/// Template 3: drag each picture onto the thing it belongs with.
class MatchGame extends StatelessWidget {
  const MatchGame({
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
      create: (_) => MatchCubit(bundle: bundle, random: Random()),
      child: BlocConsumer<MatchCubit, MatchState>(
        listenWhen: (previous, current) =>
            previous.feedbackTick != current.feedbackTick,
        listener: (context, state) {
          onFeedback(state.feedback);
          if (state.finished) onFinished(state.stars);
        },
        builder: (context, state) {
          final round = state.round;
          return Column(
            children: [
              RoundDots(total: state.rounds.length, current: state.index),
              const SizedBox(height: AppSpacing.s8),
              PromptBar(text: context.l10n.matchPrompt),
              const SizedBox(height: AppSpacing.s8),
              Expanded(
                child: KeyedSubtree(
                  key: ValueKey(state.index),
                  child: Column(
                    children: [
                      Expanded(
                        child: _PieceRow(
                          children: [
                            for (final (i, item) in round.sources.indexed)
                              PopIn(
                                delay: Duration(milliseconds: 80 * i),
                                child: _SourcePiece(
                                  item: item,
                                  placed: state.matched.contains(item.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Expanded(
                        child: _PieceRow(
                          children: [
                            for (final item in round.targets)
                              _TargetSlot(
                                item: item,
                                filled: state.matched.contains(item.id),
                                shakeTick: state.wrongTargetId == item.id
                                    ? state.wrongTick
                                    : 0,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lays pieces out in one centred row of equal squares.
class _PieceRow extends StatelessWidget {
  const _PieceRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = min(
          constraints.maxHeight,
          constraints.maxWidth / children.length,
        );
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final child in children)
              SizedBox.square(
                dimension: cell,
                child: Padding(
                  padding: EdgeInsets.all(cell * 0.07),
                  child: child,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SourcePiece extends StatelessWidget {
  const _SourcePiece({required this.item, required this.placed});

  final LearningItem item;
  final bool placed;

  @override
  Widget build(BuildContext context) {
    final card = KidCard(child: ItemVisualView(visual: item.visual));
    if (placed) {
      // Keep the space so the remaining pieces do not jump around.
      return const SizedBox.expand();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        return Draggable<String>(
          data: item.id,
          onDragStarted: () {
            final language = context.languageCode;
            context.read<Speaker>().speak(
              item.name.of(language),
              languageCode: language,
            );
          },
          feedback: SizedBox.square(
            dimension: side * 1.08,
            child: Material(type: MaterialType.transparency, child: card),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: card),
          child: Semantics(
            label: item.name.of(context.languageCode),
            child: card,
          ),
        );
      },
    );
  }
}

class _TargetSlot extends StatelessWidget {
  const _TargetSlot({
    required this.item,
    required this.filled,
    required this.shakeTick,
  });

  final LearningItem item;
  final bool filled;
  final int shakeTick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Shaker(
      trigger: shakeTick,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => !filled,
        onAcceptWithDetails: (details) {
          context.read<MatchCubit>().drop(
            sourceId: details.data,
            targetId: item.id,
          );
        },
        builder: (context, candidates, _) {
          final hovering = candidates.isNotEmpty;
          return AnimatedScale(
            scale: hovering ? 1.07 : 1,
            duration: tokens.motionFast,
            child: KidCard(
              color: filled
                  ? Color.lerp(tokens.success, Colors.white, 0.7)
                  : hovering
                  ? Color.lerp(tokens.primary, Colors.white, 0.75)
                  : Color.lerp(tokens.card, tokens.skyTop, 0.25),
              edgeColor: filled ? tokens.success : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemVisualView(visual: item.pairOrLabel),
                  if (filled)
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: PopIn(
                        child: FractionallySizedBox(
                          widthFactor: 0.42,
                          heightFactor: 0.42,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: tokens.success,
                                width: 3,
                              ),
                            ),
                            child: ItemVisualView(visual: item.visual),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
