import 'package:get_it/get_it.dart';

import 'data/progress_repository_impl.dart';
import 'domain/progress_repository.dart';
import 'domain/progress_usecases.dart';
import 'presentation/progress_cubit.dart';

void registerProgress(GetIt getIt) {
  getIt
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetProgress(getIt()))
    ..registerLazySingleton(() => SaveActivityResult(getIt()))
    ..registerLazySingleton(() => ResetProgress(getIt()))
    ..registerFactory(
      () => ProgressCubit(
        getProgress: getIt(),
        saveActivityResult: getIt(),
        resetProgress: getIt(),
      ),
    );
}
