import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../domain/app_settings.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._store);

  static const storageKey = 'settings.v1';

  final KeyValueStore _store;

  @override
  AppSettings load() {
    final raw = _store.getString(storageKey);
    if (raw == null) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return const AppSettings();
      final language = decoded['languageCode'];
      final sfx = decoded['sfxOn'];
      final voice = decoded['voiceOn'];
      return AppSettings(
        languageCode: language == 'en' ? 'en' : 'ar',
        sfxOn: sfx is bool ? sfx : true,
        voiceOn: voice is bool ? voice : true,
      );
    } on FormatException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) {
    return _store.setString(
      storageKey,
      jsonEncode({
        'languageCode': settings.languageCode,
        'sfxOn': settings.sfxOn,
        'voiceOn': settings.voiceOn,
      }),
    );
  }
}
