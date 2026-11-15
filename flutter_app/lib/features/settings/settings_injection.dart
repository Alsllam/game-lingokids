import 'package:get_it/get_it.dart';

import 'data/settings_repository_impl.dart';
import 'domain/app_settings.dart';
import 'presentation/settings_cubit.dart';

void registerSettings(GetIt getIt) {
  getIt
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt()),
    )
    ..registerFactory(
      () => SettingsCubit(
        repository: getIt(),
        soundPlayer: getIt(),
        speaker: getIt(),
      ),
    );
}
