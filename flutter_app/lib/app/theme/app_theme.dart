import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  /// The app uses one bright theme on purpose: a playful daytime world reads
  /// better for young children than a dark interface.
  static ThemeData build() {
    const tokens = AppTokens.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: Brightness.light,
    ).copyWith(primary: tokens.primary, error: tokens.danger);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Baloo',
      scaffoldBackgroundColor: tokens.skyBottom,
      extensions: const [tokens],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: tokens.ink,
        displayColor: tokens.ink,
      ),
    );
  }
}
