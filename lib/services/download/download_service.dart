import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'package:audiotags/audiotags.dart';
import 'package:archive/archive_io.dart';
import '../../data/models/qobuz_models.dart';
import '../../data/local/database.dart';
import '../../data/secure_storage/secure_storage.dart';
import '../api/api_client.dart';
import '../api/qobuz_service.dart';
import '../../services/permissions/permission_handler.dart';

/// Info about the currently active download for the floating bar.
class ActiveDownloadInfo {
  final int trackId;
  final String trackTitle;
  final String albumTitle;
  final String artistName;
  final String coverUrl;
  final double progress;

  ActiveDownloadInfo({
    required this.trackId,
    required this.trackTitle,
    required this.albumTitle,
    required this.artistName,
    required this.coverUrl,
    required this.progress,
  });
}

class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();
  DownloadService._();

  final Dio _downloadDio = Dio();
  late AppDatabase _db;
  late QobuzService _qobuzService;
  late SecureStorage _secureStorage;
  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;
  bool _isProcessing = false;
  final int _maxConcurrent = 4;
  String _baseMusicDir = '/storage/emulated/0/Music/Ganne';

  final StreamController<Map<int, double>> _progressController =
      StreamController<Map<int, double>>.broadcast();
  Stream<Map<int, double>> get progressStream => _progressController.stream;
  final Map<int, double> _currentProgress = {};

  final StreamController<ActiveDownloadInfo?> _activeController =
      StreamController<ActiveDownloadInfo?>.broadcast();
  Stream<ActiveDownloadInfo?> get activeDownloadStream =>
      _activeController.stream;
  ActiveDownloadInfo? _activeInfo;
  ActiveDownloadInfo? get activeDownload => _activeInfo;

  final Map<int, CancelToken> _cancelTokens = {};

  Future<void> initialize(AppDatabase db, SecureStorage secureStorage) async {
    if (_initialized) return;
    _db = db;
    _secureStorage = secureStorage;
    final apiClient = ApiClient(secureStorage);
    _qobuzService = QobuzService(apiClient, secureStorage);

    final customPath = await secureStorage.readKey('download_path');
    if (customPath != null && customPath.isNotEmpty) {
      _baseMusicDir = customPath;
    } else {
      // Default to public music dir on Android
      if (Platform.isAndroid) {
        try {
          final publicDir =
              await ExternalPath.getExternalStoragePublicDirectory(
                ExternalPath.DIRECTORY_MUSIC,
              );
          _baseMusicDir = p.join(publicDir, 'Ganne');
        } catch (e) {
          debugPrint('ExternalPath failed: $e');
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _baseMusicDir = p.join(dir.path, 'Music');
      }
    }

    debugPrint('Ganne active download path: $_baseMusicDir');

    try {
      _notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications!.initialize(settings: initSettings);
    } catch (e) {
      debugPrint('Notifications init failed: $e');
      _notifications = null;
    }
    _initialized = true;
  }

  String get baseMusicDir => _baseMusicDir;
  void setDownloadPath(String path) => _baseMusicDir = path;

  /// Format artist string: "A & B" or "A, B & C"
  static String joinArtists(List<String>? artists, {String? fallback}) {
    if (artists == null || artists.isEmpty) return fallback ?? 'Unknown';
    if (artists.length == 1) return artists[0];
    if (artists.length == 2) return '${artists[0]} & ${artists[1]}';

    final list = List<String>.from(artists);
    final last = list.removeLast();
    return '${list.join(', ')} & $last';
  }

  /// Format file name as "[Artist] - [Title] ([Version]).ext"
  static String formatFileName(
    String artistName,
    String trackTitle,
    String? version,
    String ext,
  ) {
    final titleWithVersion = version != null && version.isNotEmpty
        ? '$trackTitle ($version)'
        : trackTitle;
    return '$artistName - $titleWithVersion$ext'.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '',
    );
  }

  /// Queue a track for download.
  /// Returns 'queued', 'already_in_queue', or 'already_downloaded'.
  Future<String> queueTrack({
    required int trackId,
    required String trackTitle,
    required String albumTitle,
    required String artistName,
    required String coverUrl,
    required String quality,
    String? trackVersion,
    String? albumArtist,
    int? trackNumber,
    int? year,
    String? genre,
  }) async {
    if (await _db.isTrackInQueue(trackId)) {
      return 'already_in_queue';
    }
    if (await _db.isTrackCompleted(trackId)) {
      return 'already_downloaded';
    }

    final sanitizedArtist = artistName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    final sanitizedAlbum = albumTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    final savePath = p.join(_baseMusicDir, sanitizedArtist, sanitizedAlbum);

    await _db.insertTask(
      DownloadTasksCompanion.insert(
        trackId: trackId,
        trackTitle: trackTitle,
        albumTitle: albumTitle,
        artistName: artistName,
        albumArtist: drift.Value(albumArtist),
        trackVersion: drift.Value(trackVersion),
        trackNumber: drift.Value(trackNumber),
        year: drift.Value(year),
        genre: drift.Value(genre),
        coverUrl: coverUrl,
        quality: quality,
        addedAt: DateTime.now().millisecondsSinceEpoch,
        savePath: drift.Value(savePath),
      ),
    );
    processQueue();
    return 'queued';
  }

  bool _batteryOptAsked = false;

  void processQueue() async {
    if (!_initialized || _isProcessing) return;
    _isProcessing = true;

    final hasStorage = await PermissionService.requestStoragePermission();
    if (!hasStorage) {
      debugPrint('Storage permission denied!');
      _isProcessing = false;
      return;
    }
    await PermissionService.requestNotificationPermission();

    // Ask to disable battery optimization once per session so downloads
    // continue running when the app is in the background.
    if (!_batteryOptAsked) {
      _batteryOptAsked = true;
      final isExempt = await PermissionService.isBatteryOptimizationDisabled();
      if (!isExempt) {
        await PermissionService.requestBatteryOptimizationExemption();
      }
    }

    try {
      while (true) {
        final tasks = await _db.getAllTasks();
        final activeCount = tasks
            .where((t) => t.status == 'downloading')
            .length;
        final slotsAvailable = _maxConcurrent - activeCount;
        if (slotsAvailable <= 0) break;

        final pending = tasks
            .where((t) => t.status == 'pending')
            .take(slotsAvailable)
            .toList();
        if (pending.isEmpty) break;
        await Future.wait(pending.map((task) => _downloadTask(task)));
      }
    } finally {
      _isProcessing = false;
      _setActiveInfo(null);
    }
  }

  Future<void> _downloadTask(DownloadTask task) async {
    try {
      await _db.updateTask(task.copyWith(status: 'downloading'));
      _updateProgress(task.trackId, 0.0);

      // Prevents the navigation progress bar from flashing wildly during multiple concurrent downloads
      if (_activeInfo == null || _activeInfo!.trackId == task.trackId) {
        _setActiveInfo(
          ActiveDownloadInfo(
            trackId: task.trackId,
            trackTitle: task.trackTitle,
            albumTitle: task.albumTitle,
            artistName: task.artistName,
            coverUrl: task.coverUrl,
            progress: 0,
          ),
        );
      }

      final fileUrl = await _qobuzService.getDownloadUrl(
        task.trackId,
        task.quality,
      );

      final savePath = task.savePath;
      if (savePath == null || savePath.isEmpty) throw Exception('No save path');
      final saveDir = Directory(savePath);
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      final ext = task.quality == '5' ? '.mp3' : '.flac';
      final fileName = formatFileName(
        task.artistName,
        task.trackTitle,
        task.trackVersion,
        ext,
      );
      final finalPath = p.join(saveDir.path, fileName);
      final tempPath = "$finalPath.part";

      final cancelToken = CancelToken();
      _cancelTokens[task.trackId] = cancelToken;
      int lastNotifiedPercent = -1;
      int lastUpdateTime = 0;

      await _downloadDio.download(
        fileUrl,
        tempPath,
        cancelToken: cancelToken,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            final progress = count / total;
            final now = DateTime.now().millisecondsSinceEpoch;
            // Throttle UI stream updates to ~15 FPS to prevent UI bugging out
            if (now - lastUpdateTime > 66 || progress == 1.0) {
              lastUpdateTime = now;
              _updateProgress(task.trackId, progress);

              if (_activeInfo == null || _activeInfo!.trackId == task.trackId) {
                _setActiveInfo(
                  ActiveDownloadInfo(
                    trackId: task.trackId,
                    trackTitle: task.trackTitle,
                    albumTitle: task.albumTitle,
                    artistName: task.artistName,
                    coverUrl: task.coverUrl,
                    progress: progress,
                  ),
                );
              }
            }
            final percent = (progress * 100).toInt();
            if (percent != lastNotifiedPercent && percent % 5 == 0) {
              lastNotifiedPercent = percent;
              _showProgressNotification(task.id, task.trackTitle, percent);
            }
          }
        },
      );

      // 1. Rename the download file from tempPath to finalPath (done first for consistency)
      await File(tempPath).rename(finalPath);

      final applyMetadataRaw = await _secureStorage.readKey('setting_metadata');
      final shouldApplyMetadata = applyMetadataRaw != 'false';

      if (shouldApplyMetadata) {
        File? coverFile;
        // A. Separate, safe try-catch for downloading the cover art
        if (task.coverUrl.isNotEmpty) {
          try {
            final response = await http
                .get(Uri.parse(task.coverUrl))
                .timeout(const Duration(seconds: 10));
            if (response.statusCode == 200) {
              final tempDir = await getTemporaryDirectory();
              coverFile = File(
                p.join(tempDir.path, 'cover_${task.trackId}.jpg'),
              );
              await coverFile.writeAsBytes(response.bodyBytes);
            }
          } catch (e) {
            debugPrint('Cover download failed for metadata: $e');
          }
        }

        // B. Apply metadata to renamed file
        try {
          await _applyMetadata(File(finalPath), coverFile, task);
        } catch (e) {
          debugPrint('Failed to apply metadata: $e');
        }

        // C. Clean up cover temp file safely
        if (coverFile != null) {
          try {
            if (await coverFile.exists()) {
              await coverFile.delete();
            }
          } catch (e) {
            debugPrint('Failed to delete temp cover file: $e');
          }
        }
      }

      await _db.updateTask(
        task.copyWith(status: 'completed', savePath: drift.Value(finalPath)),
      );
      _updateProgress(task.trackId, 1.0);
      _showCompletionNotification(task.id, task.trackTitle);
      _cancelTokens.remove(task.trackId);

      if (_activeInfo?.trackId == task.trackId) {
        _setActiveInfo(null);
      }

      // Media scan
      try {
        const channel = MethodChannel('com.ganne.media_scanner');
        await channel.invokeMethod('scanFile', {'path': finalPath});
      } catch (_) {}
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        await _db.updateTask(task.copyWith(status: 'failed'));
        _updateProgress(task.trackId, -1.0);
      } else {
        debugPrint('Download failed for ${task.trackTitle}: $e');
        await _db.updateTask(task.copyWith(status: 'failed'));
        _updateProgress(task.trackId, -1.0);
        _showErrorNotification(task.id, task.trackTitle);
      }
      _cancelTokens.remove(task.trackId);
    }
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
      debugPrint('Metadata apply error: $e');
    }
  }

  // Not used by dart_tags but kept for future ref
  void _addMeta(StringBuffer sb, String key, String value) {}

  Future<void> downloadAlbumAsZip({
    required QobuzAlbum album,
    required FetchedAlbumResponse fetchedData,
    required String qualityId,
  }) async {
    final startId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    debugPrint('[ZIP] Starting ZIP for album: ${album.title}');

    _updateProgress(startId, 0.0);
    _setActiveInfo(
      ActiveDownloadInfo(
        trackId: startId,
        trackTitle: 'Zipping: ${album.title}',
        albumTitle: album.title,
        artistName: album.artist?.name ?? 'Unknown',
        coverUrl: album.getCoverLargeUrl(),
        progress: 0.0,
      ),
    );

    try {
      final hasStorage = await PermissionService.requestStoragePermission();
      debugPrint('[ZIP] Storage permission: $hasStorage');
      if (!hasStorage) {
        debugPrint('[ZIP] Storage permission denied!');
        _updateProgress(startId, -1.0);
        _setActiveInfo(null);
        return;
      }
      await PermissionService.requestNotificationPermission();

      var sanitizedArtist = (album.artist?.name ?? 'Unknown')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .trim();
      if (sanitizedArtist.isEmpty) sanitizedArtist = 'Unknown Artist';

      var sanitizedAlbum = album.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .trim();
      if (sanitizedAlbum.isEmpty) sanitizedAlbum = 'Unknown Album';

      final saveDir = Directory(p.join(_baseMusicDir, sanitizedArtist));
      debugPrint('[ZIP] Save directory: ${saveDir.path}');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      final zipPath = p.join(saveDir.path, '$sanitizedAlbum.zip');
      debugPrint('[ZIP] Zip output path: $zipPath');

      final tempDir = await getTemporaryDirectory();
      final albumTempDir = Directory(
        p.join(tempDir.path, 'ganne_zip_$startId'),
      );
      if (await albumTempDir.exists())
        await albumTempDir.delete(recursive: true);
      await albumTempDir.create(recursive: true);
      debugPrint('[ZIP] Temp directory: ${albumTempDir.path}');

      final tracks = fetchedData.tracks?.items ?? [];
      debugPrint('[ZIP] Total tracks to download: ${tracks.length}');
      if (tracks.isEmpty) {
        debugPrint('[ZIP] No tracks found in fetched data!');
        _updateProgress(startId, -1.0);
        _setActiveInfo(null);
        return;
      }

      final ext = qualityId == '5' ? '.mp3' : '.flac';

      // Download Cover
      File? coverFile;
      final coverUrl = album.getCoverLargeUrl();
      if (coverUrl.isNotEmpty) {
        try {
          final res = await http.get(Uri.parse(coverUrl));
          if (res.statusCode == 200) {
            coverFile = File(p.join(albumTempDir.path, 'cover.jpg'));
            await coverFile.writeAsBytes(res.bodyBytes);
            debugPrint(
              '[ZIP] Cover downloaded: ${coverFile.path} (${res.bodyBytes.length} bytes)',
            );
          }
        } catch (e) {
          debugPrint('[ZIP] Cover download failed: $e');
        }
      }

      int completed = 0;
      List<File> downloadedFiles = [];

      for (final track in tracks) {
        final trackProgress = completed / tracks.length;
        _updateProgress(startId, trackProgress);
        _setActiveInfo(
          ActiveDownloadInfo(
            trackId: startId,
            trackTitle: 'Zipping: ${album.title}',
            albumTitle: album.title,
            artistName: album.artist?.name ?? 'Unknown',
            coverUrl: coverUrl,
            progress: trackProgress,
          ),
        );

        try {
          debugPrint(
            '[ZIP] Downloading track ${completed + 1}/${tracks.length}: ${track.title}',
          );
          final fileUrl = await _qobuzService.getDownloadUrl(
            track.id,
            qualityId,
          );
          debugPrint('[ZIP] Got download URL for track ${track.id}');

          final artistName =
              track.performer?.name ?? album.artist?.name ?? 'Unknown';
          final tempTrackPath = p.join(
            albumTempDir.path,
            formatFileName(artistName, track.title, track.version, ext),
          );

          await _downloadDio.download(fileUrl, tempTrackPath);

          final downloadedFile = File(tempTrackPath);
          final fileSize = await downloadedFile.length();
          debugPrint(
            '[ZIP] Track downloaded: $tempTrackPath ($fileSize bytes)',
          );

          if (fileSize > 0) {
            downloadedFiles.add(downloadedFile);

            // Tag it
            try {
              final fakeTask = DownloadTask(
                id: 0,
                trackId: track.id,
                trackTitle: track.title,
                albumTitle: album.title,
                artistName:
                    track.performer?.name ?? album.artist?.name ?? 'Unknown',
                coverUrl: coverUrl,
                quality: qualityId,
                status: 'completed',
                addedAt: 0,
                totalBytes: 0,
                downloadedBytes: 0,
                trackNumber: track.trackNumber,
                year: album.releasedAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        album.releasedAt! * 1000,
                      ).year
                    : null,
                genre: album.genre?.name,
                albumArtist: album.artist?.name,
              );
              await _applyMetadata(downloadedFile, coverFile, fakeTask);
              debugPrint('[ZIP] Metadata applied for: ${track.title}');
            } catch (e) {
              debugPrint('[ZIP] Metadata error for ${track.title}: $e');
            }
          } else {
            debugPrint(
              '[ZIP] WARNING: Downloaded file is empty for ${track.title}',
            );
          }
        } catch (e) {
          debugPrint('[ZIP] FAILED to download track ${track.title}: $e');
        }
        completed++;
      }

      debugPrint(
        '[ZIP] Downloaded ${downloadedFiles.length} files successfully',
      );

      if (downloadedFiles.isEmpty) {
        debugPrint('[ZIP] No files were downloaded! Aborting zip creation.');
        _updateProgress(startId, -1.0);
        _showErrorNotification(
          startId,
          'ZIP Failed: No tracks downloaded for ${album.title}',
        );
        await albumTempDir.delete(recursive: true);
        _setActiveInfo(null);
        return;
      }

      _updateProgress(startId, 0.95);
      _setActiveInfo(
        ActiveDownloadInfo(
          trackId: startId,
          trackTitle: 'Zipping: ${album.title}',
          albumTitle: album.title,
          artistName: album.artist?.name ?? 'Unknown',
          coverUrl: coverUrl,
          progress: 0.95,
        ),
      );

      // Create ZIP in temp directory first (avoids Android scoped storage file descriptor issues)
      final tempZipPath = p.join(albumTempDir.path, '$sanitizedAlbum.zip');
      debugPrint('[ZIP] Creating zip archive in temp: $tempZipPath');

      // Offload zip encoding to a background isolate to prevent UI freezing
      final filePaths = downloadedFiles.map((f) => f.path).toList();
      final coverPath = (coverFile != null && await coverFile.exists())
          ? coverFile.path
          : null;

      await compute(
        _createZipInIsolate,
        _ZipParams(
          outputPath: tempZipPath,
          filePaths: filePaths,
          coverPath: coverPath,
        ),
      );

      final tempZipFile = File(tempZipPath);
      final tempZipSize = await tempZipFile.length();
      debugPrint('[ZIP] Temp zip created: $tempZipPath ($tempZipSize bytes)');

      // Copy the finished zip from temp to public external storage
      debugPrint('[ZIP] Copying zip to final path: $zipPath');
      await tempZipFile.copy(zipPath);

      final finalZipFile = File(zipPath);
      final finalZipSize = await finalZipFile.length();
      debugPrint('[ZIP] Final zip copied: $zipPath ($finalZipSize bytes)');

      await albumTempDir.delete(recursive: true);

      // Media scan so it shows up in file explorers instantly
      try {
        const channel = MethodChannel('com.ganne.media_scanner');
        await channel.invokeMethod('scanFile', {'path': zipPath});
      } catch (_) {}

      _updateProgress(startId, 1.0);
      _setActiveInfo(
        ActiveDownloadInfo(
          trackId: startId,
          trackTitle: 'Zipping: ${album.title}',
          albumTitle: album.title,
          artistName: album.artist?.name ?? 'Unknown',
          coverUrl: coverUrl,
          progress: 1.0,
        ),
      );
      _showCompletionNotification(startId, 'Zipped: ${album.title}');

      // Keep the completed state visible for a moment
      await Future.delayed(const Duration(seconds: 2));
    } catch (e, stack) {
      debugPrint('[ZIP] FATAL ERROR: $e');
      debugPrint('[ZIP] Stack: $stack');
      _updateProgress(startId, -1.0);
      _showErrorNotification(startId, 'ZIP Failed: ${album.title}');
    } finally {
      _setActiveInfo(null);
    }
  }

  void cancelDownload(int trackId) {
    _cancelTokens[trackId]?.cancel('User cancelled');
    _cancelTokens.remove(trackId);
  }

  void cancelAll() {
    for (final token in _cancelTokens.values) {
      token.cancel('User cancelled all');
    }
    _cancelTokens.clear();
  }

  Future<void> deleteEmptyDirs(String filePath) async {
    try {
      final baseDir = _baseMusicDir;
      var currentDir = Directory(p.dirname(filePath));

      while (currentDir.path != baseDir &&
          currentDir.path.length > baseDir.length) {
        if (await currentDir.exists()) {
          final entities = await currentDir.list().isEmpty;
          if (entities) {
            await currentDir.delete();
            debugPrint('Deleted empty directory: ${currentDir.path}');
            currentDir = currentDir.parent;
          } else {
            break;
          }
        } else {
          break;
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up empty directories: $e');
    }
  }

  Future<void> resetLibraryStorage({VoidCallback? onStopPlayer}) async {
    // 1. Cancel all active download tokens
    cancelAll();

    // 2. Stop player via callback
    if (onStopPlayer != null) {
      onStopPlayer();
    }

    // 3. Clear SQLite database completely
    await _db.clearAllTasks();

    // 4. Recursively delete the entire base music directory
    try {
      final dir = Directory(_baseMusicDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint(
          'Successfully deleted music folder recursively: $_baseMusicDir',
        );
      }
      // Re-create the empty directory
      await dir.create(recursive: true);
    } catch (e) {
      debugPrint('Error deleting music directory recursively: $e');
    }
  }

  void _setActiveInfo(ActiveDownloadInfo? info) {
    _activeInfo = info;
    _activeController.add(info);
  }

  void _updateProgress(int trackId, double progress) {
    _currentProgress[trackId] = progress;
    _progressController.add(Map.from(_currentProgress));
  }

  Map<int, double> get currentProgress => Map.from(_currentProgress);

  void _showProgressNotification(int id, String title, int progress) {
    _notifications?.show(
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
    _notifications?.show(
      id: id,
      title: 'Download Complete',
      body: title,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Active Downloads',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }

  void _showErrorNotification(int id, String title) {
    _notifications?.show(
      id: id,
      title: 'Download Failed',
      body: title,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Active Downloads',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }
}

/// Parameters for the background zip isolate
class _ZipParams {
  final String outputPath;
  final List<String> filePaths;
  final String? coverPath;

  _ZipParams({
    required this.outputPath,
    required this.filePaths,
    this.coverPath,
  });
}

/// Top-level function that runs in a background isolate via compute()
Future<void> _createZipInIsolate(_ZipParams params) async {
  final encoder = ZipFileEncoder();
  encoder.create(params.outputPath);

  for (final filePath in params.filePaths) {
    final file = File(filePath);
    await encoder.addFile(file, p.basename(filePath));
  }

  if (params.coverPath != null) {
    final coverFile = File(params.coverPath!);
    if (coverFile.existsSync()) {
      await encoder.addFile(coverFile, 'cover.jpg');
    }
  }

  encoder.close();
}
