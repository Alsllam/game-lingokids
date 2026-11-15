import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/core/domain/localized_text.dart';
import 'package:nujoom/features/catalog/domain/entities/catalog.dart';
import 'package:nujoom/core/domain/item_visual.dart';
import 'package:nujoom/features/games/domain/game_engines.dart';

List<LearningItem> makeItems(int count) => [
  for (var i = 0; i < count; i++)
    LearningItem(
      id: 'item$i',
      name: LocalizedText.same('Item $i'),
      visual: ItemVisual(
        kind: VisualKind.glyph,
        value: LocalizedText.same('$i'),
      ),
    ),
];

void main() {
  group('StarCalculator', () {
    test('gives 3 stars for a perfect run', () {
      expect(StarCalculator.stars(mistakes: 0, questions: 6), 3);
    });

    test('gives 2 stars when mistakes are at most half the questions', () {
      expect(StarCalculator.stars(mistakes: 1, questions: 6), 2);
      expect(StarCalculator.stars(mistakes: 3, questions: 6), 2);
    });

    test('never gives fewer than 1 star', () {
      expect(StarCalculator.stars(mistakes: 4, questions: 6), 1);
      expect(StarCalculator.stars(mistakes: 99, questions: 6), 1);
    });
  });

  group('ChoiceGameBuilder', () {
    test('every round contains its target among unique options', () {
      for (var seed = 0; seed < 50; seed++) {
        final rounds = ChoiceGameBuilder.build(
          items: makeItems(6),
          rounds: 8,
          random: Random(seed),
        );
        expect(rounds.length, 8);
        for (final round in rounds) {
          expect(round.options.length, 3);
          expect(round.options.contains(round.target), isTrue);
          expect(round.options.toSet().length, round.options.length);
        }
      }
    });

    test('never asks for the same target twice in a row', () {
      for (var seed = 0; seed < 50; seed++) {
        final rounds = ChoiceGameBuilder.build(
          items: makeItems(4),
          rounds: 12,
          random: Random(seed),
        );
        for (var i = 1; i < rounds.length; i++) {
          expect(rounds[i].target == rounds[i - 1].target, isFalse);
        }
      }
    });

    test('uses every item once before repeating any', () {
      final rounds = ChoiceGameBuilder.build(
        items: makeItems(5),
        rounds: 5,
        random: Random(7),
      );
      expect(rounds.map((round) => round.target.id).toSet().length, 5);
    });

    test('shrinks the options when there are only two items', () {
      final rounds = ChoiceGameBuilder.build(
        items: makeItems(2),
        rounds: 4,
        random: Random(1),
      );
      for (final round in rounds) {
        expect(round.options.length, 2);
      }
    });
  });

  group('MemoryDeckBuilder', () {
    test('contains exactly two cards per item, capped at maxPairs', () {
      final deck = MemoryDeckBuilder.build(
        items: makeItems(9),
        random: Random(3),
      );
      expect(deck.length, 12);
      final counts = <String, int>{};
      for (final card in deck) {
        counts[card.item.id] = (counts[card.item.id] ?? 0) + 1;
      }
      expect(counts.length, 6);
      expect(counts.values.every((count) => count == 2), isTrue);
    });

    test('numbers the cards by their position', () {
      final deck = MemoryDeckBuilder.build(
        items: makeItems(3),
        random: Random(3),
      );
      for (var i = 0; i < deck.length; i++) {
        expect(deck[i].index, i);
      }
    });
  });

  group('MatchGameBuilder', () {
    test('uses every item exactly once across rounds', () {
      for (var count = 2; count <= 10; count++) {
        final rounds = MatchGameBuilder.build(
          items: makeItems(count),
          random: Random(count),
        );
        final used = [for (final round in rounds) ...round.sources];
        expect(used.length, count);
        expect(used.toSet().length, count);
      }
    });

    test('sources and targets of a round hold the same items', () {
      final rounds = MatchGameBuilder.build(
        items: makeItems(6),
        random: Random(5),
      );
      for (final round in rounds) {
        expect(round.sources.toSet(), round.targets.toSet());
      }
    });

    test('never leaves a round with a single piece', () {
      for (var count = 2; count <= 10; count++) {
        final rounds = MatchGameBuilder.build(
          items: makeItems(count),
          random: Random(1),
        );
        for (final round in rounds) {
          expect(round.sources.length >= 2, isTrue);
        }
      }
    });
  });

  group('TracePath.densify', () {
    test('keeps a single point as a dot', () {
      expect(TracePath.densify(const [TracePoint(0.5, 0.5)]).length, 1);
    });

    test('a two-point stroke is a straight, evenly spaced line', () {
      final points = TracePath.densify(const [
        TracePoint(0.2, 0.5),
        TracePoint(0.8, 0.5),
      ]);
      expect(points.first, const TracePoint(0.2, 0.5));
      expect((points.last.x - 0.8).abs() < 1e-9, isTrue);
      for (var i = 1; i < points.length; i++) {
        expect((points[i].y - 0.5).abs() < 1e-9, isTrue);
        expect(points[i].x - points[i - 1].x <= 0.03 + 1e-9, isTrue);
        expect(points[i].x > points[i - 1].x, isTrue);
      }
    });

    test('a curve passes through every control point', () {
      const control = [
        TracePoint(0.8, 0.3),
        TracePoint(0.5, 0.15),
        TracePoint(0.2, 0.5),
        TracePoint(0.5, 0.85),
      ];
      final points = TracePath.densify(control);
      for (final wanted in control) {
        final hit = points.any(
          (p) => (p.x - wanted.x).abs() < 1e-9 && (p.y - wanted.y).abs() < 1e-9,
        );
        expect(hit, isTrue);
      }
    });
  });

  group('TraceTracker', () {
    const line = TraceStroke([TracePoint(0.2, 0.5), TracePoint(0.8, 0.5)]);
    const dot = TraceStroke([TracePoint(0.5, 0.2)]);

    /// Drags a finger along a stroke until it completes, and returns the
    /// event that completed it. (The stroke finishes a little before the
    /// finger reaches the very end, because of the tolerance.)
    TraceEvent follow(TraceTracker tracker, int strokeIndex) {
      for (final point in [...tracker.paths[strokeIndex]]) {
        final event = tracker.touch(point.x, point.y);
        if (event == TraceEvent.strokeDone || event == TraceEvent.done) {
          return event;
        }
      }
      return TraceEvent.none;
    }

    test('following the line completes it', () {
      final tracker = TraceTracker(const [line]);
      expect(follow(tracker, 0), TraceEvent.done);
      expect(tracker.isDone, isTrue);
      expect(tracker.slips, 0);
      expect(tracker.touch(0.5, 0.5), TraceEvent.none);
    });

    test('a stroke must be started from its beginning', () {
      final tracker = TraceTracker(const [line]);
      expect(tracker.touch(0.8, 0.5), TraceEvent.none);
      expect(tracker.touch(0.5, 0.5), TraceEvent.none);
      expect(tracker.reached, 0);
      expect(tracker.touch(0.2, 0.5), TraceEvent.progressed);
    });

    test('jumping ahead does not skip the middle', () {
      final tracker = TraceTracker(const [line]);
      tracker.touch(0.2, 0.5);
      final before = tracker.reached;
      expect(tracker.touch(0.8, 0.5), TraceEvent.none);
      expect(tracker.reached, before);
    });

    test('lifting the finger keeps the progress', () {
      final tracker = TraceTracker(const [line]);
      tracker.touch(0.2, 0.5);
      tracker.touch(0.4, 0.5);
      final before = tracker.reached;
      tracker.lift();
      expect(tracker.reached, before);
      expect(tracker.touch(0.5, 0.5), TraceEvent.progressed);
    });

    test('a slightly wobbly finger is still accepted', () {
      final tracker = TraceTracker(const [line]);
      for (var x = 0.2; x <= 0.81; x += 0.02) {
        tracker.touch(x, 0.5 + 0.06 * sin(x * 40));
      }
      expect(tracker.isDone, isTrue);
      expect(tracker.slips, 0);
    });

    test('one excursion off the line counts as one slip', () {
      final tracker = TraceTracker(const [line]);
      expect(tracker.touch(0.5, 0.95), TraceEvent.none);
      expect(tracker.slips, 0); // not started yet: no slip
      tracker.touch(0.2, 0.5);
      tracker.touch(0.3, 0.95);
      tracker.touch(0.3, 0.9);
      expect(tracker.slips, 1);
      tracker.touch(0.3, 0.5); // back on the line
      tracker.touch(0.4, 0.95);
      expect(tracker.slips, 2);
    });

    test('strokes come in order and a dot needs one touch', () {
      final tracker = TraceTracker(const [line, dot]);
      expect(tracker.touch(0.5, 0.2), TraceEvent.none); // the dot is not due yet
      expect(follow(tracker, 0), TraceEvent.strokeDone);
      expect(tracker.stroke, 1);
      expect(tracker.nextPoint, const TracePoint(0.5, 0.2));
      expect(tracker.touch(0.52, 0.22), TraceEvent.done);
      expect(tracker.nextPoint, isNull);
    });
  });
}
