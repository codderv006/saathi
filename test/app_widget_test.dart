import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/data/ride_workflow.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/voice_session/domain/voice_session_service.dart';

import 'support/fakes.dart';

/// Typical Android phone: 360 x 780 logical pixels.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> pumpApp(WidgetTester tester, TestApp app) async {
  usePhoneScreen(tester);
  await tester.pumpWidget(app.widget);
  await tester.pumpAndSettle();
}

Future<void> openRideGuide(
  WidgetTester tester,
  RideApp rideApp, {
  bool fromInstall = false,
}) async {
  await tapText(tester, 'Book a ride');
  await tapText(tester, rideApp.displayName);
  await tapText(
    tester,
    fromInstall ? 'No, help me install it' : "Yes, I'm already signed in",
  );
}

/// For screens with continuous animation (live voice orb): fixed pumps, no settle.
Future<void> tapLive(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pump();
  await tester.tap(find.text(text).last);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    // Lazily-built lists only create what is near the viewport.
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

void main() {
  testWidgets('onboarding: language switch updates UI, then home', (
    tester,
  ) async {
    final app = await TestApp.create(onboarded: false);
    await pumpApp(tester, app);
    expect(find.text('Your companion for everyday apps.'), findsOneWidget);

    await tapText(tester, 'मराठी');
    expect(find.text('रोजच्या ॲप्ससाठी तुमचा सोबती.'), findsOneWidget);
    expect(app.services.settings.language, 'mr');

    await tapText(tester, 'सुरू करा');
    expect(find.text('तुम्हाला कशासाठी मदत हवी आहे?'), findsOneWidget);
    expect(app.android.settingsOpened, 0, reason: 'no permission prompts');
  });

  testWidgets('home shows the voice card first and only the ride guide', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    expect(find.text('What would you like help with?'), findsOneWidget);
    expect(find.text('Talk to Saathi'), findsOneWidget);
    expect(find.text('Start talking'), findsOneWidget);
    expect(find.text('Book a ride'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('Google Pay'), findsNothing);
  });

  testWidgets(
    'picking Uber starts the Uber guide at step 1 with a placeholder',
    (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await openRideGuide(tester, RideApp.uber);

      expect(find.text('Open Uber'), findsOneWidget);
      expect(find.text('Step 1 of 9'), findsOneWidget);
      expect(
        app.store.stored!.workflowId,
        RideApp.uber.workflowId(fromInstall: false),
      );
    },
  );

  testWidgets(
    'fresh install path starts at the Play Store and guards the OTP',
    (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await openRideGuide(tester, RideApp.rapido, fromInstall: true);
      expect(find.text('Install Rapido'), findsOneWidget);
      expect(find.text('Step 1 of 12'), findsOneWidget);
      // No Play Store recording yet: labelled placeholder.
      expect(find.text('Picture coming soon'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tapText(tester, "I've done this");
      }
      expect(find.text('Enter the code you receive'), findsOneWidget);
      expect(
        find.textContaining('Saathi will never ask for it'),
        findsOneWidget,
      );
      expect(find.textContaining('involves money'), findsNothing);
    },
  );

  testWidgets('full Ola guide: confirm, repeat, help, back, outcome', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.ola);

    await tapText(tester, "I've done this");
    expect(find.text('Find where to enter your destination'), findsOneWidget);
    expect(find.text('Step 2 of 9'), findsOneWidget);

    // Repeat and help never advance.
    await tapText(tester, 'Repeat');
    expect(find.text('Step 2 of 9'), findsOneWidget);
    await tapText(tester, 'I need help');
    await tapText(tester, 'Explain it more simply');
    expect(find.text('In simple words'), findsOneWidget);
    expect(find.text('Step 2 of 9'), findsOneWidget);

    // Back keeps the earlier confirmation in history.
    await tapText(tester, 'Back');
    expect(find.text('Open Ola'), findsOneWidget);
    expect(app.store.stored!.confirmedAt('open_app'), isNotNull);

    for (var i = 0; i < 8; i++) {
      await tapText(tester, "I've done this");
    }
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.text("I've done this"), findsNothing);
    expect(
      app.store.stored!.status,
      SessionStatus.active,
      reason: 'reaching the last step is not success',
    );

    await tapText(tester, 'Yes, my ride is booked');
    expect(find.text('Well done'), findsOneWidget);
    expect(find.textContaining('You told Saathi that Ola'), findsOneWidget);
    expect(app.store.stored!.status, SessionStatus.completed);

    await tapText(tester, 'Done');
    expect(find.text('Book a ride'), findsOneWidget, reason: 'not resumable');
  });

  testWidgets('saying no at the outcome step never claims success', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.rapido);
    for (var i = 0; i < 7; i++) {
      await tapText(tester, "I've done this");
    }
    await tapText(tester, "No, I didn't book");
    expect(find.text('No problem'), findsOneWidget);
    expect(find.text('Well done'), findsNothing);
    expect(app.store.stored!.outcome, Outcome.notCompleted);
  });

  testWidgets('failed save keeps the step and explains', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.ola);
    app.store.failNextSave = true;
    await tapText(tester, "I've done this");
    expect(find.text('Open Ola'), findsOneWidget);
    expect(find.textContaining("Couldn't save your progress"), findsOneWidget);
  });

  testWidgets('stop for now pauses; home offers to continue at the same step', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.ola);
    await tapText(tester, "I've done this");
    await tester.tap(find.byTooltip('Exit guide'));
    await tester.pumpAndSettle();

    expect(app.store.stored!.status, SessionStatus.paused);
    expect(find.text('In progress: Ola · Step 2 of 9'), findsOneWidget);

    // Never resumes silently: the user is asked.
    await tapText(tester, 'Book a ride');
    expect(find.text('Continue where you left off?'), findsOneWidget);
    await tapText(tester, 'Continue');
    expect(find.text('Find where to enter your destination'), findsOneWidget);
    expect(app.store.stored!.status, SessionStatus.active);
  });

  testWidgets('choosing "Start a new one" begins a fresh guide', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.ola);
    await tapText(tester, "I've done this");
    final oldId = app.store.stored!.id;
    await tester.tap(find.byTooltip('Exit guide'));
    await tester.pumpAndSettle();

    await tapText(tester, 'Book a ride');
    await tapText(tester, 'Start a new one');
    await tapText(tester, 'Uber');
    await tapText(tester, "Yes, I'm already signed in");
    expect(find.text('Open Uber'), findsOneWidget);
    expect(find.text('Step 1 of 9'), findsOneWidget);
    expect(app.store.stored!.id, isNot(oldId));
  });

  testWidgets('a call from Home does not assume a paused guide', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await openRideGuide(tester, RideApp.ola);
    await tester.tap(find.byTooltip('Exit guide'));
    await tester.pumpAndSettle();
    await tapLive(tester, 'Start talking');
    expect(app.voice.starts, 1);
    expect(app.voice.lastContext, isEmpty);
  });

  testWidgets('progress survives an app restart', (tester) async {
    final first = await TestApp.create();
    await pumpApp(tester, first);
    await openRideGuide(tester, RideApp.ola);
    await tapText(tester, "I've done this");
    await tapText(tester, "I've done this");

    final second = await TestApp.create(store: first.store);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, second);
    expect(find.text('In progress: Ola · Step 3 of 9'), findsOneWidget);
  });

  group('voice', () {
    testWidgets('mic rationale is shown before the first call', (tester) async {
      final app = await TestApp.create();
      app.android.micGranted = false;
      await pumpApp(tester, app);
      await tapText(tester, 'Start talking');
      expect(find.text('Saathi needs your microphone'), findsOneWidget);
      await tapText(tester, 'Not now');
      expect(app.voice.starts, 0);
    });

    testWidgets('call passes the current step as context and shows status', (
      tester,
    ) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await openRideGuide(tester, RideApp.ola);
      await tester.tap(find.text('Talk to Saathi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(app.voice.starts, 1);
      expect(app.voice.lastContext!['saathi_task'], 'Book a ride with Ola');
      expect(app.voice.lastContext!['saathi_step'], contains('Open Ola'));
      expect(find.text('Listening'), findsWidgets);
      expect(find.text('Back to your guide'), findsOneWidget);

      app.voice.emit(const VoiceStatus(VoicePhase.speaking));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Saathi is speaking'), findsWidgets);

      await tester.tap(find.text('End call'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Call ended'), findsOneWidget);
      expect(find.text('Talk again'), findsOneWidget);
    });

    testWidgets('microphone denied explains and offers settings', (
      tester,
    ) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await tapLive(tester, 'Start talking');
      app.voice.emit(
        const VoiceStatus(
          VoicePhase.failed,
          failure: VoiceFailure.microphoneDenied,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Couldn't start the call"), findsOneWidget);
      expect(find.textContaining('needs the microphone'), findsOneWidget);
      await tapText(tester, 'Open settings');
      expect(app.android.settingsOpened, 1);
    });

    testWidgets('dropped connection says progress is saved', (tester) async {
      final app = await TestApp.create();
      await pumpApp(tester, app);
      await tapLive(tester, 'Start talking');
      app.voice.emit(const VoiceStatus(VoicePhase.disconnected));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('The voice call ended'), findsOneWidget);
      expect(find.textContaining('progress is saved'), findsOneWidget);
    });
  });

  testWidgets('Marathi at 2x text on a small phone has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280); // 360x640 @2x
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final app = await TestApp.create(language: 'mr');
    await tester.pumpWidget(app.widget);
    await tester.pumpAndSettle();
    await tapText(tester, 'राइड बुक करा');
    await tapText(tester, 'Ola');
    await tapText(tester, 'हो, मी आधीच साइन इन केले आहे');
    // Walk to the longest (sensitive) step.
    for (var i = 0; i < 6; i++) {
      await tapText(tester, 'मी हे केले');
    }
    expect(find.text('खात्री असेल तरच बुक करा'), findsOneWidget);
    // Any overflow during the walk fails the test via the framework's own reporter.
  });
}
