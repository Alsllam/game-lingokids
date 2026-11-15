import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/catalog.dart';
import '../../domain/game_engines.dart';
import 'game_feedback.dart';

final class TraceState extends Equatable {
  const TraceState({
    required this.items,
    required this.paths,
    this.index = 0,
    this.stroke = 0,
    this.reached = 0,
    this.slips = 0,
    this.solved = false,
    this.finished = false,
    this.feedback = GameFeedback.none,
    this.feedbackTick = 0,
  });

  /// The letters to write, in order.
  final List<LearningItem> items;

  /// Checkpoints of every stroke of the current letter.
  final List<List<TracePoint>> paths;

  /// Which letter is being written.
  final int index;

  /// Which stroke of that letter, and how far along it.
  final int stroke;
  final int reached;

  /// Slips over the whole activity.
  final int slips;

  /// True while a finished letter is being celebrated.
  final bool solved;
  final bool finished;
  final GameFeedback feedback;
  final int feedbackTick;

  LearningItem get item => items[index];

  /// Tracing is forgiving: three slips per letter still earn two stars.
  int get stars =>
      StarCalculator.stars(mistakes: slips, questions: items.length * 6);

  @override
  List<Object?> get props => [
    items,
    paths,
    index,
    stroke,
    reached,
    slips,
    solved,
    finished,
    feedback,
    feedbackTick,
  ];
}

final class TraceCubit extends Cubit<TraceState> {
  TraceCubit({
    required ActivityBundle bundle,
    required this.languageCode,
    required Random random,
    this.celebrateFor = const Duration(milliseconds: 1400),
  }) : super(_initial(bundle, languageCode, random)) {
    _tracker = TraceTracker(state.item.tracesFor(languageCode));
  }

  /// Letters differ per language, so the game is built for one language.
  final String languageCode;
  final Duration celebrateFor;

  late TraceTracker _tracker;
  int _slipsBefore = 0;

  static TraceState _initial(
    ActivityBundle bundle,
    String languageCode,
    Random random,
  ) {
    final traceable = bundle.items
        .where((item) => item.tracesFor(languageCode).isNotEmpty)
        .toList();
    assert(traceable.isNotEmpty, 'a trace game needs items with traces');
    final items = (traceable..shuffle(random))
        .take(max(1, bundle.activity.rounds))
        .toList(growable: false);
    return TraceState(
      items: items,
      paths: TraceTracker(items.first.tracesFor(languageCode)).paths,
    );
  }

  /// The finger is at ([x], [y]) in box coordinates (0..1).
  Future<void> touch(double x, double y) async {
    if (state.solved || state.finished) return;
    final slipsBefore = _tracker.slips;
    final event = _tracker.touch(x, y);
    if (event == TraceEvent.none && _tracker.slips == slipsBefore) return;

    final slips = _slipsBefore + _tracker.slips;
    if (event != TraceEvent.done) {
      _emit(
        slips: slips,
        // A slip is the only thing worth a reaction mid-letter; finished
        // strokes are shown by the screen itself.
        feedback: event == TraceEvent.none ? GameFeedback.wrong : null,
      );
      return;
    }

    _emit(slips: slips, solved: true, feedback: GameFeedback.correct);
    await Future<void>.delayed(celebrateFor);
    if (isClosed) return;

    if (state.index + 1 >= state.items.length) {
      _emit(slips: slips, solved: true, finished: true, feedback: GameFeedback.finished);
      return;
    }
    final next = state.index + 1;
    _slipsBefore = slips;
    _tracker = TraceTracker(state.items[next].tracesFor(languageCode));
    emit(
      TraceState(
        items: state.items,
        paths: _tracker.paths,
        index: next,
        slips: slips,
        feedbackTick: state.feedbackTick,
      ),
    );
  }

  /// The finger left the screen.
  void lift() => _tracker.lift();

  void _emit({
    required int slips,
    bool solved = false,
    bool finished = false,
    GameFeedback? feedback,
  }) {
    emit(
      TraceState(
        items: state.items,
        paths: state.paths,
        index: state.index,
        stroke: _tracker.stroke,
        reached: _tracker.reached,
        slips: slips,
        solved: solved,
        finished: finished,
        feedback: feedback ?? state.feedback,
        feedbackTick: feedback == null
            ? state.feedbackTick
            : state.feedbackTick + 1,
      ),
    );
  }
}
