import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/core/storage/key_value_store.dart';
import 'package:nujoom/features/progress/data/progress_repository_impl.dart';
import 'package:nujoom/features/progress/domain/progress_usecases.dart';
import 'package:nujoom/features/settings/data/settings_repository_impl.dart';
import 'package:nujoom/features/settings/domain/app_settings.dart';

void main() {
  group('ProgressRepositoryImpl', () {
    late InMemoryKeyValueStore store;
    late ProgressRepositoryImpl repository;

    setUp(() {
      store = InMemoryKeyValueStore();
      repository = ProgressRepositoryImpl(store);
    });

    Future<Map<String, int>> stars() async =>
        (await repository.getStars()).getOrElse(() => {'error': -1});

    test('starts empty', () async {
      expect(await stars(), isEmpty);
    });

    test('keeps the best result per activity', () async {
      await repository.saveBest(activityId: 'a', stars: 2);
      await repository.saveBest(activityId: 'a', stars: 1);
      expect(await stars(), {'a': 2});
      await repository.saveBest(activityId: 'a', stars: 3);
      expect(await stars(), {'a': 3});
    });

    test('survives a new repository instance (data is persisted)', () async {
      await repository.saveBest(activityId: 'a', stars: 3);
      final reopened = ProgressRepositoryImpl(store);
      expect((await reopened.getStars()).getOrElse(() => {}), {'a': 3});
    });

    test('reset removes everything', () async {
      await repository.saveBest(activityId: 'a', stars: 3);
      await repository.reset();
      expect(await stars(), isEmpty);
    });

    test('treats corrupt or out-of-range data as no progress', () async {
      await store.setString(ProgressRepositoryImpl.storageKey, 'not json');
      expect(await stars(), isEmpty);
      await store.setString(
        ProgressRepositoryImpl.storageKey,
        '{"a": 9, "b": "x", "c": 2}',
      );
      expect(await stars(), {'c': 2});
    });
  });

  group('SaveActivityResult', () {
    test('clamps stars into the 1-3 range', () async {
      final repository = ProgressRepositoryImpl(InMemoryKeyValueStore());
      final save = SaveActivityResult(repository);
      await save(const ActivityResult(activityId: 'a', stars: 7));
      await save(const ActivityResult(activityId: 'b', stars: 0));
      expect((await repository.getStars()).getOrElse(() => {}), {
        'a': 3,
        'b': 1,
      });
    });
  });

  group('SettingsRepositoryImpl', () {
    test('defaults to Arabic with all audio on', () {
      final repository = SettingsRepositoryImpl(InMemoryKeyValueStore());
      expect(repository.load(), const AppSettings());
      expect(repository.load().languageCode, 'ar');
    });

    test('round-trips saved settings', () async {
      final store = InMemoryKeyValueStore();
      const saved = AppSettings(languageCode: 'en', sfxOn: false);
      await SettingsRepositoryImpl(store).save(saved);
      expect(SettingsRepositoryImpl(store).load(), saved);
    });

    test('falls back to defaults on corrupt data', () async {
      final store = InMemoryKeyValueStore();
      await store.setString(SettingsRepositoryImpl.storageKey, '{{{');
      expect(SettingsRepositoryImpl(store).load(), const AppSettings());
    });
  });
}
