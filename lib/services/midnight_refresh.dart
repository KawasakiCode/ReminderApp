import 'package:workmanager/workmanager.dart';

import '../core/app_constants.dart';
import '../core/day_key.dart';

/// At 00:00 "today" changes, so the widget and the persistent notification
/// must roll over to the new day. WorkManager persists across reboots and
/// process death; the task re-arms itself for the next midnight every time it
/// runs (see `workmanagerDispatcher` in background_entrypoints.dart).
///
/// Doze can delay the task by a few minutes. That's acceptable because the
/// native renderers check the snapshot's `dayKey` and show an empty "new day"
/// state instead of yesterday's list until the refresh lands, and the
/// foreground service additionally re-renders itself exactly at midnight.
class MidnightRefresh {
  const MidnightRefresh._();

  static Future<void> ensureScheduled() async {
    await Workmanager().registerOneOffTask(
      MidnightTask.uniqueName,
      MidnightTask.taskName,
      // Small grace period so the run lands safely on the new day.
      initialDelay:
          untilNextMidnight(DateTime.now()) + const Duration(seconds: 30),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
