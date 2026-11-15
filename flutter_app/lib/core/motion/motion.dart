import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Reusable code-driven animations (the role DOTween plays in Unity).
///
/// Every widget here owns its own controller and cleans it up, and every one
/// falls back to no movement when the system asks for reduced motion. Because
/// the animation is plain code, it cannot "go missing" at runtime the way an
/// unlinked animation asset can.

/// Scales its child in with a bouncy overshoot, optionally after a [delay].
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.3),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Shakes its child sideways every time [trigger] changes to a new value.
/// Used for "that was not the right one".
class Shaker extends StatefulWidget {
  const Shaker({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shaker> createState() => _ShakerState();
}

class _ShakerState extends State<Shaker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shaker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
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
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Gently grows and shrinks forever to say "tap me".
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.active = true});

  final Widget child;
  final bool active;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.07).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Wraps anything tappable: squashes slightly while pressed and reports taps.
/// Guarantees a touch target of at least 48x48.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: context.tokens.motionFast,
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A card that flips around its vertical axis between [back] and [front].
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.showFront,
    required this.front,
    required this.back,
  });

  final bool showFront;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    final duration = context.reduceMotion
        ? Duration.zero
        : context.tokens.motionMedium;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: showFront ? 1 : 0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final frontVisible = value >= 0.5;
        final angle = (frontVisible ? value - 1 : value) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(angle),
          child: frontVisible ? front : back,
        );
      },
    );
  }
}
