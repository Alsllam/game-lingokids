import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/audio/sound_player.dart';
import '../../core/audio/speaker.dart';
import '../../core/storage/key_value_store.dart';
import '../../core/storage/shared_prefs_key_value_store.dart';
import '../../features/catalog/catalog_injection.dart';
import '../../features/games/games_injection.dart';
import '../../features/progress/progress_injection.dart';
import '../../features/settings/settings_injection.dart';

final GetIt getIt = GetIt.instance;

/// Registers shared services first, then each feature's own objects.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<KeyValueStore>(SharedPrefsKeyValueStore(prefs))
    ..registerLazySingleton<SoundPlayer>(() => AssetSoundPlayer())
    ..registerLazySingleton<Speaker>(() => TtsSpeaker());

  registerCatalog(getIt);
  registerProgress(getIt);
  registerSettings(getIt);
  registerGames(getIt);
}
