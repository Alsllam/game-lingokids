import 'dart:math';

import 'package:equatable/equatable.dart';

import '../../catalog/domain/entities/catalog.dart';
import '../../../core/domain/item_visual.dart';

/// Pure game rules. No Flutter, no storage, no audio - only data in and data
/// out, so every rule can be unit-tested and reused by any screen.

// ---------------------------------------------------------------------------
// Scoring
// ---------------------------------------------------------------------------

abstract final class StarCalculator {
  /// 3 stars for a perfect run, 2 when mistakes are at most half the number
  /// of questions, otherwise 1. Finishing always earns at least one star.
  static int stars({required int mistakes, required int questions}) {
    if (mistakes <= 0) return 3;
    if (mistakes * 2 <= questions) return 2;
    return 1;
  }
}

// ---------------------------------------------------------------------------
// Template 1: choice ("find it")
// ---------------------------------------------------------------------------

final class ChoiceRound extends Equatable {
  const ChoiceRound({required this.target, required this.options});

  /// The item the child is asked to find.
  final LearningItem target;

  /// Shuffled options; always contains [target].
  final List<LearningItem> options;

  @override
  List<Object?> get props => [target, options];
}

abstract final class ChoiceGameBuilder {
  /// Builds [rounds] rounds with up to [optionCount] options each.
  ///
  /// Targets cycle through all items before repeating, and the same target
  /// never appears twice in a row.
  static List<ChoiceRound> build({
    required List<LearningItem> items,
    required int rounds,
    required Random random,
    int optionCount = 3,
  }) {
    assert(items.length >= 2, 'a choice game needs at least 2 items');
    final options = min(optionCount, items.length);
    final result = <ChoiceRound>[];
    var queue = <LearningItem>[];
    LearningItem? previous;
    for (var i = 0; i < rounds; i++) {
      if (queue.isEmpty) {
        queue = [...items]..shuffle(random);
        if (queue.first == previous && queue.length > 1) {
          queue.add(queue.removeAt(0));
        }
      }
      final target = queue.removeAt(0);
      previous = target;
      final distractors = items.where((item) => item != target).toList()
        ..shuffle(random);
      final roundOptions = [target, ...distractors.take(options - 1)]
        ..shuffle(random);
      result.add(ChoiceRound(target: target, options: roundOptions));
    }
    return result;
  }
}

// ---------------------------------------------------------------------------
// Template 2: memory
// ---------------------------------------------------------------------------

final class MemoryCard extends Equatable {
  const MemoryCard({
    required this.index,
    required this.item,
    required this.visual,
  });

  /// Position in the deck.
  final int index;
  final LearningItem item;

  /// What the face of the card shows.
  final ItemVisual visual;

  @override
  List<Object?> get props => [index, item, visual];
}

abstract final class MemoryDeckBuilder {
  /// Builds a shuffled deck of [maxPairs] pairs at most. Each pair is the
  /// item's picture twice, so pre-readers can play.
  static List<MemoryCard> build({
    required List<LearningItem> items,
    required Random random,
    int maxPairs = 6,
  }) {
    final chosen = ([...items]..shuffle(random)).take(maxPairs).toList();
    final faces = <LearningItem>[...chosen, ...chosen]..shuffle(random);
    return [
      for (var i = 0; i < faces.length; i++)
        MemoryCard(index: i, item: faces[i], visual: faces[i].visual),
    ];
  }
}

// ---------------------------------------------------------------------------
// Template 3: drag-and-drop matching
// ---------------------------------------------------------------------------

final class MatchRound extends Equatable {
  const MatchRound({required this.sources, required this.targets});

  /// Draggable pieces (the item's main picture), shuffled.
  final List<LearningItem> sources;

  /// Drop targets (the item's pair or written name), shuffled independently.
  final List<LearningItem> targets;

  @override
  List<Object?> get props => [sources, targets];
}

