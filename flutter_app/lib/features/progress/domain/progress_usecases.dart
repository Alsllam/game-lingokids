import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';
import '../../../core/usecase/usecase.dart';
import 'progress_repository.dart';

final class GetProgress implements UseCase<StarsByActivity, NoParams> {
  const GetProgress(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, StarsByActivity>> call(NoParams params) =>
      _repository.getStars();
}

final class ActivityResult {
  const ActivityResult({required this.activityId, required this.stars});

  final String activityId;
  final int stars;
}

final class SaveActivityResult
    implements UseCase<StarsByActivity, ActivityResult> {
  const SaveActivityResult(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, StarsByActivity>> call(ActivityResult params) {
    final stars = params.stars.clamp(1, 3);
    return _repository.saveBest(activityId: params.activityId, stars: stars);
  }
}

final class ResetProgress implements UseCase<Unit, NoParams> {
  const ResetProgress(this._repository);

  final ProgressRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.reset();
}
