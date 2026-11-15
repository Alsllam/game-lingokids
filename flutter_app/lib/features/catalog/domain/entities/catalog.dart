import 'package:equatable/equatable.dart';

import '../../../../core/domain/localized_text.dart';
import '../../../../core/domain/item_visual.dart';

/// A point of a tracing path, in a box from (0,0) top-left to (1,1)
/// bottom-right.
final class TracePoint extends Equatable {
  const TracePoint(this.x, this.y);

  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

/// One pen stroke of a letter: the points the line passes through, in the
/// order it is written. A stroke with a single point is a dot to tap.
final class TraceStroke extends Equatable {
  const TraceStroke(this.points);

  final List<TracePoint> points;

  @override
  List<Object?> get props => [points];
}

/// One thing a child learns: a letter, a number, a colour, an animal...
final class LearningItem extends Equatable {
  const LearningItem({
    required this.id,
    required this.name,
    required this.visual,
    this.pair,
    this.traces = const {},
  });

  final String id;

  /// Spoken and written name.
  final LocalizedText name;

  /// The main picture.
  final ItemVisual visual;

  /// What this item is matched with in the matching game (letter -> picture,
  /// digit -> dots). When null the written [name] is used.
  final ItemVisual? pair;

  /// How to write this item, per language code ('ar', 'en'). Only items
  /// used by the tracing game need it.
  final Map<String, List<TraceStroke>> traces;

  List<TraceStroke> tracesFor(String languageCode) =>
      traces[languageCode] ?? const [];

  ItemVisual get pairOrLabel =>
      pair ?? ItemVisual(kind: VisualKind.label, value: name);

  @override
  List<Object?> get props => [id, name, visual, pair, traces];
}

/// The reusable game templates. Add a value here when adding a template.
enum GameType { choice, memory, match, trace }

/// A playable activity: a template plus the content it is filled with.
final class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.topicId,
    required this.type,
    required this.itemIds,
    required this.rounds,
    this.title,
  });

  final String id;
  final String topicId;
  final GameType type;

  /// Items used by this activity. Empty means "all items of the topic".
  final List<String> itemIds;

  /// Number of rounds for round-based templates.
  final int rounds;

  /// Optional custom title; the template name is used when null.
  final LocalizedText? title;

  @override
  List<Object?> get props => [id, topicId, type, itemIds, rounds, title];
}

/// A world on the home screen, e.g. "Animals".
final class Topic extends Equatable {
  const Topic({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    required this.activities,
  });

  final String id;
  final LocalizedText title;

  /// ARGB theme colour of the topic card.
  final int color;
  final ItemVisual icon;
  final List<LearningItem> items;
  final List<Activity> activities;

  @override
  List<Object?> get props => [id, title, color, icon, items, activities];
}

final class Catalog extends Equatable {
  const Catalog({required this.topics});

  final List<Topic> topics;

  Topic? topicById(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  int get activityCount =>
      topics.fold(0, (sum, topic) => sum + topic.activities.length);

  @override
  List<Object?> get props => [topics];
}

/// Everything a game needs to start: the activity and its resolved items.
final class ActivityBundle extends Equatable {
  const ActivityBundle({
    required this.topic,
    required this.activity,
    required this.items,
  });

  final Topic topic;
  final Activity activity;
  final List<LearningItem> items;

  @override
  List<Object?> get props => [topic, activity, items];
}
