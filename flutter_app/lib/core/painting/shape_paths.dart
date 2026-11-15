import 'dart:math' as math;
import 'dart:ui';

/// Vector shapes shared by the mascot, the star rating and the "shapes"
/// learning topic. Everything is built from paths, so it stays sharp at any
/// size and needs no image files.
abstract final class ShapePaths {
  /// A star with rounded-looking proportions, pointing up.
  static Path star(Offset center, double radius, {int points = 5}) {
    final inner = radius * 0.5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static Path heart(Offset center, double radius) {
    final w = radius * 2;
    final left = center.dx - radius;
    final top = center.dy - radius * 0.9;
    return Path()
      ..moveTo(center.dx, top + w * 0.3)
      ..cubicTo(
        center.dx - w * 0.1,
        top - w * 0.02,
        left - w * 0.05,
        top + w * 0.1,
        left + w * 0.02,
        top + w * 0.42,
      )
      ..cubicTo(
        left + w * 0.08,
        top + w * 0.65,
        center.dx - w * 0.15,
        top + w * 0.78,
        center.dx,
        top + w * 0.95,
      )
      ..cubicTo(
        center.dx + w * 0.15,
        top + w * 0.78,
        left + w * 0.92,
        top + w * 0.65,
        left + w * 0.98,
        top + w * 0.42,
      )
      ..cubicTo(
        left + w * 1.05,
        top + w * 0.1,
        center.dx + w * 0.1,
        top - w * 0.02,
        center.dx,
        top + w * 0.3,
      )
      ..close();
  }

  static Path triangle(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy + radius * 0.85)
      ..lineTo(center.dx - radius, center.dy + radius * 0.85)
      ..close();
  }
}
