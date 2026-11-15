import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/core/error/failure.dart';
import 'package:nujoom/features/catalog/data/mappers/catalog_parser.dart';
import 'package:nujoom/features/catalog/domain/entities/catalog.dart';
import 'package:nujoom/core/domain/item_visual.dart';
import 'package:nujoom/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nujoom/features/catalog/domain/usecases/get_activity_bundle.dart';
import 'package:dartz/dartz.dart';

final class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository(this.result);

  final Either<Failure, Catalog> result;

  @override
  Future<Either<Failure, Catalog>> getCatalog() async => result;
}

Map<String, Object?> minimalCatalog({String gameType = 'choice'}) => {
  'topics': [
    {
      'id': 't',
      'title': {'ar': 'ع', 'en': 'T'},
      'color': '#112233',
      'icon': {'kind': 'emoji', 'value': '⭐'},
      'items': [
        {
          'id': 'a',
          'name': {'ar': 'أ', 'en': 'A'},
          'visual': {'kind': 'glyph', 'value': 'A', 'color': '#FF0000'},
        },
        {
          'id': 'b',
          'name': 'B',
          'visual': {'kind': 'emoji', 'value': '🐱'},
          'pair': {'kind': 'dots', 'value': '2'},
        },
      ],
      'activities': [
        {'id': 'act', 'type': gameType, 'rounds': 4},
      ],
    },
  ],
};

void main() {
  group('the bundled catalog.json', () {
    late Catalog catalog;

    setUpAll(() {
      final raw = File('assets/content/catalog.json').readAsStringSync();
      catalog = CatalogParser.parse(jsonDecode(raw));
    });

    test('parses and has topics', () {
      expect(catalog.topics.isNotEmpty, isTrue);
    });

    test('has unique topic, item and activity ids', () {
      final topicIds = catalog.topics.map((topic) => topic.id).toList();
      expect(topicIds.toSet().length, topicIds.length);
      final activityIds = [
        for (final topic in catalog.topics)
          for (final activity in topic.activities) activity.id,
      ];
      expect(activityIds.toSet().length, activityIds.length);
      for (final topic in catalog.topics) {
        final itemIds = topic.items.map((item) => item.id).toList();
        expect(itemIds.toSet().length, itemIds.length);
      }
    });

    test('every activity can be started', () async {
      final useCase = GetActivityBundle(FakeCatalogRepository(Right(catalog)));
      for (final topic in catalog.topics) {
        for (final activity in topic.activities) {
          final result = await useCase(activity.id);
          expect(result.isRight(), isTrue);
        }
      }
    });

    test('every picture used by the content exists in assets/art', () {
      final visuals = [
        for (final topic in catalog.topics) ...[
          topic.icon,
          for (final item in topic.items) ...[item.visual, ?item.pair],
        ],
      ];
      final sprites = visuals.where((v) => v.kind == VisualKind.sprite);
      expect(sprites.isNotEmpty, isTrue);
      for (final sprite in sprites) {
        // A picture may differ per language (A-apple, but أ-أسد).
        for (final name in {sprite.value.en, sprite.value.ar}) {
          expect(File('assets/art/$name.png').existsSync(), isTrue);
        }
      }
    });

    test('every item has a name in both languages', () {
      for (final topic in catalog.topics) {
        for (final item in topic.items) {
          expect(item.name.ar.isNotEmpty, isTrue);
          expect(item.name.en.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('CatalogParser', () {
    test('reads colours, localized values and optional pairs', () {
      final topic = CatalogParser.parse(minimalCatalog()).topics.single;
      expect(topic.color, 0xFF112233);
      expect(topic.title.of('ar'), 'ع');
      expect(topic.items[0].visual.color, 0xFFFF0000);
      expect(topic.items[0].pair, isNull);
      expect(topic.items[0].pairOrLabel.kind, VisualKind.label);
      expect(topic.items[1].name.of('ar'), 'B');
      expect(topic.items[1].pair?.kind, VisualKind.dots);
      expect(topic.activities.single.rounds, 4);
      expect(topic.activities.single.topicId, 't');
    });

    test('rejects an unknown game type and names the activity', () {
      expect(
        () => CatalogParser.parse(minimalCatalog(gameType: 'racing')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('act.type'),
          ),
        ),
      );
    });

    test('rejects a catalog without topics', () {
      expect(
        () => CatalogParser.parse({'topics': <Object?>[]}),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses 6- and 8-digit colours and rejects bad ones', () {
      expect(CatalogParser.parseColor('#3D8BFF'), 0xFF3D8BFF);
      expect(CatalogParser.parseColor('#803D8BFF'), 0x803D8BFF);
      expect(
        () => CatalogParser.parseColor('blue'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('GetActivityBundle', () {
    test('returns NotFoundFailure for an unknown id', () async {
      final catalog = CatalogParser.parse(minimalCatalog());
      final useCase = GetActivityBundle(FakeCatalogRepository(Right(catalog)));
      final result = await useCase('missing');
      expect(result.fold((failure) => failure, (_) => null), isA<NotFoundFailure>());
    });

    test('passes repository failures through', () async {
      final useCase = GetActivityBundle(
        FakeCatalogRepository(const Left(ContentFailure('broken'))),
      );
      final result = await useCase('act');
      expect(result.fold((failure) => failure, (_) => null), isA<ContentFailure>());
    });
  });
}
