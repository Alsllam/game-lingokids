import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/catalog.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_asset_data_source.dart';
import '../mappers/catalog_parser.dart';

final class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._assets);

  final CatalogAssetDataSource _assets;
  Catalog? _cache;

  @override
  Future<Either<Failure, Catalog>> getCatalog() async {
    final cached = _cache;
    if (cached != null) return Right(cached);
    try {
      final catalog = CatalogParser.parse(await _assets.readCatalogJson());
      _cache = catalog;
      return Right(catalog);
    } on FormatException catch (error) {
      return Left(ContentFailure(error.message));
    } on Exception catch (error) {
      return Left(ContentFailure(error.toString()));
    }
  }
}
