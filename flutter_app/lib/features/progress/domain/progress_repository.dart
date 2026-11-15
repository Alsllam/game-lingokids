import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';

/// Stars earned per activity id (1-3). Missing id = not played yet.
typedef StarsByActivity = Map<String, int>;

abstract interface class ProgressRepository {
  Future<Either<Failure, StarsByActivity>> getStars();

  /// Stores [stars] for the activity if it beats the previous best, and
  /// returns the updated map.
  Future<Either<Failure, StarsByActivity>> saveBest({
    required String activityId,
    required int stars,
  });

  Future<Either<Failure, Unit>> reset();
}
