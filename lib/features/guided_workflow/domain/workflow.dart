/// Guided-workflow model. Pure Dart (no Flutter/Firebase/voice imports) so the rules
/// are deterministic and unit-testable, and new workflows are data, not new code.
library;

/// Text in every supported language. Workflow content is data, so it lives here
/// rather than in the UI's ARB files.
class LocalizedText {
  const LocalizedText({required this.en, required this.mr});

  final String en;
  final String mr;

  String of(String languageCode) => languageCode == 'mr' ? mr : en;
}

/// A rectangle in a screenshot, as fractions (0–1) of the ORIGINAL image's width and
/// height, so it stays aligned at any display size.
class NormalizedRect {
  const NormalizedRect(this.left, this.top, this.width, this.height)
    : assert(left >= 0 && top >= 0 && width > 0 && height > 0),
      assert(left + width <= 1.0001 && top + height <= 1.0001);

  final double left;
  final double top;
  final double width;
  final double height;
}

class ScreenshotAnnotation {
  const ScreenshotAnnotation({
    required this.highlight,
    this.marker,
    this.label,
  });

  final NormalizedRect highlight;

  /// Optional numbered marker drawn at the highlight's top-left corner.
  final int? marker;

  /// Optional short helper label shown next to the highlight.
  final LocalizedText? label;
}

class StepScreenshot {
  const StepScreenshot({
    required this.asset,
    required this.description,
    this.annotations = const [],
  });

  /// Bundled asset path, e.g. assets/workflows/ola/ola_03_destination.png.
  /// May not exist yet: the UI shows a labelled placeholder until it's supplied.
  final String asset;

  /// Accessibility description of what the screenshot shows.
  final LocalizedText description;
  final List<ScreenshotAnnotation> annotations;
}

/// Why a step needs extra care; drives the safety note shown with it.
enum Sensitivity {
  none,

  /// Spending money / irreversible booking.
  money,

  /// Secret codes (OTP). Must never be spoken to anyone, including Saathi.
  secretCode,
}

enum StepKind {
  /// User does something in the other app, then confirms.
  instruction,

  /// Final step: the user reports what actually happened.
  outcome,
}

/// Optional on-screen helpers a step offers in addition to confirm/repeat/help/back.
enum StepHelper {
  /// "Copy an address from Saathi" sheet. Saathi never pastes into the other app.
  copyText,
}

/// Animated vector illustration for a step: a stylised phone screen of [kind]
/// (e.g. `chat`, `qr`, `ride_card`) with a pulsing tap target at [focus]. Used when
/// there is no real screenshot, so a step never shows an empty picture.
class StepVisual {
  const StepVisual(this.kind, {this.focus});

  final String kind;
  final String? focus;
}

class WorkflowStep {
  const WorkflowStep({
    required this.id,
    required this.title,
    required this.instruction,
    this.simplerInstruction,
    this.screenshot,
    this.visual,
    this.helpers = const {},
    this.kind = StepKind.instruction,
    this.sensitivity = Sensitivity.none,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText instruction;

  /// "Explain it more simply" text (optional).
  final LocalizedText? simplerInstruction;
  final StepScreenshot? screenshot;
  final StepVisual? visual;
  final Set<StepHelper> helpers;
  final StepKind kind;

  final Sensitivity sensitivity;

  /// Involves money, an irreversible action or a secret; UI adds a safety note.
  bool get isSensitive => sensitivity != Sensitivity.none;
}

class WorkflowDefinition {
  WorkflowDefinition({
    required this.id,
    required this.title,
    required this.steps,
    this.app,
    this.topic,
    this.supportedLanguages = const {'en', 'mr'},
  }) : assert(steps.isNotEmpty),
       assert(
         steps.map((s) => s.id).toSet().length == steps.length,
         'step ids must be unique',
       ),
       assert(
         steps.where((s) => s.kind == StepKind.outcome).length <= 1 &&
             (steps.every((s) => s.kind != StepKind.outcome) ||
                 steps.last.kind == StepKind.outcome),
         'at most one outcome step, and it must be last',
       );

  final String id;
  final LocalizedText title;
  final List<WorkflowStep> steps;

  /// App id from the catalog (ola, uber, rapido, gpay, phonepe, whatsapp).
  final String? app;

  /// Topic id within the app (book_ride, scan_qr, post_status, …).
  final String? topic;
  final Set<String> supportedLanguages;

  String get initialStepId => steps.first.id;

  int indexOf(String stepId) => steps.indexWhere((s) => s.id == stepId);

  WorkflowStep? stepById(String stepId) {
    final i = indexOf(stepId);
    return i < 0 ? null : steps[i];
  }

  /// Transitions are linear: next/previous in list order.
  String? nextStepId(String stepId) {
    final i = indexOf(stepId);
    return i < 0 || i == steps.length - 1 ? null : steps[i + 1].id;
  }

  String? previousStepId(String stepId) {
    final i = indexOf(stepId);
    return i <= 0 ? null : steps[i - 1].id;
  }
}

enum SessionStatus {
  active,

  /// User stepped away ("stop for now" / left the screen). Resumable.
  paused,

  /// User explicitly reported the real-world task succeeded.
  completed,

  /// Session closed without a reported success (e.g. "I didn't book").
  ended,
}

enum Outcome { succeeded, notCompleted }

enum ProgressEventKind { confirmed, wentBack }

/// Append-only history; going back never erases earlier confirmations.
class ProgressEvent {
  const ProgressEvent(this.stepId, this.kind, this.at);

  final String stepId;
  final ProgressEventKind kind;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'stepId': stepId,
    'kind': kind.name,
    'at': at.toUtc().toIso8601String(),
  };

  factory ProgressEvent.fromJson(Map<String, Object?> json) => ProgressEvent(
    json['stepId']! as String,
    ProgressEventKind.values.byName(json['kind']! as String),
    DateTime.parse(json['at']! as String),
  );
}

/// Persisted session. Deliberately small: no audio, transcripts, OTPs, PINs or
/// payment data.
class WorkflowSession {
  const WorkflowSession({
    required this.id,
    required this.installationId,
    required this.workflowId,
    required this.currentStepId,
    required this.status,
    required this.language,
    required this.history,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.outcome,
  });

