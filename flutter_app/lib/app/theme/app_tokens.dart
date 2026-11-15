import 'package:flutter/material.dart';

/// Design tokens of the app. Widgets read `context.tokens.x` and never use
/// raw colour values, so the whole look can be changed in this one file.
@immutable
final class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.primary,
    required this.success,
    required this.danger,
    required this.star,
    required this.starEmpty,
    required this.mascotBody,
    required this.mascotBelly,
    required this.mascotAccent,
    required this.radiusCard,
    required this.radiusButton,
    required this.motionFast,
    required this.motionMedium,
    required this.motionSlow,
  });

  static const AppTokens light = AppTokens(
    skyTop: Color(0xFF8FD8FF),
    skyBottom: Color(0xFFE6F8FF),
    ground: Color(0xFF8BD67A),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1F2A44),
    inkSoft: Color(0xFF5B6785),
    primary: Color(0xFF3D8BFF),
    success: Color(0xFF2EC27E),
    danger: Color(0xFFFF5A5F),
    star: Color(0xFFFFC533),
    starEmpty: Color(0xFFD9DFEC),
    mascotBody: Color(0xFF7C5CFF),
    mascotBelly: Color(0xFFEDE7FF),
    mascotAccent: Color(0xFFFFC533),
    radiusCard: 28,
    radiusButton: 24,
    motionFast: Duration(milliseconds: 150),
    motionMedium: Duration(milliseconds: 350),
    motionSlow: Duration(milliseconds: 700),
  );

  final Color skyTop;
  final Color skyBottom;
  final Color ground;
  final Color card;
  final Color ink;
  final Color inkSoft;
  final Color primary;
  final Color success;
  final Color danger;
  final Color star;
  final Color starEmpty;
  final Color mascotBody;
  final Color mascotBelly;
  final Color mascotAccent;
  final double radiusCard;
  final double radiusButton;
  final Duration motionFast;
  final Duration motionMedium;
  final Duration motionSlow;

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    return other is AppTokens && t >= 0.5 ? other : this;
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;

  /// True when the system asks apps to reduce motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// 'ar' or 'en' - the language of both interface and spoken content.
  String get languageCode => Localizations.localeOf(this).languageCode;
}

/// 8-pt spacing scale.
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
}
