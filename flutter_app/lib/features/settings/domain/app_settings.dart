import 'package:equatable/equatable.dart';

final class AppSettings extends Equatable {
  const AppSettings({
    this.languageCode = 'ar',
    this.sfxOn = true,
    this.voiceOn = true,
  });

  /// 'ar' or 'en'. Drives both the interface and the spoken content.
  final String languageCode;
  final bool sfxOn;
  final bool voiceOn;

  AppSettings copyWith({String? languageCode, bool? sfxOn, bool? voiceOn}) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      sfxOn: sfxOn ?? this.sfxOn,
      voiceOn: voiceOn ?? this.voiceOn,
    );
  }

  @override
  List<Object?> get props => [languageCode, sfxOn, voiceOn];
}

abstract interface class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings settings);
}
