import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../core/usecase/usecase.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_usecases.dart';

final class ProgressState extends Equatable {
  const ProgressState({this.stars = const {}});

  final StarsByActivity stars;

  int starsFor(String activityId) => stars[activityId] ?? 0;

  int get total => stars.values.fold(0, (sum, value) => sum + value);

  @override
  List<Object?> get props => [stars];
}

/// App-wide stars. Lives above the router so every screen sees the same data.
final class ProgressCubit extends Cubit<ProgressState> {
  ProgressCubit({
    required GetProgress getProgress,
    required SaveActivityResult saveActivityResult,
    required ResetProgress resetProgress,
  }) : _getProgress = getProgress,
       _saveActivityResult = saveActivityResult,
       _resetProgress = resetProgress,
       super(const ProgressState());

  final GetProgress _getProgress;
  final SaveActivityResult _saveActivityResult;
  final ResetProgress _resetProgress;

  Future<void> load() async {
    final result = await _getProgress(const NoParams());
    result.fold((_) {}, (stars) => emit(ProgressState(stars: stars)));
  }

  Future<void> record({required String activityId, required int stars}) async {
    final result = await _saveActivityResult(
      ActivityResult(activityId: activityId, stars: stars),
    );
    // A new map instance is emitted so Equatable sees the change.
    result.fold((_) {}, (all) => emit(ProgressState(stars: {...all})));
  }

  Future<bool> reset() async {
    final result = await _resetProgress(const NoParams());
    return result.fold((_) => false, (_) {
      emit(const ProgressState());
      return true;
    });
  }
}
