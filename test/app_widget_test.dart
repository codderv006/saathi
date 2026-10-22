import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/call/guide_tool_handler.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/presentation/app_illustration.dart';
import 'package:saathi_poc/features/voice_session/domain/voice_session_service.dart';

import 'support/fakes.dart';

/// Typical Android phone, animations off (orbs and illustrations loop forever).
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

GuideToolHandler agentFor(TestApp app) => GuideToolHandler(
  guide: app.services.guide,
  settings: app.services.settings,
  catalog: app.services.catalog,
);

Future<void> tapOrb(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Tap to get help. मदतीसाठी टॅप करा'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens on the mic with the invitation in both languages', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    expect(find.text('Tap to get help'), findsOneWidget);
    expect(find.text('मदतीसाठी टॅप करा'), findsOneWidget);
    expect(app.voice.starts, 0, reason: 'no call until the user taps');

    await tapOrb(tester);
    expect(app.voice.starts, 1);
    expect(app.voice.lastContext!.keys, ['saathi_device']);
    expect(find.text('Listening'), findsOneWidget);
    expect(find.text('Ask me anything about these apps'), findsOneWidget);
    expect(find.byTooltip('End call'), findsOneWidget);
  });

  testWidgets('agent opens a WhatsApp guide; screen follows with no taps', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = agentFor(app);

    var answer = await agent.handle({
      'action': 'show_topic',
      'app': 'whatsapp',
      'topic': 'post_status',
    });
    await tester.pumpAndSettle();
    expect(answer['step_id'], 'open_updates');
    expect(find.text('Open Updates'), findsOneWidget);
    // No screenshot for this step: an animated illustration is shown instead.
    expect(find.byType(AppIllustration), findsOneWidget);
    expect(find.text('Picture coming soon'), findsNothing);

    answer = await agent.handle({
      'action': 'step_done',
      'step_id': 'open_updates',
    });
    await tester.pumpAndSettle();
    expect(find.text('Add a photo or text'), findsOneWidget);
  });

  testWidgets('screen ahead of the agent: agent catches up, no skipping', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = agentFor(app);
    await agent.handle({
      'action': 'show_topic',
      'app': 'gpay',
      'topic': 'scan_qr',
    });
    await tester.pumpAndSettle();
    await tapText(tester, 'Done'); // user taps ahead of the agent

    // Agent still thinks the user is on the first step.
    final answer = await agent.handle({
      'action': 'step_done',
      'step_id': 'open_app',
    });
    expect(answer['ok'], isTrue);
    expect(answer['step_id'], 'tap_scan', reason: 'told where the screen is');
    expect(app.services.guide.currentStep!.id, 'tap_scan', reason: 'no skip');

    // A step the user has not reached yet is refused.
    final ahead = await agent.handle({
      'action': 'step_done',
      'step_id': 'enter_pin',
    });
    expect(ahead['ok'], isFalse);
    expect(app.services.guide.currentStep!.id, 'tap_scan');
  });

  testWidgets('finishing a guide shows "All done" then back to the mic', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = agentFor(app);
    await agent.handle({
      'action': 'show_topic',
      'app': 'whatsapp',
      'topic': 'communities',
    });
    for (final id in ['what_community', 'why_community', 'community_safety']) {
      await agent.handle({'action': 'step_done', 'step_id': id});
    }
    await tester.pumpAndSettle();
    expect(find.text('All done'), findsOneWidget);
    await tapText(tester, 'Ask something else');
    expect(find.text('Tap to get help'), findsOneWidget);
  });

  testWidgets('ride booking via voice: booked only from the user\'s answer', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = agentFor(app);
    await agent.handle({'action': 'start_guide', 'app': 'rapido'});
    final ids = app.services.guide.definition!.steps.map((s) => s.id).toList();
    expect(
      (await agent.handle({
        'action': 'outcome',
        'step_id': ids.first,
        'booked': true,
      }))['ok'],
      isFalse,
      reason: 'cannot claim booked early',
    );
    for (final id in ids.take(ids.length - 1)) {
      await agent.handle({'action': 'step_done', 'step_id': id});
    }
    await agent.handle({
      'action': 'outcome',
      'step_id': ids.last,
      'booked': true,
    });
    await tester.pumpAndSettle();
    expect(find.text('Well done'), findsOneWidget);
    expect(app.store.stored!.status, SessionStatus.completed);
  });

  testWidgets('close_topic returns to the mic; unknown topics are refused', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    final agent = agentFor(app);
    final unknown = await agent.handle({
      'action': 'show_topic',
      'app': 'instagram',
      'topic': 'post_reel',
    });
    expect(unknown['ok'], isFalse);
    await agent.handle({
      'action': 'show_topic',
      'app': 'phonepe',
      'topic': 'check_balance',
    });
    await tester.pumpAndSettle();
    expect(find.text('Open PhonePe'), findsOneWidget);
    await agent.handle({'action': 'close_topic'});
    await tester.pumpAndSettle();
    expect(find.text('Tap to get help'), findsOneWidget);
  });

  testWidgets('browse by tap: WhatsApp → Put a status', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await tapText(tester, 'Browse guides');
    await tapText(tester, 'WhatsApp');
    await tapText(tester, 'Put a status');
    expect(find.text('Open Updates'), findsOneWidget);
    await tapText(tester, 'Done');
    expect(find.text('Add a photo or text'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open Updates'), findsOneWidget);
  });

  testWidgets('browse: ride booking asks once, then shows the guide', (
    tester,
  ) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await tapText(tester, 'Browse guides');
    await tapText(tester, 'Uber');
    await tapText(tester, 'Book a ride');
    await tapText(tester, "No, I'm new");
    expect(find.text('Install Uber'), findsOneWidget);
    // No Play Store recording: illustration, not an empty placeholder.
    expect(find.text('Picture coming soon'), findsNothing);
  });

  testWidgets('a saved guide asks before continuing', (tester) async {
    final first = await TestApp.create();
    await pumpApp(tester, first);
    await agentFor(first).handle({
      'action': 'show_topic',
      'app': 'whatsapp',
      'topic': 'send_message',
    });
    await tester.pumpAndSettle();
    await tapText(tester, 'Done');
    await tester.pumpWidget(const SizedBox());
    final second = await TestApp.create(store: first.store);
    await pumpApp(tester, second);
    expect(find.text('Continue where you left off?'), findsOneWidget);
    await tapText(tester, 'Continue');
    expect(find.text('Start a chat'), findsOneWidget);
  });

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

  testWidgets('language switch keeps the bilingual invitation', (tester) async {
    final app = await TestApp.create();
    await pumpApp(tester, app);
    await tapText(tester, 'मराठी');
    expect(app.services.settings.language, 'mr');
    expect(find.text('Tap to get help'), findsOneWidget);
    expect(find.text('मदतीसाठी टॅप करा'), findsOneWidget);
    expect(find.text('मार्गदर्शक पाहा'), findsOneWidget);
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
    await agentFor(
      app,
    ).handle({'action': 'show_topic', 'app': 'gpay', 'topic': 'pay_phone'});
    await tester.pumpAndSettle();
    // open app, find person, check name, amount -> PIN step
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'झाले');
    }
    expect(find.text('तुमचा UPI PIN टाका'), findsOneWidget);
  });
}
