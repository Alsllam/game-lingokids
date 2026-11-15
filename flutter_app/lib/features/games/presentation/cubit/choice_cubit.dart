import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../catalog/domain/entities/catalog.dart';
import '../../domain/game_engines.dart';
import 'game_feedback.dart';

final class ChoiceState extends Equatable {
  const ChoiceState({
    required this.rounds,
    this.index = 0,
    this.eliminated = const {},
    this.solved = false,
    this.mistakes = 0,
    this.finished = false,
    this.feedback = GameFeedback.none,
    this.feedbackTick = 0,
  });

  final List<ChoiceRound> rounds;
  final int index;

  /// Ids of wrong options already tried in the current round.
  final Set<String> eliminated;

  /// True while the correct answer is being celebrated.
  final bool solved;
  final int mistakes;
  final bool finished;
  final GameFeedback feedback;

  /// Increases with every feedback so listeners fire even for repeats.
  final int feedbackTick;

  ChoiceRound get round => rounds[index];

  int get stars =>
      StarCalculator.stars(mistakes: mistakes, questions: rounds.length);

  ChoiceState copyWith({
    int? index,
    Set<String>? eliminated,
    bool? solved,
    int? mistakes,
    bool? finished,
    GameFeedback? feedback,
  }) {
    return ChoiceState(
      rounds: rounds,
      index: index ?? this.index,
      eliminated: eliminated ?? this.eliminated,
      solved: solved ?? this.solved,
      mistakes: mistakes ?? this.mistakes,
      finished: finished ?? this.finished,
      feedback: feedback ?? this.feedback,
      feedbackTick: feedback == null ? feedbackTick : feedbackTick + 1,
    );
  }

  @override
  List<Object?> get props => [
    rounds,
    index,
    eliminated,
    solved,
    mistakes,
    finished,
    feedback,
    feedbackTick,
  ];
}

final class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit({
    required ActivityBundle bundle,
    required Random random,
    this.celebrateFor = const Duration(milliseconds: 1100),
  }) : super(
         ChoiceState(
           rounds: ChoiceGameBuilder.build(
             items: bundle.items,
             rounds: bundle.activity.rounds,
             random: random,
           ),
         ),
       );

  /// How long the correct answer stays highlighted before the next round.
  final Duration celebrateFor;

  Future<void> pick(LearningItem item) async {
    if (state.solved || state.finished) return;
    if (state.eliminated.contains(item.id)) return;

    if (item.id != state.round.target.id) {
      emit(
        state.copyWith(
          eliminated: {...state.eliminated, item.id},
          mistakes: state.mistakes + 1,
          feedback: GameFeedback.wrong,
        ),
      );
      return;
    }

    emit(state.copyWith(solved: true, feedback: GameFeedback.correct));
    await Future<void>.delayed(celebrateFor);
    if (isClosed) return;

    if (state.index + 1 >= state.rounds.length) {
      emit(state.copyWith(finished: true, feedback: GameFeedback.finished));
    } else {
      emit(
        state.copyWith(
          index: state.index + 1,
          eliminated: const {},
          solved: false,
        ),
      );
    }
  }
}
