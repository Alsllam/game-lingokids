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
