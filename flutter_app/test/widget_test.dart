import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nujoom/app/theme/app_theme.dart';
import 'package:nujoom/core/domain/localized_text.dart';
import 'package:nujoom/core/mascot/mascot.dart';
import 'package:nujoom/core/motion/confetti.dart';
import 'package:nujoom/core/widgets/item_visual_view.dart';
import 'package:nujoom/core/domain/item_visual.dart';

/// These tests draw the code-built visuals for real, so a broken painter or
/// animation fails here instead of showing up as a blank space on a phone.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.build(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('the mascot plays every mood without errors', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(host(MascotView(controller: controller)));

    for (final mood in MascotMood.values) {
      controller.play(mood);
      // Step through the whole animation frame by frame.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('every kind of item visual can be drawn', (tester) async {
    const visuals = [
      ItemVisual(kind: VisualKind.emoji, value: LocalizedText.same('🐱')),
      ItemVisual(kind: VisualKind.glyph, value: LocalizedText(ar: 'أ', en: 'A')),
      ItemVisual(kind: VisualKind.color, value: LocalizedText.same('#F44336')),
      ItemVisual(kind: VisualKind.label, value: LocalizedText.same('Cat')),
      ItemVisual(kind: VisualKind.dots, value: LocalizedText.same('5')),
      ItemVisual(kind: VisualKind.shape, value: LocalizedText.same('circle')),
      ItemVisual(kind: VisualKind.shape, value: LocalizedText.same('square')),
      ItemVisual(kind: VisualKind.shape, value: LocalizedText.same('triangle')),
      ItemVisual(kind: VisualKind.shape, value: LocalizedText.same('star')),
      ItemVisual(kind: VisualKind.shape, value: LocalizedText.same('heart')),
    ];
    await tester.pumpWidget(
      host(
        Wrap(
          children: [
            for (final visual in visuals)
              SizedBox.square(
                dimension: 80,
                child: ItemVisualView(visual: visual),
              ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ItemVisualView), findsNWidgets(visuals.length));
  });

  testWidgets('confetti runs to the end and stops', (tester) async {
    await tester.pumpWidget(host(const SizedBox.expand(child: ConfettiBurst())));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    // Nothing may still be animating once the burst is over.
    expect(tester.hasRunningAnimations, isFalse);
  });
}
