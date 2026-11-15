import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../catalog/domain/entities/catalog.dart';
import '../../../catalog/domain/usecases/get_activity_bundle.dart';

sealed class GameSessionState extends Equatable {
  const GameSessionState();

  @override
  List<Object?> get props => [];
}

final class GameSessionLoading extends GameSessionState {
  const GameSessionLoading();
}

final class GameSessionFailed extends GameSessionState {
  const GameSessionFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class GameSessionReady extends GameSessionState {
  const GameSessionReady(this.bundle);

  final ActivityBundle bundle;

  @override
  List<Object?> get props => [bundle];
}

/// Loads the activity a game screen was opened for.
final class GameSessionCubit extends Cubit<GameSessionState> {
  GameSessionCubit(this._getActivityBundle)
    : super(const GameSessionLoading());

  final GetActivityBundle _getActivityBundle;

  Future<void> load(String activityId) async {
    emit(const GameSessionLoading());
    final result = await _getActivityBundle(activityId);
    if (isClosed) return;
    emit(result.fold(GameSessionFailed.new, GameSessionReady.new));
  }
}
