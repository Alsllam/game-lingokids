import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

final class SharedPrefsKeyValueStore implements KeyValueStore {
  const SharedPrefsKeyValueStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}
