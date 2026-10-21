import '../domain/workflow.dart';
import 'ride_workflow.dart';

/// All guided workflows the app ships. Add new ones here (one data file each).
abstract final class WorkflowRegistry {
  static final List<WorkflowDefinition> all = [
    for (final app in RideApp.values) ...[
      rideWorkflow(app, fromInstall: true),
      rideWorkflow(app, fromInstall: false),
    ],
  ];

  static WorkflowDefinition? find(String id) {
    for (final w in all) {
      if (w.id == id) return w;
    }
    return null;
  }
}
