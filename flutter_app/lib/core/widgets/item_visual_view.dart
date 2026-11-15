import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../domain/item_visual.dart';
import '../painting/shape_paths.dart';

/// Draws any [ItemVisual] inside a square, scaling to the space it is given.
/// This is the single place that knows how content is turned into pictures.
class ItemVisualView extends StatelessWidget {
  const ItemVisualView({super.key, required this.visual});

  final ItemVisual visual;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final value = visual.value.of(context.languageCode);
    final tint = visual.color == null ? null : Color(visual.color!);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          switch (visual.kind) {
            case VisualKind.emoji:
              return Center(
                child: Text(
                  value,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: side * 0.62, height: 1.1),
                ),
              );
            case VisualKind.glyph:
              return Center(
                child: Text(
                  value,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: side * 0.66,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: tint ?? tokens.primary,
                  ),
                ),
              );
            case VisualKind.label:
              return Padding(
                padding: EdgeInsets.all(side * 0.08),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: side * 0.3,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                ),
              );
            case VisualKind.color:
              return CustomPaint(
                painter: _BlobPainter(_parseHex(value) ?? tokens.primary),
              );
            case VisualKind.shape:
              return CustomPaint(
                painter: _ShapePainter(value, tint ?? tokens.primary),
              );
            case VisualKind.sprite:
              return Padding(
                padding: EdgeInsets.all(side * 0.04),
                child: Image.asset(
                  'assets/art/$value.png',
                  fit: BoxFit.contain,
                  // A missing file shows a placeholder instead of crashing.
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported_outlined,
                    size: side * 0.5,
                    color: tokens.inkSoft,
                  ),
                ),
              );
            case VisualKind.dots:
              return CustomPaint(
                painter: _DotsPainter(
                  (int.tryParse(value) ?? 1).clamp(1, 9),
                  tint ?? tokens.primary,
                ),
              );
          }
        },
      ),
    );
  }

  static Color? _parseHex(String hex) {
    final digits = hex.replaceFirst('#', '');
    final value = int.tryParse(digits, radix: 16);
    if (value == null) return null;
    return Color(digits.length == 6 ? 0xFF000000 | value : value);
  }
}

/// A soft paint blob with a highlight, for the colours topic.
class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.36;
    final path = Path();
    const lobes = 7;
    for (var i = 0; i <= 72; i++) {
      final angle = i / 72 * math.pi * 2;
      final r = radius * (1 + 0.07 * math.sin(angle * lobes));
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawCircle(
        center + Offset(-radius * 0.35, -radius * 0.38),
        radius * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) => oldDelegate.color != color;
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.shape, this.color);

  final String shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.34;
    final paint = Paint()..color = color;
    switch (shape) {
      case 'square':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: center, radius: radius * 0.9),
            Radius.circular(radius * 0.16),
          ),
          paint,
        );
      case 'triangle':
        canvas.drawPath(ShapePaths.triangle(center, radius), paint);
      case 'star':
        canvas.drawPath(ShapePaths.star(center, radius * 1.1), paint);
      case 'heart':
        canvas.drawPath(ShapePaths.heart(center, radius), paint);
      default:
        canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

/// Counting dots laid out like the faces of a die.
class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.count, this.color);

  final int count;
  final Color color;

  static const _layouts = <int, List<Offset>>{
    1: [Offset(0, 0)],
    2: [Offset(-1, -1), Offset(1, 1)],
    3: [Offset(-1, -1), Offset(0, 0), Offset(1, 1)],
    4: [Offset(-1, -1), Offset(1, -1), Offset(-1, 1), Offset(1, 1)],
    5: [Offset(-1, -1), Offset(1, -1), Offset(0, 0), Offset(-1, 1), Offset(1, 1)],
    6: [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(1, 1),
    ],
    7: [
      Offset(-1, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(0, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(1, 1),
    ],
    8: [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(0, 1),
      Offset(1, 1),
    ],
    9: [
      Offset(-1, -1),
      Offset(0, -1),
      Offset(1, -1),
      Offset(-1, 0),
      Offset(0, 0),
      Offset(1, 0),
      Offset(-1, 1),
      Offset(0, 1),
      Offset(1, 1),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final step = size.shortestSide * 0.24;
    final radius = size.shortestSide * 0.085;
    final paint = Paint()..color = color;
    for (final cell in _layouts[count] ?? _layouts[1]!) {
      canvas.drawCircle(center + cell * step, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.color != color;
}
