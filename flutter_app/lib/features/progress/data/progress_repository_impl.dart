import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/progress_repository.dart';

final class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._store);

  static const storageKey = 'progress.stars.v1';

  final KeyValueStore _store;

  @override
  Future<Either<Failure, StarsByActivity>> getStars() async {
    try {
      return Right(_read());
    } on Exception catch (error) {
      return Left(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, StarsByActivity>> saveBest({
    required String activityId,
    required int stars,
  }) async {
    try {
      final all = _read();
      if (stars > (all[activityId] ?? 0)) {
        all[activityId] = stars;
        await _store.setString(storageKey, jsonEncode(all));
      }
      return Right(all);
    } on Exception catch (error) {
      return Left(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> reset() async {
    try {
      await _store.remove(storageKey);
      return const Right(unit);
    } on Exception catch (error) {
      return Left(StorageFailure(error.toString()));
    }
  }

  /// A corrupt value is treated as "no progress" instead of crashing.
  StarsByActivity _read() {
    final raw = _store.getString(storageKey);
    if (raw == null) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    if (decoded is! Map<String, Object?>) return {};
    final result = <String, int>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is int && value >= 1 && value <= 3) {
        result[entry.key] = value;
      }
    }
    return result;
  }
}
