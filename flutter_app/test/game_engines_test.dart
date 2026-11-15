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
}
