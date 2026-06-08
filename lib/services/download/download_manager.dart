import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import '../../data/local/database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import '../api/qobuz_service.dart' show DownloadUrlInfo;
import 'download_service.dart' show DownloadService;

class DownloadManager {
  final Dio _apiDio; // For API calls (has Qobuz headers)
  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _notifications;
  final Dio _downloadDio =
      Dio(); // Clean Dio for CDN download (no Qobuz base URL)

  DownloadManager(this._apiDio, this._db, this._notifications);

  Future<void> executeDownload(DownloadTask task, DownloadUrlInfo downloadInfo) async {
    final savePath = task.savePath;
    if (savePath == null || savePath.isEmpty) {
      await _db.updateTask(task.copyWith(status: 'failed'));
      return;
    }

    final saveDir = Directory(savePath);
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    // Determine extension from MIME type, with quality-based fallback
    var ext = DownloadService.extensionFromMime(downloadInfo.mimeType, task.quality);
    debugPrint('DownloadManager MIME: ${downloadInfo.mimeType} → ext: $ext');
    final fileName = "${task.trackTitle}$ext".replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );
    var finalPath = p.join(saveDir.path, fileName);
    final tempPath = "$finalPath.part";

    int downloaded = 0;
    try {
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        downloaded = await tempFile.length();
      }

      // Use a clean Dio instance for CDN download — the fileUrl is a full HTTPS URL
      await _downloadDio.download(
        downloadInfo.url,
        tempPath,
        options: Options(
          headers: downloaded > 0 ? {'Range': 'bytes=$downloaded-'} : null,
        ),
        onReceiveProgress: (count, total) async {
          final current = downloaded + count;
          final totalBytes = total != -1 ? downloaded + total : -1;

          await _db.updateTask(
            task.copyWith(
              downloadedBytes: current,
              totalBytes: totalBytes,
              status: 'downloading',
            ),
          );

          if (totalBytes > 0) {
            final progress = (current / totalBytes * 100).toInt();
            _showProgressNotification(task.id, task.trackTitle, progress);
          }
        },
      );

      // Validate with magic bytes and correct extension if needed
      final downloadedFile = File(tempPath);
      try {
        final raf = await downloadedFile.open(mode: FileMode.read);
        final headerBytes = await raf.read(4);
        await raf.close();
        final detectedExt = DownloadService.detectExtensionFromBytes(headerBytes);
        if (detectedExt != ext) {
          debugPrint(
            'DownloadManager magic-byte mismatch! Expected $ext but '
            'detected $detectedExt. Correcting.',
          );
          ext = detectedExt;
          final correctedFileName = "${task.trackTitle}$ext".replaceAll(
            RegExp(r'[\\/:*?"<>|]'),
            '',
          );
          finalPath = p.join(saveDir.path, correctedFileName);
        }
      } catch (e) {
        debugPrint('DownloadManager magic-byte detection failed: $e');
      }

      // Rename temp file to final
      await downloadedFile.rename(finalPath);
      await _db.updateTask(
        task.copyWith(
          status: 'completed',
          downloadedBytes: task.totalBytes,
          savePath: drift.Value(finalPath),
        ),
      );
      _showCompletionNotification(task.id, task.trackTitle);
    } catch (e) {
      await _db.updateTask(task.copyWith(status: 'failed'));
      _showErrorNotification(task.id, task.trackTitle);
      rethrow;
    }
  }

  void _showProgressNotification(int id, String title, int progress) {
    _notifications.show(
      id: id,
      title: 'Downloading $title',
      body: '$progress%',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Active Downloads',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          ongoing: true,
          onlyAlertOnce: true,
        ),
      ),
    );
  }

  void _showCompletionNotification(int id, String title) {
    _notifications.show(
      id: id,
      title: 'Download Complete',
      body: title,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Active Downloads',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  void _showErrorNotification(int id, String title) {
    _notifications.show(
      id: id,
      title: 'Download Failed',
      body: title,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Active Downloads',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }
}
