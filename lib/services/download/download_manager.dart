import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/local/database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:audiotags/audiotags.dart';
import 'package:http/http.dart' as http;
import '../../data/secure_storage/secure_storage.dart';
import '../api/qobuz_service.dart' show DownloadUrlInfo;
import 'download_service.dart' show DownloadService;

class DownloadManager {
  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _notifications;
  final SecureStorage _secureStorage;
  final Dio _downloadDio =
      Dio(); // Clean Dio for CDN download (no Qobuz base URL)

  DownloadManager(this._db, this._notifications, this._secureStorage);

  Future<void> executeDownload(DownloadTask task, DownloadUrlInfo downloadInfo) async {
    final savePath = task.savePath;
    if (savePath == null || savePath.isEmpty) {
      await _db.updateTask(task.copyWith(status: 'failed'));
      return;
    }

    final tempDir = await getTemporaryDirectory();
    var ext = DownloadService.extensionFromMime(downloadInfo.mimeType, task.quality);
    debugPrint('DownloadManager MIME: ${downloadInfo.mimeType} → ext: $ext');

    var localFinalPath = p.join(tempDir.path, 'bg_download_${task.trackId}$ext');
    final localTempPath = '$localFinalPath.part';

    int downloaded = 0;
    try {
      final localTempFile = File(localTempPath);
      if (await localTempFile.exists()) {
        downloaded = await localTempFile.length();
      }

      await _downloadDio.download(
        downloadInfo.url,
        localTempPath,
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
      try {
        final raf = await localTempFile.open(mode: FileMode.read);
        final headerBytes = await raf.read(12);
        await raf.close();
        final detectedExt = DownloadService.detectExtensionFromBytes(headerBytes);
        if (detectedExt != ext) {
          debugPrint(
            'DownloadManager magic-byte mismatch! Expected $ext but '
            'detected $detectedExt. Correcting.',
          );
          ext = detectedExt;
          localFinalPath = p.join(tempDir.path, 'bg_download_${task.trackId}$ext');
        }
      } catch (e) {
        debugPrint('DownloadManager magic-byte detection failed: $e');
      }

      // Rename temp file to local final path
      final finalLocalFile = await localTempFile.rename(localFinalPath);

      final applyMetadataRaw = await _secureStorage.readKey('setting_metadata');
      final shouldApplyMetadata = applyMetadataRaw != 'false';

      if (shouldApplyMetadata) {
        File? coverFile;
        if (task.coverUrl.isNotEmpty) {
          try {
            final response = await http
                .get(Uri.parse(task.coverUrl))
                .timeout(const Duration(seconds: 10));
            if (response.statusCode == 200) {
              coverFile = File(
                p.join(tempDir.path, 'bg_cover_${task.trackId}.jpg'),
              );
              await coverFile.writeAsBytes(response.bodyBytes);
            }
          } catch (e) {
            debugPrint('Background cover download failed: $e');
          }
        }

        try {
          await _applyMetadata(finalLocalFile, coverFile, task);
        } catch (e) {
          debugPrint('Background metadata tag failed: $e');
        }

        if (coverFile != null) {
          try {
            if (await coverFile.exists()) {
              await coverFile.delete();
            }
          } catch (e) {
            debugPrint('Failed to delete temp cover: $e');
          }
        }
      }

      final saveDir = Directory(savePath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final fileName = "${task.trackTitle}$ext".replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '',
      );
      final finalPath = p.join(saveDir.path, fileName);

      // Copy completed file to final public directory (cross-device safe)
      await finalLocalFile.copy(finalPath);

      try {
        await finalLocalFile.delete();
      } catch (_) {}

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

  Future<void> _applyMetadata(
    File audioFile,
    File? coverFile,
    DownloadTask task,
  ) async {
    try {
      final tag = Tag(
        title: task.trackTitle,
        trackArtist: task.artistName,
        album: task.albumTitle,
        albumArtist: task.albumArtist,
        trackNumber: task.trackNumber,
        year: task.year,
        genre: task.genre,
        pictures: coverFile != null
            ? [
                Picture(
                  bytes: await coverFile.readAsBytes(),
                  mimeType: MimeType.jpeg,
                  pictureType: PictureType.coverFront,
                ),
              ]
            : [],
      );
      await AudioTags.write(audioFile.path, tag);
    } catch (e) {
      debugPrint('Background metadata apply error: $e');
    }
  }
}
