import 'package:dartz/dartz.dart';

import '../error/failure.dart';

/// Base contract: one public `call`, always returning `Either<Failure, T>`.
abstract interface class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Marker for use cases that take no input.
final class NoParams {
  const NoParams();
}
