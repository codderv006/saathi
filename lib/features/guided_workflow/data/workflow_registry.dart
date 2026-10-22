import '../domain/workflow.dart';
import 'guide_catalog.dart';
import 'ride_workflow.dart';

/// All guides the app ships: ride booking (with real screenshots) plus everything
/// in the JSON catalog once [load] has run.
abstract final class WorkflowRegistry {
  static final List<WorkflowDefinition> _rides = [
    for (final app in RideApp.values) ...[
      rideWorkflow(app, fromInstall: true),
      rideWorkflow(app, fromInstall: false),
    ],
  ];

  static GuideCatalog? _catalog;
  static GuideCatalog? get catalog => _catalog;

  static Future<GuideCatalog> load() async =>
      _catalog ??= await GuideCatalog.load();

  /// For tests or tools that already have the JSON.
  static void useCatalog(GuideCatalog catalog) => _catalog = catalog;

  static List<WorkflowDefinition> get all => [
    ..._rides,
    ...?_catalog?.definitions,
  ];

  static WorkflowDefinition? find(String id) {
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }
}
