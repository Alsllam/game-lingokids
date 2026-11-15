import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'data/datasources/catalog_asset_data_source.dart';
import 'data/repositories/catalog_repository_impl.dart';
import 'domain/repositories/catalog_repository.dart';
import 'domain/usecases/get_activity_bundle.dart';
import 'domain/usecases/get_catalog.dart';
import 'presentation/catalog_cubit.dart';

void registerCatalog(GetIt getIt) {
  getIt
    ..registerLazySingleton(() => CatalogAssetDataSource(bundle: rootBundle))
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(getIt()),
    )
    ..registerLazySingleton(() => GetCatalog(getIt()))
    ..registerLazySingleton(() => GetActivityBundle(getIt()))
    ..registerFactory(() => CatalogCubit(getIt()));
}
