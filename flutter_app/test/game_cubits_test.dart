import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/core/domain/localized_text.dart';
import 'package:nujoom/features/catalog/domain/entities/catalog.dart';
import 'package:nujoom/core/domain/item_visual.dart';
import 'package:nujoom/features/games/presentation/cubit/choice_cubit.dart';
import 'package:nujoom/features/games/presentation/cubit/game_feedback.dart';
import 'package:nujoom/features/games/presentation/cubit/match_cubit.dart';
import 'package:nujoom/features/games/presentation/cubit/memory_cubit.dart';
import 'package:nujoom/features/games/presentation/cubit/trace_cubit.dart';

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

  group('TraceCubit', () {
    const enStroke = TraceStroke([TracePoint(0.2, 0.5), TracePoint(0.8, 0.5)]);
    const arStroke = TraceStroke([TracePoint(0.5, 0.2), TracePoint(0.5, 0.8)]);

    ActivityBundle traceBundle() {
      final base = makeBundle(GameType.trace, items: 3, rounds: 2);
      final items = [
        for (final item in base.items)
          LearningItem(
            id: item.id,
            name: item.name,
            visual: item.visual,
            traces: const {
              'en': [enStroke],
              'ar': [arStroke],
            },
          ),
      ];
      return ActivityBundle(
        topic: base.topic,
        activity: base.activity,
        items: items,
      );
    }

    TraceCubit build(String language) => TraceCubit(
      bundle: traceBundle(),
      languageCode: language,
      random: Random(4),
      celebrateFor: Duration.zero,
    );

    /// Drags a finger along every stroke of the current letter.
    Future<void> writeLetter(TraceCubit cubit) async {
      for (final path in [...cubit.state.paths]) {
        for (final point in path) {
          await cubit.touch(point.x, point.y);
        }
      }
    }

    test('uses the strokes of the chosen language', () async {
      final english = build('en');
      final arabic = build('ar');
      expect(english.state.paths.single.first, const TracePoint(0.2, 0.5));
      expect(arabic.state.paths.single.first, const TracePoint(0.5, 0.2));
      await english.close();
      await arabic.close();
    });

    test('plays as many letters as the activity has rounds', () async {
      final cubit = build('en');
      expect(cubit.state.items.length, 2);
      await cubit.close();
    });

    test('progress is reported while the finger moves', () async {
      final cubit = build('en');
      await cubit.touch(0.2, 0.5);
      await cubit.touch(0.3, 0.5);
      expect(cubit.state.reached > 0, isTrue);
      expect(cubit.state.stroke, 0);
      await cubit.close();
    });

    test('writing every letter finishes with 3 stars', () async {
      final cubit = build('en');
      await writeLetter(cubit);
      expect(cubit.state.index, 1);
      expect(cubit.state.reached, 0);
      expect(cubit.state.solved, isFalse);
      await writeLetter(cubit);
      expect(cubit.state.finished, isTrue);
      expect(cubit.state.stars, 3);
      expect(cubit.state.feedback, GameFeedback.finished);
      await cubit.close();
    });

    test('slips are kept across letters and reported as wrong', () async {
      final cubit = build('en');
      await cubit.touch(0.2, 0.5);
      await cubit.touch(0.3, 0.95);
      expect(cubit.state.slips, 1);
      expect(cubit.state.feedback, GameFeedback.wrong);
      await cubit.touch(0.2, 0.5);
      await writeLetter(cubit);
      expect(cubit.state.slips, 1);
      expect(cubit.state.index, 1);
      await cubit.close();
    });
  });
}
