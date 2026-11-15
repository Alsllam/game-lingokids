import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../motion/motion.dart';
import '../painting/shape_paths.dart';

/// The sky-and-grass backdrop shared by every screen.
class SceneBackground extends StatelessWidget {
  const SceneBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.skyTop, tokens.skyBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.14,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.ground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.elliptical(900, 60),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// A raised white card with a coloured "3D" bottom edge.
class KidCard extends StatelessWidget {
  const KidCard({
    super.key,
    required this.child,
    this.color,
    this.edgeColor,
    this.padding = const EdgeInsets.all(AppSpacing.s12),
  });

  final Widget child;
  final Color? color;
  final Color? edgeColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final face = color ?? tokens.card;
    final edge = edgeColor ?? Color.lerp(face, tokens.ink, 0.18)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        boxShadow: [
          BoxShadow(color: edge, offset: const Offset(0, 6)),
          BoxShadow(
            color: tokens.ink.withValues(alpha: 0.12),
            offset: const Offset(0, 12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// A large, friendly button with an optional icon.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final face = color ?? tokens.primary;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face,
          borderRadius: BorderRadius.circular(tokens.radiusButton),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(face, tokens.ink, 0.3)!,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s24,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.s8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round icon-only button (back, close, parents).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.size = 56,
  });

  final IconData icon;

  /// Read by screen readers and shown as a tooltip.
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final face = color ?? tokens.card;
    final onFace = color == null ? tokens.ink : Colors.white;
    return Tooltip(
      message: label,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: face,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.lerp(face, tokens.ink, 0.22)!,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: onFace, size: size * 0.52),
        ),
      ),
    );
  }
}

/// Draws one star, filled or empty.
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, required this.filled, this.size = 28});

  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(filled ? tokens.star : tokens.starEmpty),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero) + Offset(0, size.height * 0.04);
    canvas.drawPath(
      ShapePaths.star(center, size.shortestSide * 0.5),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}

/// Three stars showing how many were earned.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 24});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars / 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: StarIcon(filled: i < stars, size: size),
            ),
        ],
      ),
    );
  }
}
