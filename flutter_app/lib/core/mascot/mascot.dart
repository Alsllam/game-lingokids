import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../painting/shape_paths.dart';

/// What the mascot is doing. [idle] loops forever; the others play once and
/// return to idle.
enum MascotMood { idle, wave, cheer, sad, talk }

/// Tells a [MascotView] what to play. Create one per screen and dispose it.
///
/// This is the only API the rest of the app uses. To replace the drawn
/// mascot with a Rive or Lottie file later, keep this class and swap the
/// inside of [MascotView] - no game code changes.
class MascotController extends ChangeNotifier {
  MascotMood _mood = MascotMood.idle;
  int _tick = 0;

  MascotMood get mood => _mood;

  /// Changes on every [play], even when the mood repeats.
  int get tick => _tick;

  void play(MascotMood mood) {
    _mood = mood;
    _tick++;
    notifyListeners();
  }
}

/// "Noor": an original character drawn with a [CustomPainter] and animated
/// from two controllers - a slow loop (breathing, blinking) and a one-shot
/// action (wave, cheer, sad, talk).
class MascotView extends StatefulWidget {
  const MascotView({super.key, required this.controller, this.size = 180});

  final MascotController controller;
  final double size;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  late final AnimationController _action = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  MascotMood _mood = MascotMood.idle;
  bool _loopStarted = false;