  final String id;
  final String installationId;

  /// Set once authentication exists (Firebase anonymous uid). Null for local-only.
  final String? userId;
  final String workflowId;
  final String currentStepId;
  final SessionStatus status;
  final String language;
  final Outcome? outcome;
  final List<ProgressEvent> history;

  /// +1 on every accepted change. Writers must name the revision they read, so a
  /// stale or duplicate write can't overwrite newer progress.
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen =>
      status == SessionStatus.active || status == SessionStatus.paused;

  DateTime? confirmedAt(String stepId) {
    for (final e in history.reversed) {
      if (e.stepId == stepId && e.kind == ProgressEventKind.confirmed) {
        return e.at;
      }
    }
    return null;
  }

  WorkflowSession copyWith({
    String? currentStepId,
    SessionStatus? status,
    String? language,
    Outcome? outcome,
    List<ProgressEvent>? history,
    int? revision,
    DateTime? updatedAt,
    String? userId,
  }) => WorkflowSession(
    id: id,
    installationId: installationId,
    userId: userId ?? this.userId,
    workflowId: workflowId,
    currentStepId: currentStepId ?? this.currentStepId,
    status: status ?? this.status,
    language: language ?? this.language,
    outcome: outcome ?? this.outcome,
    history: history ?? this.history,
    revision: revision ?? this.revision,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'installationId': installationId,
    'userId': userId,
    'workflowId': workflowId,
    'currentStepId': currentStepId,
    'status': status.name,
    'language': language,
    'outcome': outcome?.name,
    'history': history.map((e) => e.toJson()).toList(),
    'revision': revision,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory WorkflowSession.fromJson(Map<String, Object?> json) =>
      WorkflowSession(
        id: json['id']! as String,
        installationId: json['installationId']! as String,
        userId: json['userId'] as String?,
        workflowId: json['workflowId']! as String,
        currentStepId: json['currentStepId']! as String,
        status: SessionStatus.values.byName(json['status']! as String),
        language: json['language']! as String,
        outcome: json['outcome'] == null
            ? null
            : Outcome.values.byName(json['outcome']! as String),
        history: [
          for (final e in json['history']! as List)
            ProgressEvent.fromJson(Map<String, Object?>.from(e as Map)),
        ],
        revision: (json['revision']! as num).toInt(),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
      );

  @override
  String toString() =>
      'WorkflowSession($id $workflowId step=$currentStepId '
      '${status.name} rev=$revision)';
}

/// Every way a session can be acted on. Confirm/back/outcome name the step they
/// refer to, so a late or repeated command for a step that is no longer current
/// is rejected instead of skipping ahead.
sealed class WorkflowCommand {
  const WorkflowCommand();
}

class ConfirmStep extends WorkflowCommand {
  const ConfirmStep(this.stepId);
  final String stepId;
  @override
  String toString() => 'ConfirmStep($stepId)';
}

class GoBack extends WorkflowCommand {
  const GoBack(this.fromStepId);
  final String fromStepId;
  @override
  String toString() => 'GoBack($fromStepId)';
}

class ReportOutcome extends WorkflowCommand {
  const ReportOutcome(this.stepId, this.outcome);
  final String stepId;
  final Outcome outcome;
  @override
  String toString() => 'ReportOutcome($stepId, ${outcome.name})';
}

/// Read-only requests: never change the step.
class RepeatInstruction extends WorkflowCommand {
  const RepeatInstruction();
}

class RequestHelp extends WorkflowCommand {
  const RequestHelp();
}

class ExplainSimpler extends WorkflowCommand {
  const ExplainSimpler();
}

class Pause extends WorkflowCommand {
  const Pause();
}

class Resume extends WorkflowCommand {
  const Resume();
}
