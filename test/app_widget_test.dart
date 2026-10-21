import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/call/guide_tool_handler.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/voice_session/domain/voice_session_service.dart';

import 'support/fakes.dart';

/// Typical Android phone, animations off (the voice orb animates forever otherwise).
Future<void> pumpApp(WidgetTester tester, TestApp app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(find.text(text).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> startGuide(
  WidgetTester tester,
  String app, {
  bool newUser = false,
}) async {
  await tapText(tester, app);
  await tapText(tester, newUser ? "No, I'm new" : 'Yes');
}

Future<void> done(WidgetTester tester, [int times = 1]) async {
  for (var i = 0; i < times; i++) {
    await tapText(tester, 'Done');
  }
}

void main() {
  testWidgets('opening the app starts the call straight away', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    expect(app.voice.starts, 1);
    expect(app.voice.lastContext!.keys, ['saathi_device']);
    expect(find.text('Listening'), findsOneWidget);
    expect(find.byTooltip('End call'), findsOneWidget);
    expect(find.text('Book a ride'), findsOneWidget);
  });

  testWidgets('the screen follows the voice agent with no taps', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = GuideToolHandler(
      guide: app.services.guide,
      settings: app.services.settings,
    );

    // User: "I use Ola, I already have it" -> agent calls start_guide.
    var answer = await agent.handle({
      'action': 'start_guide',
      'app': 'ola',
      'new_user': false,
    });
    await tester.pumpAndSettle();
    expect(answer['step_id'], 'open_app');
    expect(find.text('Open Ola'), findsOneWidget);
    expect(find.text('Ola · Step 1 of 9'), findsOneWidget);

    // User: "done" -> agent calls step_done for the current step.
    answer = await agent.handle({'action': 'step_done', 'step_id': 'open_app'});
    await tester.pumpAndSettle();
    expect(answer['step_id'], 'find_locations');
    expect(find.text('Ola · Step 2 of 9'), findsOneWidget);

    // A stale or skipping request is refused and the screen stays put.
    answer = await agent.handle({
      'action': 'step_done',
      'step_id': 'check_fare',
    });
    await tester.pumpAndSettle();
    expect(answer['ok'], isFalse);
    expect(answer['step_id'], 'find_locations');
    expect(find.text('Ola · Step 2 of 9'), findsOneWidget);
  });

  testWidgets('voice-reported booking shows the finish screen', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = GuideToolHandler(
      guide: app.services.guide,
      settings: app.services.settings,
    );
    await agent.handle({'action': 'start_guide', 'app': 'rapido'});
    final ids = app.services.guide.definition!.steps.map((s) => s.id);
    for (final id in ids.take(ids.length - 1)) {
      await agent.handle({'action': 'step_done', 'step_id': id});
    }
    // "outcome" before the final step would be refused; here we are on it.
    final answer = await agent.handle({
      'action': 'outcome',
      'step_id': 'confirm_outcome',
      'booked': true,
    });
    await tester.pumpAndSettle();
    expect(answer['finished'], isTrue);
    expect(find.text('Well done'), findsOneWidget);
    expect(app.store.stored!.status, SessionStatus.completed);
  });

  testWidgets('taps still work: pick app, answer once, Done and Back', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await tapText(tester, 'Ola');
    expect(find.text('Already using Ola?'), findsOneWidget);
    await tapText(tester, 'Yes');
    expect(find.text('Open Ola'), findsOneWidget);
    expect(find.text('Repeat'), findsNothing);
    expect(find.text('I need help'), findsNothing);
    expect(find.byTooltip('End call'), findsOneWidget, reason: 'call stays');

    await done(tester);
    expect(find.text('Ola · Step 2 of 9'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open Ola'), findsOneWidget);
    expect(app.store.stored!.confirmedAt('open_app'), isNotNull);
  });

  testWidgets('booked is only claimed after the user says so', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await startGuide(tester, 'Ola');
    await done(tester, 8);
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(app.store.stored!.status, SessionStatus.active);
    await tapText(tester, "No, I didn't book");
    expect(find.text('No problem'), findsOneWidget);
    expect(find.text('Well done'), findsNothing);
    await tapText(tester, 'New ride');
    expect(find.text('Book a ride'), findsOneWidget);
  });

  testWidgets('new users start at install and the OTP step warns', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await startGuide(tester, 'Uber', newUser: true);
    expect(find.text('Install Uber'), findsOneWidget);
    expect(find.text('Uber · Step 1 of 14'), findsOneWidget);
    expect(find.text('Picture coming soon'), findsOneWidget);
    await done(tester, 4); // install, open, location, phone
    expect(find.text('Enter the code you receive'), findsOneWidget);
    expect(find.textContaining('Saathi will never ask for it'), findsOneWidget);
  });

  testWidgets('failed save keeps the step and explains', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await startGuide(tester, 'Ola');
    app.store.failNextSave = true;
    await done(tester);
    expect(find.text('Open Ola'), findsOneWidget);
    expect(find.textContaining("Couldn't save your progress"), findsOneWidget);
  });

  group('previous guide', () {
    Future<TestApp> withSavedGuide(WidgetTester tester) async {
      final first = await TestApp.create();
      await pumpApp(tester, first);
      await startGuide(tester, 'Ola');
      await done(tester, 2);
      await tester.pumpWidget(const SizedBox());
      final second = await TestApp.create(store: first.store);
      await pumpApp(tester, second);
      return second;
    }

    testWidgets('asks before continuing; the call is not told about it', (
      tester,
    ) async {
      final app = await withSavedGuide(tester);
      expect(find.text('Continue where you left off?'), findsOneWidget);
      expect(find.textContaining('Ola · Step 3 of 9'), findsOneWidget);
      expect(app.voice.lastContext!.keys, ['saathi_device']);
      await tapText(tester, 'Continue');
      expect(find.text('Ola · Step 3 of 9'), findsOneWidget);
    });

    testWidgets('"Start a new one" goes back to the app list', (tester) async {
      await withSavedGuide(tester);
      await tapText(tester, 'Start a new one');
      expect(find.text('Book a ride'), findsOneWidget);
    });
  });

  group('call bar', () {
    testWidgets('mic denied offers to allow it', (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      app.voice.emit(
        const VoiceStatus(
          VoicePhase.failed,
          failure: VoiceFailure.microphoneDenied,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Couldn't start the call"), findsOneWidget);
      await tapText(tester, 'Allow microphone');
      expect(app.android.settingsOpened, 1);
    });

    testWidgets('after the call ends, one tap calls again', (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await tester.tap(find.byTooltip('End call'));
      await tester.pumpAndSettle();
      expect(find.text('Call ended'), findsOneWidget);
      await tapText(tester, 'Call again');
      expect(app.voice.starts, 2);
    });

    testWidgets('mute toggles', (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await tester.tap(find.byTooltip('Mute'));
      await tester.pumpAndSettle();
      expect(app.voice.muted, isTrue);
      expect(find.text('Microphone paused'), findsOneWidget);
    });
  });

  testWidgets('language switch updates the screen', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await tapText(tester, 'मराठी');
    expect(find.text('राइड बुक करा'), findsOneWidget);
    expect(app.services.settings.language, 'mr');
  });

  testWidgets('Marathi at 2x text on a small phone has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280); // 360x640 @2x
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final app = await TestApp.create(language: 'mr');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tapText(tester, 'Ola');
    await tapText(tester, 'हो');
    for (var i = 0; i < 6; i++) {
      await tapText(tester, 'झाले');
    }
    expect(find.text('खात्री असेल तरच बुक करा'), findsOneWidget);
  });
}