  static const _durations = {
    MascotMood.wave: Duration(milliseconds: 1400),
    MascotMood.cheer: Duration(milliseconds: 1100),
    MascotMood.sad: Duration(milliseconds: 1000),
    MascotMood.talk: Duration(milliseconds: 1300),
  };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCommand);
    _action.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _mood = MascotMood.idle);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = context.reduceMotion;
    if (!reduce && !_loopStarted) {
      _loop.repeat();
      _loopStarted = true;
    } else if (reduce && _loopStarted) {
      _loop.stop();
      _loopStarted = false;
    }
  }

  @override
  void didUpdateWidget(MascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCommand);
      widget.controller.addListener(_onCommand);
    }
  }

  void _onCommand() {
    final mood = widget.controller.mood;
    if (mood == MascotMood.idle) {
      _action.stop();
      setState(() => _mood = MascotMood.idle);
      return;
    }
    setState(() => _mood = mood);
    _action
      ..duration = _durations[mood]
      ..forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCommand);
    _loop.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _action]),
          builder: (context, _) {
            return CustomPaint(
              painter: MascotPainter(
                loop: _loop.value,
                action: _mood == MascotMood.idle ? 0 : _action.value,
                mood: _mood,
                body: tokens.mascotBody,
                belly: tokens.mascotBelly,
                accent: tokens.mascotAccent,
                ink: tokens.ink,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Draws one frame of the mascot.
///
/// [loop] and [action] both run from 0 to 1. All sizes are fractions of the
/// canvas, so the character scales to any size.
class MascotPainter extends CustomPainter {
  const MascotPainter({
    required this.loop,
    required this.action,
    required this.mood,
    required this.body,
    required this.belly,
    required this.accent,
    required this.ink,
  });

  final double loop;
  final double action;
  final MascotMood mood;
  final Color body;
  final Color belly;
  final Color accent;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ---- Pose values derived from the two timelines -----------------------
    final breathe = math.sin(loop * math.pi * 4) * 0.012;
    final blinkPhase = (loop * 2) % 1.0; // blink twice per loop
    final blink = blinkPhase > 0.94
        ? 1 - math.sin((blinkPhase - 0.94) / 0.06 * math.pi)
        : 1.0;

    var jump = 0.0; // upward lift, fraction of s
    var sway = 0.0; // sideways shift
    var squash = 0.0; // +wide/-tall
    var leftArm = 0.35; // radians below horizontal
    var rightArm = 0.35;
    var mouthOpen = 0.0; // 0 closed smile .. 1 wide open
    var smile = 1.0; // 1 smile .. -1 frown
    var eyeDrop = 0.0;
    var starSpin = math.sin(loop * math.pi * 2) * 0.15;

    switch (mood) {
      case MascotMood.idle:
        break;
      case MascotMood.wave:
        final lift = Curves.easeOut.transform((action * 4).clamp(0.0, 1.0));
        final lower = Curves.easeIn.transform(
          ((action - 0.8) * 5).clamp(0.0, 1.0),
        );
        final raised = lift * (1 - lower);
        rightArm = 0.35 - raised * (1.25 + math.sin(action * math.pi * 8) * 0.35);
        mouthOpen = 0.35 * raised;
      case MascotMood.cheer:
        final hop = (math.sin(action * math.pi * 2)).abs();
        jump = hop * 0.15 * (1 - action * 0.35);
        squash = -hop * 0.04 + (1 - hop) * 0.03 * (1 - action);
        final up = math.sin(action * math.pi).clamp(0.0, 1.0);
        leftArm = 0.35 - up * 1.5;
        rightArm = 0.35 - up * 1.5;
        mouthOpen = up;
        starSpin = action * math.pi * 2;
      case MascotMood.sad:
        final fade = 1 - action;
        sway = math.sin(action * math.pi * 5) * 0.03 * fade;
        final down = math.sin(action * math.pi).clamp(0.0, 1.0);
        smile = 1 - down * 1.8;
        eyeDrop = down * 0.012;
        leftArm = 0.35 + down * 0.5;
        rightArm = 0.35 + down * 0.5;
        squash = down * 0.02;
      case MascotMood.talk:
        final envelope = math.sin(action * math.pi).clamp(0.0, 1.0);
        mouthOpen = (math.sin(action * math.pi * 9)).abs() * 0.8 * envelope;
        leftArm = 0.35 - envelope * 0.25;
    }

    // ---- Ground shadow ------------------------------------------------------
    fill.color = ink.withValues(alpha: 0.12);
    final shadowScale = 1 - jump * 2.2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.94),
        width: s * 0.5 * shadowScale,
        height: s * 0.07 * shadowScale,
      ),
      fill,
    );

    canvas
      ..save()
      ..translate(s * sway, -s * jump);

    final cx = s * 0.5;
    final cy = s * 0.6;
    final rx = s * (0.29 + squash);
    final ry = s * (0.30 - squash + breathe);

    // ---- Feet -----------------------------------------------------------------
    fill.color = Color.lerp(body, ink, 0.25)!;
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * s * 0.13, s * 0.905),
          width: s * 0.17,
          height: s * 0.075,
        ),
        fill,
      );
    }

    // ---- Arms (behind the body) -------------------------------------------------
    stroke
      ..color = Color.lerp(body, ink, 0.12)!
      ..strokeWidth = s * 0.075;
    void arm(double side, double angle) {
      final shoulder = Offset(cx + side * rx * 0.88, cy - ry * 0.05);
      final hand =
          shoulder +
          Offset(side * math.cos(angle) * s * 0.17, math.sin(angle) * s * 0.17);
      canvas.drawLine(shoulder, hand, stroke);
    }

    arm(-1, leftArm);
    arm(1, rightArm);

    // ---- Antenna with a star -----------------------------------------------------
    final antennaBase = Offset(cx, cy - ry * 0.95);
    final antennaTip = Offset(cx + s * 0.02, cy - ry - s * 0.13);
    stroke
      ..color = Color.lerp(body, ink, 0.25)!
      ..strokeWidth = s * 0.022;
    canvas.drawLine(antennaBase, antennaTip, stroke);
    canvas
      ..save()
      ..translate(antennaTip.dx, antennaTip.dy)
      ..rotate(starSpin);
    fill.color = accent;
    canvas.drawPath(ShapePaths.star(Offset.zero, s * 0.075), fill);
    canvas.restore();

    // ---- Body and belly -------------------------------------------------------------
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rx * 2,
      height: ry * 2,
    );
    fill.shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      radius: 1.0,
      colors: [Color.lerp(body, Colors.white, 0.28)!, body],
    ).createShader(bodyRect);
    canvas.drawOval(bodyRect, fill);
    fill.shader = null;

    fill.color = belly;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + ry * 0.38),
        width: rx * 1.15,
        height: ry * 0.95,
      ),
      fill,
    );

    // ---- Face ------------------------------------------------------------------------
    final eyeY = cy - ry * 0.22 + s * eyeDrop;
    final eyeDx = rx * 0.42;
    final eyeR = s * 0.062;
    for (final side in const [-1.0, 1.0]) {
      final center = Offset(cx + side * eyeDx, eyeY);
      fill.color = Colors.white;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: eyeR * 2,
          height: eyeR * 2 * blink.clamp(0.08, 1.0),
        ),
        fill,
      );
      if (blink > 0.4) {
        fill.color = ink;
        canvas.drawCircle(
          center + Offset(0, s * (0.006 + eyeDrop)),
          eyeR * 0.52,
          fill,
        );
        fill.color = Colors.white;
        canvas.drawCircle(
          center + Offset(-eyeR * 0.18, -eyeR * 0.2),
          eyeR * 0.17,
          fill,
        );
      }
    }

    // Cheeks
    fill.color = const Color(0xFFFF8FB1).withValues(alpha: 0.55);
    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * rx * 0.68, cy + ry * 0.02),
          width: s * 0.075,
          height: s * 0.05,
        ),
        fill,
      );
    }

    // Mouth
    final mouthCenter = Offset(cx, cy + ry * 0.06);
    final mouthW = s * 0.085;
    if (mouthOpen > 0.12) {
      fill.color = ink;
      final mouthRect = Rect.fromCenter(
        center: mouthCenter + Offset(0, s * 0.012),
        width: mouthW * 1.5,
        height: s * 0.035 + s * 0.075 * mouthOpen,
      );
      canvas.drawOval(mouthRect, fill);
      fill.color = const Color(0xFFFF6B8B);
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthRect.center + Offset(0, mouthRect.height * 0.22),
          width: mouthRect.width * 0.6,
          height: mouthRect.height * 0.45,
        ),
        fill,
      );
    } else {
      stroke
        ..color = ink
        ..strokeWidth = s * 0.02;
      final curve = s * 0.045 * smile;
      final path = Path()
        ..moveTo(mouthCenter.dx - mouthW, mouthCenter.dy)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + curve * 2,
          mouthCenter.dx + mouthW,
          mouthCenter.dy,
        );
      canvas.drawPath(path, stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) {
    return oldDelegate.loop != loop ||
        oldDelegate.action != action ||
        oldDelegate.mood != mood ||
        oldDelegate.body != body;
  }
}
