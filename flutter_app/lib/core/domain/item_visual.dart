import 'package:equatable/equatable.dart';

import 'localized_text.dart';

/// How a learning item is drawn. Everything is rendered by code at runtime,
/// so content authors only describe *what* to draw.
enum VisualKind {
  /// A single emoji, e.g. an animal.
  emoji,

  /// A large letter or digit.
  glyph,

  /// A blob filled with a colour. `value` is the hex colour.
  color,

  /// A geometric shape: circle, square, triangle, star or heart.
  shape,

  /// N counting dots. `value` is the count.
  dots,

  /// A written word (used as a matching target).
  label,
}

final class ItemVisual extends Equatable {
  const ItemVisual({required this.kind, required this.value, this.color});

  final VisualKind kind;

  /// Meaning depends on [kind]; may differ per language (letters, digits).
  final LocalizedText value;

  /// Optional ARGB tint, e.g. 0xFF3D8BFF.
  final int? color;

  @override
  List<Object?> get props => [kind, value, color];
}
