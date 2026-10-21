import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/presentation/screenshot_guide.dart';
import 'package:saathi_poc/l10n/app_localizations.dart';

void main() {
  group('annotation geometry', () {
    test('tall image is fitted by height, aspect preserved', () {
      final size = fittedImageSize(
        const Size(1080, 2400),
        const Size(400, 444),
      );
      expect(size.height, closeTo(444, 0.01));
      expect(size.width / size.height, closeTo(1080 / 2400, 0.001));
    });

    test('normalized rect maps onto the displayed image', () {
      const r = NormalizedRect(0.1, 0.3, 0.8, 0.08);
      final rect = annotationRect(r, const Size(200, 444));
      expect(rect.left, closeTo(20, 0.01));
      expect(rect.top, closeTo(133.2, 0.01));
      expect(rect.width, closeTo(160, 0.01));
      expect(rect.height, closeTo(35.52, 0.01));
    });

    test('same fractions land on the same image feature at any size', () {
      const r = NormalizedRect(0.25, 0.5, 0.5, 0.1);
      for (final box in const [Size(320, 500), Size(411, 700)]) {
        final shown = fittedImageSize(const Size(1080, 2400), box);
        final rect = annotationRect(r, shown);
        expect(rect.center.dx / shown.width, closeTo(0.5, 1e-9));
        expect(rect.center.dy / shown.height, closeTo(0.55, 1e-9));
      }
    });
  });

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  const shot = StepScreenshot(
    asset: 'assets/workflows/ola/does_not_exist.png',
    description: LocalizedText(en: 'Test screen', mr: 'चाचणी स्क्रीन'),
    annotations: [
      ScreenshotAnnotation(
        highlight: NormalizedRect(0.1, 0.2, 0.5, 0.1),
        marker: 1,
        label: LocalizedText(en: 'Tap here', mr: 'इथे दाबा'),
      ),
    ],
  );

  testWidgets('missing asset shows a labelled placeholder, not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const ScreenshotGuide(screenshot: shot, language: 'en')),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Picture coming soon'), findsOneWidget);
    expect(find.text('does_not_exist.png'), findsOneWidget);
    expect(find.text('Tap here'), findsNothing);
  });

  testWidgets('real image renders with marker and label on top', (
    tester,
  ) async {
    late final ui.Image image;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 90, 200),
        Paint()..color = const Color(0xFF888888),
      );
      image = await recorder.endRecording().toImage(90, 200);
    });
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.pumpWidget(
      host(
        ScreenshotGuide(
          screenshot: shot,
          language: 'en',
          maxHeight: 400,
          imageOverride: MemoryImage(bytes!.buffer.asUint8List()),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tap here'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Picture coming soon'), findsNothing);
    expect(find.bySemanticsLabel('Screenshot: Test screen'), findsOneWidget);
  });
}
