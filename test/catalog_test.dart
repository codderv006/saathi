import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/data/guide_catalog.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';

void main() {
  final catalog = GuideCatalog.parse(
    File('assets/guides/catalog.json').readAsStringSync(),
  );

  test('covers the six supported apps in three categories', () {
    expect(catalog.apps.keys.toSet(), {
      'ola',
      'uber',
      'rapido',
      'gpay',
      'phonepe',
      'whatsapp',
    });
    expect(catalog.categories.keys.toSet(), {'commute', 'payments', 'social'});
    for (final app in catalog.apps.keys) {
      expect(
        catalog.topicsFor(app).length,
        greaterThanOrEqualTo(8),
        reason: app,
      );
    }
  });

  test('requested topics exist', () {
    for (final (app, topic) in [
      ('ola', 'book_ride'),
      ('uber', 'cancel_ride'),
      ('rapido', 'vehicle_number'),
      ('ola', 'contact_driver'),
      ('uber', 'check_fare'),
      ('rapido', 'driver_eta'),
      ('ola', 'ride_otp'),
      ('gpay', 'pay_phone'),
      ('phonepe', 'scan_qr'),
      ('gpay', 'setup_upi'),
      ('phonepe', 'add_card'),
      ('whatsapp', 'send_message'),
      ('whatsapp', 'keyboard_language'),
      ('whatsapp', 'contact_name'),
      ('whatsapp', 'profile_photo'),
      ('whatsapp', 'post_status'),
      ('whatsapp', 'communities'),
      ('whatsapp', 'join_community'),
    ]) {
      expect(
        catalog.definitionFor(app, topic),
        isNotNull,
        reason: '$app.$topic',
      );
    }
  });

  test(
    'every step is bilingual, illustrated and has its app name filled in',
    () {
      for (final def in catalog.definitions) {
        expect(def.steps, isNotEmpty, reason: def.id);
        expect(
          def.steps.map((s) => s.id).toSet().length,
          def.steps.length,
          reason: '${def.id}: unique step ids',
        );
        for (final s in def.steps) {
          for (final lang in ['en', 'mr']) {
            expect(s.title.of(lang), isNotEmpty, reason: '${def.id}/${s.id}');
            expect(
              s.instruction.of(lang),
              isNotEmpty,
              reason: '${def.id}/${s.id}',
            );
            expect(s.instruction.of(lang), isNot(contains('{app}')));
          }
          expect(
            s.visual,
            isNotNull,
            reason: '${def.id}/${s.id} needs a visual',
          );
        }
      }
    },
  );

  test('PIN, OTP and card-number steps are marked secret', () {
    for (final def in catalog.definitions) {
      for (final s in def.steps) {
        final text = s.instruction.of('en').toLowerCase();
        if (text.contains('upi pin') && text.contains('type your upi pin')) {
          expect(
            s.sensitivity,
            Sensitivity.secretCode,
            reason: '${def.id}/${s.id}',
          );
        }
      }
    }
    final card = catalog.definitionFor('gpay', 'add_card')!;
    expect(card.stepById('card_otp')!.sensitivity, Sensitivity.secretCode);
  });

  test('ride booking uses the recorded guides with screenshots', () {
    final ride = catalog.definitionFor('ola', 'book_ride', newUser: true)!;
    expect(ride.steps.first.id, 'install_app');
    expect(ride.steps.every((s) => s.visual != null), isTrue);
    expect(ride.app, 'ola');
    expect(ride.topic, 'book_ride');
  });
}
