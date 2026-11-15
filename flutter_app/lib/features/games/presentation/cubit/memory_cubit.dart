import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../../catalog/domain/entities/catalog.dart';
import '../../domain/game_engines.dart';
import 'game_feedback.dart';

final class MemoryState extends Equatable {
  const MemoryState({
    required this.cards,
    this.faceUp = const [],
    this.matched = const {},
    this.mistakes = 0,
    this.busy = false,
    this.finished = false,
    this.feedback = GameFeedback.none,
    this.feedbackTick = 0,
  });

  final List<MemoryCard> cards;

  /// Indices of the (at most two) cards currently turned over.
  final List<int> faceUp;

  /// Indices of cards whose pair was found.
  final Set<int> matched;
  final int mistakes;

  /// True while two non-matching cards are shown before flipping back.
  final bool busy;
  final bool finished;
  final GameFeedback feedback;
  final int feedbackTick;

  bool isFaceUp(int index) => faceUp.contains(index) || matched.contains(index);

  int get stars =>
      StarCalculator.stars(mistakes: mistakes, questions: cards.length);

  MemoryState copyWith({
    List<int>? faceUp,
    Set<int>? matched,
    int? mistakes,
    bool? busy,
    bool? finished,
    GameFeedback? feedback,
  }) {
    return MemoryState(
      cards: cards,
      faceUp: faceUp ?? this.faceUp,
      matched: matched ?? this.matched,
      mistakes: mistakes ?? this.mistakes,
      busy: busy ?? this.busy,
      finished: finished ?? this.finished,
      feedback: feedback ?? this.feedback,
      feedbackTick: feedback == null ? feedbackTick : feedbackTick + 1,
    );
  }

  @override
  List<Object?> get props => [
    cards,
    faceUp,
    matched,
    mistakes,
    busy,
    finished,
    feedback,
    feedbackTick,
  ];
}

final class MemoryCubit extends Cubit<MemoryState> {
  MemoryCubit({
    required ActivityBundle bundle,
    required Random random,
    this.showMismatchFor = const Duration(milliseconds: 900),
    this.celebrateFor = const Duration(milliseconds: 700),
  }) : super(
         MemoryState(
           cards: MemoryDeckBuilder.build(items: bundle.items, random: random),
         ),
       );

  final Duration showMismatchFor;
  final Duration celebrateFor;

  /// Turns a card over. Ignored while a mismatch is on show.
  Future<void> flip(int index) async {
    if (state.busy || state.finished || state.isFaceUp(index)) return;

    final faceUp = [...state.faceUp, index];
    if (faceUp.length < 2) {
      emit(state.copyWith(faceUp: faceUp));
      return;
    }

    final first = state.cards[faceUp[0]];
    final second = state.cards[faceUp[1]];
    if (first.item.id == second.item.id) {
      final matched = {...state.matched, ...faceUp};
      emit(
        state.copyWith(
          faceUp: const [],
          matched: matched,
          feedback: GameFeedback.correct,
        ),
      );
      if (matched.length == state.cards.length) {
        await Future<void>.delayed(celebrateFor);
        if (isClosed) return;
        emit(state.copyWith(finished: true, feedback: GameFeedback.finished));
      }
      return;
    }

    emit(
      state.copyWith(
        faceUp: faceUp,
        busy: true,
        mistakes: state.mistakes + 1,
        feedback: GameFeedback.wrong,
      ),
    );
    await Future<void>.delayed(showMismatchFor);
    if (isClosed) return;
    emit(state.copyWith(faceUp: const [], busy: false));
  }
}
