import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/db/app_database.dart';
import '../../data/repositories/drift_todo_repository.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../services/notification_service.dart';
import '../../services/permission_service.dart';
import '../../services/persistent_notification_controller.dart';

/// Overridden with the real instance in main() — SharedPreferences must be
/// loaded before runApp so settings are available synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.open());

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => DriftTodoRepository(ref.watch(databaseProvider)),
);

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(ref.watch(notificationServiceProvider)),
);

final persistentNotificationControllerProvider =
    Provider<PersistentNotificationController>(
  (ref) => const PersistentNotificationController(),
);

/// Re-checked (invalidate) after every request the settings screen makes.
final permissionOverviewProvider = FutureProvider<PermissionOverview>(
  (ref) => ref.watch(permissionServiceProvider).overview(),
);