abstract final class MatchGameBuilder {
  /// Splits the items into rounds of [perRound] pieces. A trailing round with
  /// a single piece is merged into the previous one so no round is trivial.
  static List<MatchRound> build({
    required List<LearningItem> items,
    required Random random,
    int perRound = 3,
  }) {
    final pool = [...items]..shuffle(random);
    final groups = <List<LearningItem>>[];
    for (var i = 0; i < pool.length; i += perRound) {
      groups.add(pool.sublist(i, min(i + perRound, pool.length)));
    }
    if (groups.length > 1 && groups.last.length == 1) {
      final orphan = groups.removeLast();
      groups.last.addAll(orphan);
    }
    return [
      for (final group in groups)
        MatchRound(
          sources: [...group]..shuffle(random),
          targets: [...group]..shuffle(random),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Template 4: tracing a letter with a finger
// ---------------------------------------------------------------------------

abstract final class TracePath {
  /// Turns a few control points into a smooth, evenly dense list of
  /// checkpoints (a Catmull-Rom spline through every control point).
  ///
  /// Two points give a straight line; one point stays a single dot.
  static List<TracePoint> densify(
    List<TracePoint> control, {
    double step = 0.03,
  }) {
    if (control.length == 1) return [control.first];
    final count = control.length;
    final result = <TracePoint>[control.first];
    for (var i = 0; i < count - 1; i++) {
      final p0 = control[max(i - 1, 0)];
      final p1 = control[i];
      final p2 = control[i + 1];
      final p3 = control[min(i + 2, count - 1)];
      final length = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
      final pieces = max(1, (length / step).ceil());
      for (var j = 1; j <= pieces; j++) {
        final t = j / pieces;
        if (count == 2) {
          result.add(
            TracePoint(p1.x + (p2.x - p1.x) * t, p1.y + (p2.y - p1.y) * t),
          );
        } else {
          result.add(
            TracePoint(
              _spline(p0.x, p1.x, p2.x, p3.x, t),
              _spline(p0.y, p1.y, p2.y, p3.y, t),
            ),
          );
        }
      }
    }
    return result;
  }

  static double _spline(double a, double b, double c, double d, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    return 0.5 *
        ((2 * b) +
            (-a + c) * t +
            (2 * a - 5 * b + 4 * c - d) * t2 +
            (-a + 3 * b - 3 * c + d) * t3);
  }
}

/// What a finger position did to the tracing.
enum TraceEvent {
  /// Nothing changed (finger away from the line, or already finished).
  none,

  /// The line advanced.
  progressed,

  /// The current stroke is complete; another one follows.
  strokeDone,

  /// Every stroke is complete.
  done,
}

/// Follows a finger along the strokes of one letter.
///
/// Each stroke is a chain of checkpoints. The finger must reach them in
/// order, so a stroke can only be drawn from its start and in the right
/// direction - but lifting the finger keeps the progress, because small
/// children rarely manage a stroke in one go.
final class TraceTracker {
  TraceTracker(
    List<TraceStroke> strokes, {
    this.tolerance = 0.11,
    double step = 0.03,
  }) : paths = [
         for (final stroke in strokes)
           TracePath.densify(stroke.points, step: step),
       ];

  /// The checkpoints of every stroke.
  final List<List<TracePoint>> paths;

  /// How close (as a fraction of the box) the finger must come.
  final double tolerance;

  /// Index of the stroke being drawn.
  int stroke = 0;

  /// How many checkpoints of the current stroke are done.
  int reached = 0;

  /// How often the finger wandered clearly off the line mid-stroke.
  int slips = 0;

  bool _offLine = false;

  bool get isDone => stroke >= paths.length;

  /// The checkpoint the finger has to reach next, or null when finished.
  TracePoint? get nextPoint => isDone ? null : paths[stroke][reached];

  /// Reports a finger position in box coordinates (0..1).
  TraceEvent touch(double x, double y) {
    if (isDone) return TraceEvent.none;
    final path = paths[stroke];
    var advanced = false;
    while (reached < path.length && _near(path[reached], x, y, tolerance)) {
      reached++;
      advanced = true;
    }

    if (!advanced) {
      // Count one slip per excursion, and only once the stroke is under way.
      if (reached > 0 && !_offLine && !_near(path[reached], x, y, tolerance * 2.5)) {
        _offLine = true;
        slips++;
      }
      return TraceEvent.none;
    }

    _offLine = false;
    if (reached < path.length) return TraceEvent.progressed;
    stroke++;
    reached = 0;
    return isDone ? TraceEvent.done : TraceEvent.strokeDone;
  }

  /// The finger left the screen.
  void lift() {
    _offLine = false;
  }

  static bool _near(TracePoint point, double x, double y, double radius) {
    final dx = point.x - x;
    final dy = point.y - y;
    return dx * dx + dy * dy <= radius * radius;
  }
}
