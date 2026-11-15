import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/catalog.dart';
import '../repositories/catalog_repository.dart';

/// Finds an activity by id and resolves the items it plays with.
final class GetActivityBundle implements UseCase<ActivityBundle, String> {
  const GetActivityBundle(this._repository);

  final CatalogRepository _repository;

  @override
  Future<Either<Failure, ActivityBundle>> call(String activityId) async {
    final result = await _repository.getCatalog();
    return result.fold((failure) => Left(failure), (catalog) {
      for (final topic in catalog.topics) {
        for (final activity in topic.activities) {
          if (activity.id != activityId) continue;
          final items = activity.itemIds.isEmpty
              ? topic.items
              : topic.items
                    .where((item) => activity.itemIds.contains(item.id))
                    .toList();
          if (items.length < 2) {
            return Left(
              ContentFailure('Activity $activityId needs at least 2 items'),
            );
          }
          return Right(
            ActivityBundle(topic: topic, activity: activity, items: items),
          );
        }
      }
      return Left(NotFoundFailure('Activity $activityId'));
    });
  }
}
