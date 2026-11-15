import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/core/domain/localized_text.dart';
import 'package:nujoom/features/catalog/domain/entities/catalog.dart';
import 'package:nujoom/core/domain/item_visual.dart';
import 'package:nujoom/features/games/presentation/cubit/choice_cubit.dart';
import 'package:nujoom/features/games/presentation/cubit/game_feedback.dart';
import 'package:nujoom/features/games/presentation/cubit/match_cubit.dart';
import 'package:nujoom/features/games/presentation/cubit/memory_cubit.dart';

ActivityBundle makeBundle(GameType type, {int items = 4, int rounds = 3}) {
  final list = [
    for (var i = 0; i < items; i++)
      LearningItem(
        id: 'item$i',
        name: LocalizedText.same('Item $i'),
        visual: ItemVisual(
          kind: VisualKind.glyph,
          value: LocalizedText.same('$i'),
        ),
      ),
  ];
  final activity = Activity(
    id: 'act',
    topicId: 'topic',
    type: type,
    itemIds: const [],
    rounds: rounds,
  );
  return ActivityBundle(
    topic: Topic(
      id: 'topic',
      title: const LocalizedText.same('Topic'),
      color: 0xFF000000,
      icon: const ItemVisual(
        kind: VisualKind.emoji,
        value: LocalizedText.same('*'),
      ),
      items: list,
      activities: [activity],
    ),
    activity: activity,
    items: list,
  );
}

void main() {
  group('ChoiceCubit', () {
    ChoiceCubit build() => ChoiceCubit(
      bundle: makeBundle(GameType.choice),
      random: Random(1),
      celebrateFor: Duration.zero,
    );

    test('a wrong pick is ruled out and counted, the round stays', () async {
      final cubit = build();
      final round = cubit.state.round;
      final wrong = round.options.firstWhere((o) => o.id != round.target.id);

      await cubit.pick(wrong);
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.eliminated, {wrong.id});
      expect(cubit.state.index, 0);
      expect(cubit.state.feedback, GameFeedback.wrong);

      // Tapping the same wrong card again must not count twice.
      await cubit.pick(wrong);
      expect(cubit.state.mistakes, 1);
      await cubit.close();
    });

    test('the right pick moves to a clean next round', () async {
      final cubit = build();
      await cubit.pick(cubit.state.round.target);
      expect(cubit.state.index, 1);
      expect(cubit.state.solved, isFalse);
      expect(cubit.state.eliminated, isEmpty);
      await cubit.close();
    });

    test('a perfect game finishes with 3 stars', () async {
      final cubit = build();
      while (!cubit.state.finished) {
        await cubit.pick(cubit.state.round.target);
      }
      expect(cubit.state.stars, 3);
      expect(cubit.state.feedback, GameFeedback.finished);
      await cubit.close();
    });

    test('mistakes lower the stars but never below 1', () async {
      final cubit = build();
      while (!cubit.state.finished) {
        final round = cubit.state.round;
        for (final option in round.options) {
          if (option.id != round.target.id) await cubit.pick(option);
        }
        await cubit.pick(round.target);
      }
      expect(cubit.state.stars, 1);
      await cubit.close();
    });
  });

  group('MemoryCubit', () {
    MemoryCubit build() => MemoryCubit(
      bundle: makeBundle(GameType.memory, items: 3),
      random: Random(2),
      showMismatchFor: Duration.zero,
      celebrateFor: Duration.zero,
    );

    /// Card indices grouped by the item they show.
    Map<String, List<int>> pairsOf(MemoryCubit cubit) {
      final pairs = <String, List<int>>{};
      for (final card in cubit.state.cards) {
        pairs.putIfAbsent(card.item.id, () => []).add(card.index);
      }
      return pairs;
    }

    test('two matching cards stay face up', () async {
      final cubit = build();
      final pair = pairsOf(cubit).values.first;
      await cubit.flip(pair[0]);
      expect(cubit.state.faceUp, [pair[0]]);
      await cubit.flip(pair[1]);
      expect(cubit.state.matched, {pair[0], pair[1]});
      expect(cubit.state.mistakes, 0);
      await cubit.close();
    });

    test('two different cards flip back and count one mistake', () async {
      final cubit = build();
      final pairs = pairsOf(cubit).values.toList();
      await cubit.flip(pairs[0][0]);
      await cubit.flip(pairs[1][0]);
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.faceUp, isEmpty);
      expect(cubit.state.matched, isEmpty);
      expect(cubit.state.busy, isFalse);
      await cubit.close();
    });

    test('flipping a face-up card again does nothing', () async {
      final cubit = build();
      await cubit.flip(0);
      await cubit.flip(0);
      expect(cubit.state.faceUp, [0]);
      await cubit.close();
    });

    test('finding every pair finishes with 3 stars', () async {
      final cubit = build();
      for (final pair in pairsOf(cubit).values) {
        await cubit.flip(pair[0]);
        await cubit.flip(pair[1]);
      }
      expect(cubit.state.finished, isTrue);
      expect(cubit.state.stars, 3);
      await cubit.close();
    });
  });

  group('MatchCubit', () {
    MatchCubit build() => MatchCubit(
      bundle: makeBundle(GameType.match, items: 5),
      random: Random(3),
      celebrateFor: Duration.zero,
    );

    test('a wrong drop counts a mistake and marks the target', () async {
      final cubit = build();
      final round = cubit.state.round;
      await cubit.drop(
        sourceId: round.sources[0].id,
        targetId: round.sources[1].id,
      );
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.wrongTargetId, round.sources[1].id);
      expect(cubit.state.wrongTick, 1);
      expect(cubit.state.matched, isEmpty);
      await cubit.close();
    });

    test('matching every piece walks through all rounds', () async {
      final cubit = build();
      expect(cubit.state.totalPieces, 5);
      var guard = 0;
      while (!cubit.state.finished && guard++ < 10) {
        for (final item in [...cubit.state.round.sources]) {
          await cubit.drop(sourceId: item.id, targetId: item.id);
        }
      }
      expect(cubit.state.finished, isTrue);
      expect(cubit.state.stars, 3);
      await cubit.close();
    });
  });
}
