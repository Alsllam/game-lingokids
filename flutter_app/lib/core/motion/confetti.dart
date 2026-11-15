import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// A one-shot burst of confetti drawn entirely with a [CustomPainter]
/// (the role a ParticleSystem plays in Unity).
///
/// Place it in a [Stack] above the content; it ignores touches. It plays once
/// when first built and again every time [trigger] changes.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.trigger = 0, this.pieces = 90});

  final int trigger;
  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late List<_Piece> _pieces = _generate();

  static const _palette = [
    Color(0xFFFF5A5F),
    Color(0xFF3D8BFF),
    Color(0xFF2EC27E),
    Color(0xFFFFC533),
    Color(0xFF9B5DE5),
    Color(0xFFFF7AB6),
  ];

  List<_Piece> _generate() {
    final random = math.Random();
    return List.generate(widget.pieces, (_) {
      return _Piece(
        startX: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.5,
        speed: 0.7 + random.nextDouble() * 0.7,
        delay: random.nextDouble() * 0.25,
        size: 7 + random.nextDouble() * 9,
        spin: (random.nextDouble() - 0.5) * 14,
        wobble: random.nextDouble() * math.pi * 2,
        color: _palette[random.nextInt(_palette.length)],
        round: random.nextBool(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _pieces = _generate();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.startX,
    required this.drift,
    required this.speed,
    required this.delay,
    required this.size,
    required this.spin,
    required this.wobble,
    required this.color,
    required this.round,
  });

  final double startX;
  final double drift;
  final double speed;
  final double delay;
  final double size;
  final double spin;
  final double wobble;
  final Color color;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final time = progress.value;
    if (time <= 0 || time >= 1) return;
    final paint = Paint();
    for (final piece in pieces) {
      final t = ((time - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final fall = t * piece.speed;
      final x =
          (piece.startX +
              piece.drift * t +
              math.sin(piece.wobble + t * 9) * 0.02) *
          size.width;
      final y = -20 + fall * (size.height + 40);
      if (y > size.height + 20) continue;
      final fade = t > 0.8 ? (1 - t) / 0.2 : 1.0;
      paint.color = piece.color.withValues(alpha: fade);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * t);
      if (piece.round) {
        canvas.drawCircle(Offset.zero, piece.size / 2, paint);
      } else {
        // Squashing the height imitates a paper strip tumbling in the air.
        final flip = math.cos(piece.wobble + t * 12).abs().clamp(0.25, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size,
              height: piece.size * 0.6 * flip,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces;
}
