import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/catalog.dart';

abstract interface class CatalogRepository {
  /// Loads all topics and activities. Implementations may cache the result.
  Future<Either<Failure, Catalog>> getCatalog();
}
