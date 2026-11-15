/// Small, non-sensitive local storage (settings and stars).
///
/// Features depend on this interface, never on `shared_preferences`
/// directly, so tests can use [InMemoryKeyValueStore]. This file is pure
/// Dart on purpose; the real implementation lives next to it.
abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

final class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}
