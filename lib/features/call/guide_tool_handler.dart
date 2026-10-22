import '../../core/services/settings_controller.dart';
import '../guided_workflow/data/guide_catalog.dart';
import '../guided_workflow/domain/workflow.dart';
import '../guided_workflow/domain/workflow_controller.dart';
import '../guided_workflow/domain/workflow_engine.dart';

/// Applies guide actions requested by the voice agent (Bolna custom function
/// `saathi_guide`) and returns what the agent should know next.
///
/// The agent only relays what the user said ("how do I scan a QR in PhonePe",
/// "done", "go back", "it's booked"). Every action goes through the workflow
/// engine: steps can't be skipped, and a ride can only be reported booked on the
/// final question.
class GuideToolHandler {
  GuideToolHandler({
    required this.guide,
    required this.settings,
    required this.catalog,
    this.userId,
  });

  final WorkflowController guide;
  final SettingsController settings;
  final GuideCatalog catalog;
  String? Function()? userId;

  Future<Map<String, Object?>> handle(Map<String, Object?> event) async {
    final action = event['action'];
    final stepId = event['step_id'] as String?;
    switch (action) {
      case 'show_topic':
      case 'start_guide': // older name for booking a ride
        final app = event['app'] as String?;
        final topic = action == 'start_guide'
            ? 'book_ride'
            : event['topic'] as String?;
        final def = (app == null || topic == null)
            ? null
            : catalog.definitionFor(
                app,
                topic,
                newUser: event['new_user'] == true,
              );
        if (def == null) {
          return _fail(
            'No on-screen guide for that. Answer by voice, or pick a topic '
            'from the list in your instructions.',
          );
        }
        final outcome = await guide.startNew(
          definition: def,
          sessionId: SettingsController.randomId(),
          installationId: settings.installationId,
          language: settings.language,
          userId: userId?.call(),
        );
        return outcome is Applied ? _current() : _fail('Could not open it.');
      case 'step_done':
        if (stepId == null) return _fail('step_id is required.');
        if (_alreadyDone(stepId)) {
          // The screen is ahead (e.g. the user tapped Done). Never skip; just
          // tell the agent where the screen is so it catches up.
          return {
            ..._current(),
            'note': 'That step was already done. The screen is on this step.',
          };
        }
        return _result(await guide.apply(ConfirmStep(stepId)));
      case 'go_back':
        if (stepId == null) return _fail('step_id is required.');
        return _result(await guide.apply(GoBack(stepId)));
      case 'outcome':
        if (stepId == null) return _fail('step_id is required.');
        final booked = event['booked'] == true;
        return _result(
          await guide.apply(
            ReportOutcome(
              stepId,
              booked ? Outcome.succeeded : Outcome.notCompleted,
            ),
          ),
        );
      case 'close_topic':
        await guide.clear();
        return {
          'ok': true,
          'active_guide': false,
          'message': 'Screen cleared. Answer by voice.',
        };
      case 'current_step':
        return _current();
      default:
        return _fail('Unknown action.');
    }
  }

  bool _alreadyDone(String stepId) {
    final session = guide.session;
    final def = guide.definition;
    if (session == null || def == null || !session.isOpen) return false;
    final i = def.indexOf(stepId);
    return i >= 0 &&
        i < def.indexOf(session.currentStepId) &&
        session.confirmedAt(stepId) != null;
  }

  Map<String, Object?> _result(ApplyOutcome outcome) => switch (outcome) {
    Applied(:final effect) when effect == Effect.completed =>
      guide.definition?.topic == 'book_ride'
          ? {
              'ok': true,
              'finished': true,
              'message':
                  'The user said the ride is booked. Congratulate them warmly. '
                  'Remind them to share the ride code only with the driver.',
            }
          : {
              'ok': true,
              'finished': true,
              'message': 'Guide finished. Ask if they need anything else.',
            },
    Applied(:final effect) when effect == Effect.endedWithoutSuccess => {
      'ok': true,
      'finished': true,
      'message': 'Nothing was booked. Reassure them that this is fine.',
    },
    Applied() => _current(),
    Refused() => {
      ..._current(),
      'ok': false,
      'message': 'Not applied: that was not the current step. Use this step.',
    },
    SaveFailed() => {
      ..._current(),
      'ok': false,
      'message': 'Could not save. Ask the user to say done again.',
    },
    _ => _fail('Not applied.'),
  };

  Map<String, Object?> _current() {
    final session = guide.session;
    final step = guide.currentStep;
    final def = guide.definition;
    if (session == null || step == null || def == null || !session.isOpen) {
      return {
        'ok': true,
        'active_guide': false,
        'message':
            'No guide is open. If the question matches a topic, call show_topic.',
      };
    }
    final language = session.language;
    return {
      'ok': true,
      'active_guide': true,
      'app': def.app,
      'topic': def.topic,
      'step_id': step.id,
      'step_number': def.indexOf(step.id) + 1,
      'total_steps': def.steps.length,
      'step_title': step.title.of(language),
      'instruction': step.instruction.of(language),
      'is_final_question': step.kind == StepKind.outcome,
      if (step.sensitivity == Sensitivity.secretCode)
        'warning': 'Never ask for or listen to codes, PINs or passwords.',
    };
  }

  Map<String, Object?> _fail(String message) => {
    ..._current(),
    'ok': false,
    'message': message,
  };
}
