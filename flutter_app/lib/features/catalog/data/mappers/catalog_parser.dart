import '../../../../core/domain/localized_text.dart';
import '../../domain/entities/catalog.dart';
import '../../../../core/domain/item_visual.dart';

/// Turns the decoded `catalog.json` into domain entities.
///
/// All null-handling and defaults live here. Anything malformed throws a
/// [FormatException] that names the broken field, so content mistakes are
/// easy to find.
abstract final class CatalogParser {
  static Catalog parse(Object? json) {
    final root = _map(json, 'root');
    final topics = _list(root['topics'], 'topics')
        .map((raw) => _topic(_map(raw, 'topic')))
        .toList(growable: false);
    if (topics.isEmpty) {
      throw const FormatException('catalog has no topics');
    }
    return Catalog(topics: topics);
  }

  static Topic _topic(Map<String, Object?> json) {
    final id = _string(json['id'], 'topic.id');
    final items = _list(json['items'], '$id.items')
        .map((raw) => _item(_map(raw, '$id.item')))
        .toList(growable: false);
    final knownIds = items.map((item) => item.id).toSet();
    final activities = _list(json['activities'], '$id.activities')
        .map((raw) => _activity(_map(raw, '$id.activity'), id, knownIds))
        .toList(growable: false);
    _checkTraceActivities(id, items, activities);
    return Topic(
      id: id,
      title: _text(json['title'], '$id.title'),
      color: parseColor(_string(json['color'], '$id.color')),
      icon: _visual(_map(json['icon'], '$id.icon'), '$id.icon'),
      items: items,
      activities: activities,
    );
  }

  static LearningItem _item(Map<String, Object?> json) {
    final id = _string(json['id'], 'item.id');
    final pair = json['pair'];
    final trace = json['trace'];
    return LearningItem(
      id: id,
      name: _text(json['name'], '$id.name'),
      visual: _visual(_map(json['visual'], '$id.visual'), '$id.visual'),
      pair: pair == null ? null : _visual(_map(pair, '$id.pair'), '$id.pair'),
      traces: trace == null ? const {} : _traces(trace, '$id.trace'),
    );
  }

  /// `{"en": [stroke, ...], "ar": [...]}` where a stroke is `[[x, y], ...]`.
  static Map<String, List<TraceStroke>> _traces(Object? json, String path) {
    final byLanguage = _map(json, path);
    return {
      for (final entry in byLanguage.entries)
        entry.key: _list(entry.value, '$path.${entry.key}')
            .map((stroke) => _stroke(stroke, '$path.${entry.key}'))
            .toList(growable: false),
    };
  }

  static TraceStroke _stroke(Object? json, String path) {
    final points = _list(json, path).map((raw) {
      final pair = _list(raw, path);
      if (pair.length != 2 || pair[0] is! num || pair[1] is! num) {
        throw FormatException('$path: a point must be [x, y]');
      }
      final x = (pair[0]! as num).toDouble();
      final y = (pair[1]! as num).toDouble();
      if (x < 0 || x > 1 || y < 0 || y > 1) {
        throw FormatException('$path: point [$x, $y] is outside 0..1');
      }
      return TracePoint(x, y);
    }).toList(growable: false);
    if (points.isEmpty) throw FormatException('$path: a stroke has no points');
    return TraceStroke(points);
  }

  /// A tracing game is only playable when each of its items says how it is
  /// written in every language of the app.
  static void _checkTraceActivities(
    String topicId,
    List<LearningItem> items,
    List<Activity> activities,
  ) {
    for (final activity in activities) {
      if (activity.type != GameType.trace) continue;
      final used = activity.itemIds.isEmpty
          ? items
          : items.where((item) => activity.itemIds.contains(item.id));
      for (final item in used) {
        for (final language in const ['ar', 'en']) {
          if (item.tracesFor(language).isEmpty) {
            throw FormatException(
              '${activity.id}: item "${item.id}" has no "$language" trace',
            );
          }
        }
      }
    }
  }

  static Activity _activity(
    Map<String, Object?> json,
    String topicId,
    Set<String> knownItemIds,
  ) {
    final id = _string(json['id'], 'activity.id');
    final typeName = _string(json['type'], '$id.type');
    final type = GameType.values.where((t) => t.name == typeName).firstOrNull;
    if (type == null) {
      throw FormatException('$id.type: unknown game type "$typeName"');
    }
    final rawItems = json['items'];
    final itemIds = rawItems == null
        ? const <String>[]
        : _list(rawItems, '$id.items')
              .map((raw) => _string(raw, '$id.items[]'))
              .toList(growable: false);
    for (final itemId in itemIds) {
      if (!knownItemIds.contains(itemId)) {
        throw FormatException('$id.items: unknown item "$itemId"');
      }
    }
    final rounds = json['rounds'];
    final title = json['title'];
    return Activity(
      id: id,
      topicId: topicId,
      type: type,
      itemIds: itemIds,
      rounds: rounds is int && rounds > 0 ? rounds : 5,
      title: title == null ? null : _text(title, '$id.title'),
    );
  }

  static ItemVisual _visual(Map<String, Object?> json, String path) {
    final kindName = _string(json['kind'], '$path.kind');
    final kind = VisualKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) {
      throw FormatException('$path.kind: unknown visual kind "$kindName"');
    }
    final color = json['color'];
    return ItemVisual(
      kind: kind,
      value: _text(json['value'], '$path.value'),
      color: color == null ? null : parseColor(_string(color, '$path.color')),
    );
  }

  /// Accepts either a plain string or `{"ar": "...", "en": "..."}`.
  static LocalizedText _text(Object? json, String path) {
    if (json is String) return LocalizedText.same(json);
    final map = _map(json, path);
    return LocalizedText(
      ar: _string(map['ar'], '$path.ar'),
      en: _string(map['en'], '$path.en'),
    );
  }

  /// Parses `#RRGGBB` or `#AARRGGBB` into an ARGB int.
  static int parseColor(String hex) {
    final digits = hex.replaceFirst('#', '');
    final value = int.tryParse(digits, radix: 16);
    if (value == null || (digits.length != 6 && digits.length != 8)) {
      throw FormatException('invalid colour "$hex"');
    }
    return digits.length == 6 ? 0xFF000000 | value : value;
  }

  static Map<String, Object?> _map(Object? value, String path) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('$path: expected an object');
  }

  static List<Object?> _list(Object? value, String path) {
    if (value is List<Object?>) return value;
    throw FormatException('$path: expected a list');
  }

  static String _string(Object? value, String path) {
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('$path: expected a non-empty string');
  }
}
