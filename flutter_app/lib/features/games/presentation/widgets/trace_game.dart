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
import '../cubit/game_feedback.dart';
import '../cubit/trace_cubit.dart';
import 'game_template.dart';

/// Template 4: write a letter by following its strokes with a finger.
class TraceGame extends StatelessWidget {
  const TraceGame({
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
      create: (context) => TraceCubit(
        bundle: bundle,
        languageCode: context.languageCode,
        random: Random(),
      ),
      child: _TraceView(
        accent: Color(bundle.topic.color),
        onFeedback: onFeedback,
        onFinished: onFinished,
      ),
    );
  }
}

class _TraceView extends StatefulWidget {
  const _TraceView({
    required this.accent,
    required this.onFeedback,
    required this.onFinished,
  });

  final Color accent;
  final GameFeedbackCallback onFeedback;
  final GameFinishedCallback onFinished;

  @override
  State<_TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<_TraceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sayLetter(context.read<TraceCubit>().state);
    });
  }

  void _sayLetter(TraceState state) {
    final language = context.languageCode;
    context.read<Speaker>().speak(
      state.item.name.of(language),
      languageCode: language,
    );
    widget.onFeedback(GameFeedback.prompt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        // A new letter: say its name.
        BlocListener<TraceCubit, TraceState>(
          listenWhen: (previous, current) => previous.index != current.index,
          listener: (context, state) => _sayLetter(state),
        ),
        // A stroke was completed: a small chime.
        BlocListener<TraceCubit, TraceState>(
          listenWhen: (previous, current) =>
              previous.index == current.index &&
              current.stroke > previous.stroke,
          listener: (context, state) =>
              context.read<SoundPlayer>().play(Sfx.star),
        ),
        BlocListener<TraceCubit, TraceState>(
          listenWhen: (previous, current) =>
              previous.feedbackTick != current.feedbackTick,
          listener: (context, state) {
            widget.onFeedback(state.feedback);
            if (state.finished) widget.onFinished(state.stars);
          },
        ),
      ],
      child: BlocBuilder<TraceCubit, TraceState>(
        builder: (context, state) {
          final name = state.item.name.of(context.languageCode);
          return Column(
            children: [
              RoundDots(total: state.items.length, current: state.index),
              const SizedBox(height: AppSpacing.s8),
              PromptBar(text: l10n.tracePrompt(name)),
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The picture that goes with the letter, when it has one.
                    if (state.item.pair != null)
                      Flexible(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: PopIn(
                            key: ValueKey('picture ${state.index}'),
                            child: ItemVisualView(visual: state.item.pair!),
                          ),
                        ),
                      ),
                    Flexible(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: PopIn(
                          key: ValueKey('board ${state.index}'),
                          child: _TraceBoard(state: state, accent: widget.accent),
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

/// The square writing surface. Finger positions are converted to box
/// coordinates (0..1) so the rules never see pixels.
class _TraceBoard extends StatelessWidget {
  const _TraceBoard({required this.state, required this.accent});

  final TraceState state;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cubit = context.read<TraceCubit>();
    return KidCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          void report(Offset local) {
            if (side <= 0) return;
            cubit.touch(
              (local.dx / side).clamp(0.0, 1.0),
              (local.dy / side).clamp(0.0, 1.0),
            );
          }

          // A Listener reports every pointer move at once. A GestureDetector
          // would wait until the finger has travelled a little, which feels
          // laggy when drawing.
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => report(event.localPosition),
            onPointerMove: (event) => report(event.localPosition),
            onPointerUp: (_) => cubit.lift(),
            onPointerCancel: (_) => cubit.lift(),
            child: Semantics(
              label: state.item.name.of(context.languageCode),
              child: CustomPaint(
                size: Size.square(side),
                painter: _TracePainter(
                  paths: state.paths,
                  stroke: state.solved ? state.paths.length : state.stroke,
                  reached: state.reached,
                  guide: tokens.starEmpty,
                  ink: state.solved ? tokens.success : accent,
                  marker: tokens.success,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.paths,
    required this.stroke,
    required this.reached,
    required this.guide,
    required this.ink,
    required this.marker,
  });

  final List<List<TracePoint>> paths;

  /// Strokes before this index are complete.
  final int stroke;

  /// Checkpoints done in the current stroke.
  final int reached;
  final Color guide;
  final Color ink;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final width = side * 0.1;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint();

    Offset at(TracePoint point) => Offset(point.x * side, point.y * side);

    void drawPart(List<TracePoint> points, int count, Color color) {
      if (count <= 0) return;
      if (points.length == 1) {
        // A dot to tap.
        canvas.drawCircle(at(points.first), width * 0.62, fill..color = color);
        return;
      }
      final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
      for (var i = 1; i < count; i++) {
        path.lineTo(at(points[i]).dx, at(points[i]).dy);
      }
      if (count == 1) {
        canvas.drawCircle(at(points.first), width / 2, fill..color = color);
      } else {
        canvas.drawPath(path, line..color = color);
      }
    }

    // 1. The whole letter as a pale guide.
    for (final points in paths) {
      drawPart(points, points.length, guide);
    }
    // 2. What has been written so far.
    for (var i = 0; i < paths.length; i++) {
      if (i < stroke) {
        drawPart(paths[i], paths[i].length, ink);
      } else if (i == stroke) {
        drawPart(paths[i], reached, ink);
      }
    }
    // 3. A marker on the spot to touch next.
    if (stroke < paths.length) {
      final next = at(paths[stroke][reached.clamp(0, paths[stroke].length - 1)]);
      canvas
        ..drawCircle(next, width * 0.72, fill..color = Colors.white)
        ..drawCircle(next, width * 0.5, fill..color = marker);
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) {
    return oldDelegate.paths != paths ||
        oldDelegate.stroke != stroke ||
        oldDelegate.reached != reached ||
        oldDelegate.ink != ink;
  }
}
