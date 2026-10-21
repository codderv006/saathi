import '../../core/services/settings_controller.dart';
import '../guided_workflow/data/ride_workflow.dart';
import '../guided_workflow/data/workflow_registry.dart';
import '../guided_workflow/domain/workflow.dart';
import '../guided_workflow/domain/workflow_controller.dart';
import '../guided_workflow/domain/workflow_engine.dart';

/// Applies guide actions requested by the voice agent (Bolna custom function
/// `saathi_guide`) and returns what the agent should know next.
///
/// The agent only relays what the user said ("I use Ola", "done", "go back",
/// "it's booked"). Every action goes through the workflow engine: it must name the
/// current step, so the agent can never skip ahead, and an outcome can only be
/// reported on the final step.
class GuideToolHandler {
  GuideToolHandler({required this.guide, required this.settings, this.userId});

  final WorkflowController guide;
  final SettingsController settings;
  String? Function()? userId;

  Future<Map<String, Object?>> handle(Map<String, Object?> event) async {
    final action = event['action'];
    final stepId = event['step_id'] as String?;
    switch (action) {
      case 'start_guide':
        final app = _app(event['app']);
        if (app == null) {
          return _fail('Ask which app they use: Ola, Uber or Rapido.');
        }
        final fromInstall = event['new_user'] == true;
        final outcome = await guide.startNew(
          definition: WorkflowRegistry.find(
            app.workflowId(fromInstall: fromInstall),
          )!,
          sessionId: SettingsController.randomId(),
          installationId: settings.installationId,
          language: settings.language,
          userId: userId?.call(),
        );
        return outcome is Applied ? _current() : _fail('Could not start.');
      case 'step_done':
        if (stepId == null) return _fail('step_id is required.');
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
      case 'current_step':
        return _current();
      default:
        return _fail('Unknown action.');
    }
  }

  RideApp? _app(Object? name) {
    for (final app in RideApp.values) {
      if (app.name == name) return app;
    }
    return null;
  }

  Map<String, Object?> _result(ApplyOutcome outcome) => switch (outcome) {
    Applied(:final effect) when effect == Effect.completed => {
      'ok': true,
      'finished': true,
      'message':
          'The user said the ride is booked. Congratulate them warmly. Remind '
          'them to share the ride code only with the driver.',
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
            'No guide is open. Ask which app they use and whether they '
            'already use it, then call start_guide.',
      };
    }
    final language = session.language;
    return {
      'ok': true,
      'active_guide': true,
      'app': RideApp.fromWorkflowId(def.id)?.name,
      'step_id': step.id,
      'step_number': def.indexOf(step.id) + 1,
      'total_steps': def.steps.length,
      'step_title': step.title.of(language),
      'instruction': step.instruction.of(language),
      'is_final_question': step.kind == StepKind.outcome,
      if (step.sensitivity == Sensitivity.secretCode)
        'warning': 'Never ask for or listen to the code.',
    };
  }

  Map<String, Object?> _fail(String message) => {
    ..._current(),
    'ok': false,
    'message': message,
  };
}
