import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/local/database.dart';
import '../../data/secure_storage/secure_storage.dart';
import '../api/api_client.dart';
import '../api/qobuz_service.dart';
import 'download_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final db = AppDatabase();
      final secureStorage = SecureStorage();
      final apiClient = ApiClient(secureStorage);
      final qobuzService = QobuzService(apiClient, secureStorage);

      final notificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await notificationsPlugin.initialize(settings: initializationSettings);

      final downloadManager = DownloadManager(
        db,
        notificationsPlugin,
        secureStorage,
      );

      // Get pending tasks up to limit
      final tasks = await db.getAllTasks();
      final pendingTasks = tasks
          .where((t) => t.status == 'pending' || t.status == 'failed')
          .take(3)
          .toList(); // Simple concurrent limit 3

      if (pendingTasks.isEmpty) {
        return Future.value(true);
      }

      for (var task in pendingTasks) {
        try {
          final downloadInfo = await qobuzService.getDownloadUrl(
            task.trackId,
            task.quality,
          );
          await downloadManager.executeDownload(task, downloadInfo);
        } catch (e) {
          await db.updateTask(task.copyWith(status: 'failed'));
        }
      }

      return Future.value(true);
    } catch (err) {
      return Future.value(false);
    }
  });
}

class BackgroundWorker {
  static void initialize() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static void triggerDownloadQueue() {
    Workmanager().registerOneOffTask(
      "download_queue_task",
      "downloadQueueTask",
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run on network
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
