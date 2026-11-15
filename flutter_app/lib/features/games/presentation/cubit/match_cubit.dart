import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../catalog/domain/entities/catalog.dart';
import '../../domain/game_engines.dart';
import 'game_feedback.dart';

final class MatchState extends Equatable {
  const MatchState({
    required this.rounds,
    this.index = 0,
    this.matched = const {},
    this.mistakes = 0,
    this.wrongTargetId,
    this.wrongTick = 0,
    this.finished = false,
    this.feedback = GameFeedback.none,
    this.feedbackTick = 0,
  });

  final List<MatchRound> rounds;
  final int index;

  /// Item ids already dropped on the right target in this round.
  final Set<String> matched;
  final int mistakes;

  /// The target that last received a wrong piece (it shakes).
  final String? wrongTargetId;

  /// Increases with every wrong drop so the same target can shake twice.
  final int wrongTick;
  final bool finished;
  final GameFeedback feedback;
  final int feedbackTick;

  MatchRound get round => rounds[index];

  int get totalPieces =>
      rounds.fold(0, (sum, round) => sum + round.sources.length);

  int get stars =>
      StarCalculator.stars(mistakes: mistakes, questions: totalPieces);

  MatchState copyWith({
    int? index,
    Set<String>? matched,
    int? mistakes,
    String? wrongTargetId,
    bool? finished,
    GameFeedback? feedback,
  }) {
    return MatchState(
      rounds: rounds,
      index: index ?? this.index,
      matched: matched ?? this.matched,
      mistakes: mistakes ?? this.mistakes,
      wrongTargetId: wrongTargetId ?? this.wrongTargetId,
      wrongTick: wrongTargetId == null ? wrongTick : wrongTick + 1,
      finished: finished ?? this.finished,
      feedback: feedback ?? this.feedback,
      feedbackTick: feedback == null ? feedbackTick : feedbackTick + 1,
    );
  }

  @override
  List<Object?> get props => [
    rounds,
    index,
    matched,
    mistakes,
    wrongTargetId,
    wrongTick,
    finished,
    feedback,
    feedbackTick,
  ];
}

final class MatchCubit extends Cubit<MatchState> {
  MatchCubit({
    required ActivityBundle bundle,
    required Random random,
    this.celebrateFor = const Duration(milliseconds: 900),
  }) : super(
         MatchState(
           rounds: MatchGameBuilder.build(items: bundle.items, random: random),
         ),
       );

  final Duration celebrateFor;

  /// A dragged piece ([sourceId]) was released over a target ([targetId]).
  Future<void> drop({
    required String sourceId,
    required String targetId,
  }) async {
    if (state.finished || state.matched.contains(targetId)) return;

    if (sourceId != targetId) {
      emit(
        state.copyWith(
          mistakes: state.mistakes + 1,
          wrongTargetId: targetId,
          feedback: GameFeedback.wrong,
        ),
      );
      return;
    }

    final matched = {...state.matched, sourceId};
    emit(state.copyWith(matched: matched, feedback: GameFeedback.correct));
    if (matched.length < state.round.sources.length) return;

    await Future<void>.delayed(celebrateFor);
    if (isClosed) return;
    if (state.index + 1 >= state.rounds.length) {
      emit(state.copyWith(finished: true, feedback: GameFeedback.finished));
    } else {
      emit(state.copyWith(index: state.index + 1, matched: const {}));
    }
  }
}
