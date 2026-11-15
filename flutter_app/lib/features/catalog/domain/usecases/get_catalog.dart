import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/catalog.dart';
import '../repositories/catalog_repository.dart';

final class GetCatalog implements UseCase<Catalog, NoParams> {
  const GetCatalog(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, Catalog>> call(NoParams params) =>
      _repository.getCatalog();
}
