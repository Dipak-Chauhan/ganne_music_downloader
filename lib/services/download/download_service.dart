import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import '../../core/utils/flac_tagger.dart';
import 'package:archive/archive_io.dart';
import '../../data/models/qobuz_models.dart';
import '../../data/local/database.dart';
import '../../data/secure_storage/secure_storage.dart';
import '../api/api_client.dart';
import '../api/qobuz_service.dart';
import '../metadata/musicbrainz_service.dart';
import '../metadata/resolved_track_metadata.dart';
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

  static const MethodChannel _mediaChannel = MethodChannel(
    'com.ganne.media_scanner',
  );
  static const String _notificationIcon = 'ic_stat_ganne_download';

  final Dio _downloadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  final MusicBrainzService _musicBrainzService = MusicBrainzService();
  late AppDatabase _db;
  late QobuzService _qobuzService;
  late SecureStorage _secureStorage;
  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;
  bool _isProcessing = false;
  bool _isResetting = false;
  Future<void>? _initialization;
  final int _maxConcurrent = 2;
  String _baseMusicDir = 'Music/Ganne';
  String _workingMusicDir = 'Music/Ganne';
  String _androidDownloadLocation = 'music';
  bool _flatDownloads = false;

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
  final Map<int, Future<void>> _activeTasks = {};
  final Set<int> _queueingTrackIds = {};
  final Set<Future<void>> _queueOperations = {};
  CancelToken? _zipCancelToken;
  Completer<void>? _zipCompletion;
  bool _isZipping = false;
  int _zipSequence = 0;

  Future<void> initialize(AppDatabase db, SecureStorage secureStorage) {
    return _initialization ??= _initialize(db, secureStorage);
  }

  Future<void> _initialize(AppDatabase db, SecureStorage secureStorage) async {
    _db = db;
    _secureStorage = secureStorage;
    final apiClient = ApiClient(secureStorage);
    _qobuzService = QobuzService(apiClient, secureStorage);

    final customPath = await secureStorage.readKey('download_path');
    final storedAndroidLocation = await secureStorage.readKey(
      'setting_download_location',
    );
    _androidDownloadLocation = storedAndroidLocation == 'downloads'
        ? 'downloads'
        : storedAndroidLocation == 'custom'
        ? 'custom'
        : 'music';
    _flatDownloads =
        await secureStorage.readKey('setting_flat_downloads') == 'true';
    if (Platform.isAndroid) {
      final customLocationUsesGanneFolder =
          await secureStorage.readKey(
            'setting_custom_location_uses_ganne_folder',
          ) ==
          'true';
      await _mediaChannel.invokeMethod<void>('setCustomDownloadFolderMode', {
        'useGanneFolder': customLocationUsesGanneFolder,
      });
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      _workingMusicDir = p.join(dir.path, 'Music', 'Ganne');
      if (_androidDownloadLocation == 'custom') {
        final customPath = await _customAndroidDownloadLocationPath();
        if (customPath != null) {
          _baseMusicDir = customPath;
        } else {
          debugPrint(
            'Custom Android download location is no longer available.',
          );
          _androidDownloadLocation = 'music';
          await secureStorage.writeKey('setting_download_location', 'music');
          _baseMusicDir = await _publicAndroidDownloadLocationPath();
        }
      } else {
        _baseMusicDir = await _publicAndroidDownloadLocationPath();
      }
    } else if (customPath != null && customPath.isNotEmpty) {
      _baseMusicDir = _managedDownloadPath(customPath);
      _workingMusicDir = _baseMusicDir;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _baseMusicDir = p.join(dir.path, 'Music', 'Ganne');
      _workingMusicDir = _baseMusicDir;
    }

    debugPrint('Ganne active download path: $_baseMusicDir');

    try {
      _notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings(_notificationIcon);
      const initSettings = InitializationSettings(android: androidSettings);
      await _notifications!.initialize(settings: initSettings);
    } catch (e) {
      debugPrint('Notifications init failed: $e');
      _notifications = null;
    }
    await _db.requeueInterruptedTasks();
    await _publishExistingAndroidDownloads();
    await _relocatePendingTasks();
    _initialized = true;
    unawaited(processQueue());
  }

  String get baseMusicDir => _baseMusicDir;
  Future<void> setDownloadPath(String path) async {
    await _waitForInitialization();
    if (Platform.isAndroid) return;
    final managedPath = _managedDownloadPath(path);
    _baseMusicDir = managedPath;
    _workingMusicDir = managedPath;
    await _relocatePendingTasks();
  }

  Future<void> setAndroidDownloadLocation(String location) async {
    await _waitForInitialization();
    if (!Platform.isAndroid) return;
    if (location == 'custom') {
      final customPath = await _customAndroidDownloadLocationPath();
      if (customPath == null) {
        throw const FileSystemException(
          'Choose a custom download folder first.',
        );
      }
      _androidDownloadLocation = 'custom';
      _baseMusicDir = customPath;
      return;
    }
    _androidDownloadLocation = location == 'downloads' ? 'downloads' : 'music';
    _baseMusicDir = await _publicAndroidDownloadLocationPath();
  }

  Future<String?> selectAndroidCustomDownloadLocation() async {
    await _waitForInitialization();
    if (!Platform.isAndroid) return null;
    final result = await _mediaChannel.invokeMapMethod<String, dynamic>(
      'selectCustomDownloadLocation',
    );
    final path = result?['path'] as String?;
    if (path == null || path.isEmpty) return null;
    _androidDownloadLocation = 'custom';
    _baseMusicDir = path;
    return path;
  }

  Future<void> setAndroidCustomLocationUsesGanneFolder(bool value) async {
    await _waitForInitialization();
    if (!Platform.isAndroid) return;
    await _mediaChannel.invokeMethod<void>('setCustomDownloadFolderMode', {
      'useGanneFolder': value,
    });
    if (_androidDownloadLocation == 'custom') {
      final customPath = await _customAndroidDownloadLocationPath();
      if (customPath == null) {
        throw const FileSystemException(
          'The selected custom download folder is no longer available.',
        );
      }
      _baseMusicDir = customPath;
    }
  }

  Future<void> setFlatDownloads(bool value) async {
    await _waitForInitialization();
    _flatDownloads = value;
    await _relocatePendingTasks();
  }

  Future<void> _waitForInitialization() async {
    final initialization = _initialization;
    if (initialization == null) {
      throw StateError('Download service has not been initialized.');
    }
    await initialization;
  }

  Future<void> _relocatePendingTasks() async {
    final tasks = await _db.getAllTasks();
    for (final task in tasks.where((task) => task.status == 'pending')) {
      final relativeDirectory = relativeTrackDirectory(
        task.artistName,
        task.albumTitle,
        flat: _flatDownloads,
      );
      final savePath = relativeDirectory.isEmpty
          ? _workingMusicDir
          : p.join(_workingMusicDir, relativeDirectory);
      if (task.savePath != savePath) {
        await _db.updateTask(task.copyWith(savePath: drift.Value(savePath)));
      }
    }
  }

  Future<void> _publishExistingAndroidDownloads() async {
    if (!Platform.isAndroid || _workingMusicDir == _baseMusicDir) return;
    final tasks = await _db.getAllTasks();
    for (final task in tasks.where(
      (task) => task.status == 'completed' || task.status == 'library',
    )) {
      final oldPath = task.savePath;
      if (oldPath == null || !p.isWithin(_workingMusicDir, oldPath)) continue;
      final source = File(oldPath);
      if (!await source.exists()) continue;

      try {
        final relativeDirectory = _relativeDirectoryForPublish(
          p.dirname(oldPath),
        );
        final publishedPath = await _publishAndroidFile(
          source,
          relativeDirectory: relativeDirectory,
          mimeType: _mimeTypeForExtension(p.extension(oldPath)),
        );
        await _db.updateTask(
          task.copyWith(savePath: drift.Value(publishedPath)),
        );
      } catch (e) {
        debugPrint(
          'Unable to publish existing download ${task.trackTitle}: $e',
        );
      }
    }
  }

  /// Format artist string: "A & B" or "A, B & C"
  static String joinArtists(List<String>? artists, {String? fallback}) {
    if (artists == null || artists.isEmpty) return fallback ?? 'Unknown';
    if (artists.length == 1) return artists[0];
    if (artists.length == 2) return '${artists[0]} & ${artists[1]}';

    final list = List<String>.from(artists);
    final last = list.removeLast();
    return '${list.join(', ')} & $last';
  }

  static String artistNameForTrack(QobuzTrack track, {QobuzAlbum? album}) {
    return track.performer?.name ??
        joinArtists(
          track.album?.artists?.map((artist) => artist.name).toList() ??
              album?.artists?.map((artist) => artist.name).toList(),
          fallback:
              track.album?.artist?.name ?? album?.artist?.name ?? 'Unknown',
        );
  }

  /// Format file name as "[Artist] - [Title] ([Version]).ext"
  static String formatFileName(
    String artistName,
    String trackTitle,
    String? version,
    String ext,
  ) {
    final artist = _sanitizePathComponent(
      artistName,
      fallback: 'Unknown Artist',
    );
    final title = _sanitizePathComponent(trackTitle, fallback: 'Unknown Title');
    final cleanedVersion = version == null
        ? null
        : _sanitizePathComponent(version, fallback: '');
    final titleWithVersion = cleanedVersion != null && cleanedVersion.isNotEmpty
        ? '$title ($cleanedVersion)'
        : title;
    final extension = ext.startsWith('.') ? ext : '.$ext';
    return '$artist - $titleWithVersion$extension';
  }

  static String _sanitizePathComponent(
    String value, {
    required String fallback,
  }) {
    final sanitized = value
        .replaceAll(RegExp(r'[\x00-\x1F\\/:*?"<>|]'), '')
        .trim()
        .replaceFirst(RegExp(r'[. ]+$'), '');
    final isReservedWindowsName = RegExp(
      r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
      caseSensitive: false,
    ).hasMatch(sanitized);
    if (sanitized.isEmpty ||
        sanitized == '.' ||
        sanitized == '..' ||
        isReservedWindowsName) {
      return fallback;
    }
    return sanitized;
  }

  static String _managedDownloadPath(String selectedPath) {
    final normalized = p.normalize(selectedPath);
    if (p.basename(normalized).toLowerCase() == 'ganne') return normalized;
    return p.join(normalized, 'Ganne');
  }

  static String relativeTrackDirectory(
    String artistName,
    String albumTitle, {
    required bool flat,
  }) {
    if (flat) return '';
    return p.join(
      _sanitizePathComponent(artistName, fallback: 'Unknown Artist'),
      _sanitizePathComponent(albumTitle, fallback: 'Unknown Album'),
    );
  }

  /// Determine the correct file extension from the MIME type returned by the
  /// Qobuz API. Falls back to the quality-based guess when the MIME type is
  /// absent or unrecognised.
  static String extensionFromMime(String? mimeType, String qualityId) {
    final normalizedMime = mimeType?.split(';').first.trim().toLowerCase();
    switch (normalizedMime) {
      case 'audio/flac':
      case 'audio/x-flac':
        return '.flac';
      case 'audio/mpeg':
      case 'audio/mp3':
        return '.mp3';
      case 'audio/mp4':
      case 'audio/aac':
      case 'audio/x-m4a':
      case 'audio/m4a':
        return '.m4a';
      case 'audio/wav':
      case 'audio/x-wav':
        return '.wav';
      case 'audio/vorbis':
      case 'audio/ogg':
        return '.ogg';
      default:
        return qualityId == '5' ? '.mp3' : '.flac';
    }
  }

  static String? detectExtensionFromBytes(Uint8List header) {
    if (header.length >= 4 &&
        header[0] == 0x66 &&
        header[1] == 0x4C &&
        header[2] == 0x61 &&
        header[3] == 0x43) {
      return '.flac';
    }
    if (header.length >= 8 &&
        header[4] == 0x66 &&
        header[5] == 0x74 &&
        header[6] == 0x79 &&
        header[7] == 0x70) {
      return '.m4a';
    }
    if (header.length >= 3 &&
        header[0] == 0x49 &&
        header[1] == 0x44 &&
        header[2] == 0x33) {
      return '.mp3';
    }
    if (header.length >= 2 && header[0] == 0xFF && (header[1] & 0xF6) == 0xF0) {
      return '.aac';
    }
    if (header.length >= 2 &&
        header[0] == 0xFF &&
        (header[1] & 0xE0) == 0xE0 &&
        (header[1] & 0x18) != 0x08 &&
        (header[1] & 0x06) != 0) {
      return '.mp3';
    }
    if (header.length >= 4 &&
        header[0] == 0x4F &&
        header[1] == 0x67 &&
        header[2] == 0x67 &&
        header[3] == 0x53) {
      return '.ogg';
    }
    if (header.length >= 12 &&
        header[0] == 0x52 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x46 &&
        header[8] == 0x57 &&
        header[9] == 0x41 &&
        header[10] == 0x56 &&
        header[11] == 0x45) {
      return '.wav';
    }
    return null;
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
    String? isrc,
    String? albumArtist,
    int? trackNumber,
    int? discNumber,
    int? totalTracks,
    int? totalDiscs,
    int? durationSeconds,
    int? year,
    String? genre,
    String? copyright,
    String? label,
    String? barcode,
  }) async {
    await _waitForInitialization();
    final completion = Completer<void>();
    final operation = completion.future;
    _queueOperations.add(operation);
    try {
      if (_isResetting) {
        throw StateError('Library storage is being reset.');
      }
      if (!_queueingTrackIds.add(trackId)) return 'already_in_queue';

      try {
        if (await _db.isTrackInQueue(trackId)) {
          return 'already_in_queue';
        }
        if (await _db.isTrackCompleted(trackId)) {
          return 'already_downloaded';
        }

        final relativeDirectory = relativeTrackDirectory(
          artistName,
          albumTitle,
          flat: _flatDownloads,
        );
        final savePath = relativeDirectory.isEmpty
            ? _workingMusicDir
            : p.join(_workingMusicDir, relativeDirectory);

        await _db.insertTask(
          DownloadTasksCompanion.insert(
            trackId: trackId,
            trackTitle: trackTitle,
            albumTitle: albumTitle,
            artistName: artistName,
            albumArtist: drift.Value(albumArtist),
            trackVersion: drift.Value(trackVersion),
            isrc: drift.Value(isrc),
            trackNumber: drift.Value(trackNumber),
            discNumber: drift.Value(discNumber),
            totalTracks: drift.Value(totalTracks),
            totalDiscs: drift.Value(totalDiscs),
            durationSeconds: drift.Value(durationSeconds),
            year: drift.Value(year),
            genre: drift.Value(genre),
            copyright: drift.Value(copyright),
            label: drift.Value(label),
            barcode: drift.Value(barcode),
            coverUrl: coverUrl,
            quality: quality,
            addedAt: DateTime.now().millisecondsSinceEpoch,
            savePath: drift.Value(savePath),
          ),
        );
        unawaited(processQueue());
        return 'queued';
      } finally {
        _queueingTrackIds.remove(trackId);
      }
    } finally {
      _queueOperations.remove(operation);
      completion.complete();
    }
  }

  Future<void> processQueue() async {
    if (!_initialized || _isProcessing || _isResetting) return;
    _isProcessing = true;

    try {
      final initialTasks = await _db.getAllTasks();
      if (!initialTasks.any((task) => task.status == 'pending')) return;

      await PermissionService.requestNotificationPermission();

      while (!_isResetting && _activeTasks.length < _maxConcurrent) {
        final tasks = await _db.getAllTasks();
        final pending = tasks
            .where(
              (task) =>
                  task.status == 'pending' &&
                  !_activeTasks.containsKey(task.id),
            )
            .toList();
        if (pending.isEmpty) break;
        _startTask(pending.first);
      }
    } catch (e, stack) {
      debugPrint('Unable to process download queue: $e\n$stack');
    } finally {
      _isProcessing = false;
    }
  }

  void _startTask(DownloadTask task) {
    final future = _downloadTask(task);
    _activeTasks[task.id] = future;
    unawaited(_observeTask(task.id, future));
  }

  Future<void> _observeTask(int taskId, Future<void> task) async {
    try {
      await task;
    } catch (e, stack) {
      debugPrint('Unhandled download task error: $e\n$stack');
    } finally {
      _activeTasks.remove(taskId);
      if (!_isResetting) unawaited(processQueue());
    }
  }

  Future<void> _downloadTask(DownloadTask task) async {
    String? localTempPath;
    File? localAudioFile;
    File? outputTempFile;
    File? outputFile;
    ResolvedTrackMetadata? resolvedMetadata;
    final cancelToken = CancelToken();
    _cancelTokens[task.trackId] = cancelToken;

    try {
      await _ensureAndroidStoragePermission();
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

      final downloadInfo = await _qobuzService.getDownloadUrl(
        task.trackId,
        task.quality,
      );
      _throwIfCancelled(cancelToken);
      final fileUrl = downloadInfo.url;

      final savePath = task.savePath;
      if (savePath == null || savePath.isEmpty) throw Exception('No save path');
      final saveDir = Directory(savePath);
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      // Use the MIME type from the API as the primary source for extension
      var ext = extensionFromMime(downloadInfo.mimeType, task.quality);
      debugPrint('MIME from API: ${downloadInfo.mimeType} → extension: $ext');

      final tempDir = await getTemporaryDirectory();
      var localFinalPath = p.join(tempDir.path, 'download_${task.trackId}$ext');
      localTempPath = '$localFinalPath.part';
      int lastNotifiedPercent = -1;
      int lastUpdateTime = 0;

      await _downloadWithRetries(
        fileUrl,
        localTempPath,
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

      final localTempFile = File(localTempPath);
      final raf = await localTempFile.open(mode: FileMode.read);
      late Uint8List headerBytes;
      try {
        headerBytes = await raf.read(12);
      } finally {
        await raf.close();
      }
      final detectedExt = detectExtensionFromBytes(headerBytes);
      if (detectedExt == null) {
        throw const FormatException(
          'Downloaded file is not a supported audio format.',
        );
      }
      if (detectedExt != ext) {
        debugPrint(
          'Magic-byte mismatch! Expected $ext but detected $detectedExt. '
          'Correcting file extension.',
        );
        ext = detectedExt;
        localFinalPath = p.join(tempDir.path, 'download_${task.trackId}$ext');
      }

      localAudioFile = await localTempFile.rename(localFinalPath);

      final applyMetadataRaw = await _secureStorage.readKey('setting_metadata');
      final shouldApplyMetadata = applyMetadataRaw != 'false';

      if (shouldApplyMetadata) {
        try {
          final metadata = await _resolveTrackMetadata(task);
          resolvedMetadata = metadata;
          _throwIfCancelled(cancelToken);
          await _applyMetadata(localAudioFile, metadata);
        } catch (e) {
          debugPrint('Failed to apply metadata: $e');
        }
      }

      _throwIfCancelled(cancelToken);
      final fileName = formatFileName(
        task.artistName,
        task.trackTitle,
        task.trackVersion,
        ext,
      );
      outputTempFile = await _reserveOutputFile(saveDir, fileName);
      await _copyFile(localAudioFile, outputTempFile);
      _throwIfCancelled(cancelToken);
      var finalPath = _finalPathFor(outputTempFile);
      outputFile = await outputTempFile.rename(finalPath);
      outputTempFile = null;

      if (Platform.isAndroid) {
        finalPath = await _publishAndroidFile(
          outputFile,
          relativeDirectory: _relativeDirectoryForPublish(saveDir.path),
          mimeType: _mimeTypeForExtension(ext),
        );
        outputFile = File(finalPath);
      }

      try {
        await localAudioFile.delete();
      } catch (_) {}

      await _db.updateTask(
        (resolvedMetadata?.persistedTask ?? task).copyWith(
          status: 'completed',
          quality: ext == '.mp3' ? '5' : task.quality,
          savePath: drift.Value(finalPath),
        ),
      );
      outputFile = null;
      _updateProgress(task.trackId, 1.0);
      _showCompletionNotification(task.id, task.trackTitle);
      if (identical(_cancelTokens[task.trackId], cancelToken)) {
        _cancelTokens.remove(task.trackId);
      }

      if (_activeInfo?.trackId == task.trackId) {
        _setActiveInfo(null);
      }
    } catch (e) {
      await _deletePathIfPresent(localTempPath);
      await _deletePathIfPresent(localAudioFile?.path);
      await _deletePathIfPresent(outputTempFile?.path);
      await _deleteOutputIfPresent(outputFile?.path);

      final wasCancelled =
          cancelToken.isCancelled ||
          (e is DioException && e.type == DioExceptionType.cancel);
      try {
        await _db.updateTask(task.copyWith(status: 'failed'));
      } catch (dbError) {
        debugPrint('Unable to record failed download: $dbError');
      }
      _updateProgress(task.trackId, -1.0);
      if (!wasCancelled) {
        debugPrint('Download failed for ${task.trackTitle}: $e');
        _showErrorNotification(task.id, task.trackTitle);
      }
    } finally {
      if (identical(_cancelTokens[task.trackId], cancelToken)) {
        _cancelTokens.remove(task.trackId);
      }
    }
  }

  Future<void> _downloadWithRetries(
    String url,
    String savePath, {
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    DioException? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _downloadDio.download(
          url,
          savePath,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
        return;
      } on DioException catch (e) {
        if (cancelToken?.isCancelled == true ||
            e.type == DioExceptionType.cancel) {
          rethrow;
        }
        lastError = e;
        await _deletePathIfPresent(savePath);
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      }
    }
    throw lastError ?? StateError('Download failed without an error response.');
  }

  void _throwIfCancelled(CancelToken cancelToken) {
    if (cancelToken.isCancelled) {
      throw StateError('Download cancelled.');
    }
  }

  Future<File> _reserveOutputFile(Directory directory, String fileName) async {
    final extension = p.extension(fileName);
    final name = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);

    for (var suffix = 0; suffix < 1000; suffix++) {
      final candidateName = suffix == 0
          ? fileName
          : '$name ($suffix)$extension';
      final outputFile = File(p.join(directory.path, candidateName));
      if (await outputFile.exists()) continue;

      final tempFile = File('${outputFile.path}.part');
      if (await tempFile.exists()) continue;
      try {
        await tempFile.create(exclusive: true);
        return tempFile;
      } on FileSystemException {
        if (await tempFile.exists()) continue;
        rethrow;
      }
    }

    throw FileSystemException('Unable to reserve an output file name.');
  }

  String _finalPathFor(File tempFile) {
    const temporarySuffix = '.part';
    if (!tempFile.path.endsWith(temporarySuffix)) {
      throw StateError('Expected a reserved temporary output file.');
    }
    return tempFile.path.substring(
      0,
      tempFile.path.length - temporarySuffix.length,
    );
  }

  Future<void> _copyFile(File source, File destination) async {
    final sink = destination.openWrite(mode: FileMode.write);
    try {
      await sink.addStream(source.openRead());
    } finally {
      await sink.close();
    }
  }

  Future<void> _deletePathIfPresent(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Temporary file cleanup failed: $e');
    }
  }

  Future<void> _deleteTemporaryArtifacts() async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (!name.startsWith('download_') && !name.startsWith('ganne_zip_')) {
        continue;
      }
      try {
        await entity.delete(recursive: true);
      } catch (e) {
        debugPrint('Temporary artifact cleanup failed for ${entity.path}: $e');
      }
    }
  }

  Future<void> _ensureAndroidStoragePermission() async {
    if (!Platform.isAndroid) return;
    final needsPermission =
        await _mediaChannel.invokeMethod<bool>(
          'needsLegacyStoragePermission',
        ) ??
        false;
    if (needsPermission &&
        !await PermissionService.requestLegacyStoragePermission()) {
      throw const FileSystemException(
        'Storage permission is required to save music.',
      );
    }
  }

  Future<String> _publicAndroidDownloadLocationPath() async {
    return await _mediaChannel.invokeMethod<String>('getPublicDownloadPath', {
          'location': _androidDownloadLocation,
        }) ??
        _workingMusicDir;
  }

  Future<String?> _customAndroidDownloadLocationPath() async {
    try {
      final result = await _mediaChannel.invokeMapMethod<String, dynamic>(
        'getCustomDownloadLocation',
      );
      final path = result?['path'] as String?;
      return path == null || path.isEmpty ? null : path;
    } on PlatformException catch (e) {
      debugPrint('Unable to access custom download location: $e');
      return null;
    }
  }

  Future<String> _publishAndroidFile(
    File source, {
    required String relativeDirectory,
    required String mimeType,
  }) async {
    final result = await _mediaChannel
        .invokeMapMethod<String, dynamic>('publishFile', {
          'sourcePath': source.path,
          'displayName': p.basename(source.path),
          'relativeDirectory': relativeDirectory.replaceAll('\\', '/'),
          'mimeType': mimeType,
          'location': _androidDownloadLocation,
        });
    final publishedPath = result?['path'] as String?;
    if (publishedPath == null || publishedPath.isEmpty) {
      throw const FileSystemException('Android did not return a saved path.');
    }
    try {
      await source.delete();
    } catch (e) {
      debugPrint('Unable to remove private download copy: $e');
    }
    return publishedPath;
  }

  String _relativeDirectoryForPublish(String directoryPath) {
    final relative = p.relative(directoryPath, from: _workingMusicDir);
    return relative == '.' ? '' : relative;
  }

  static String _mimeTypeForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      case '.aac':
        return 'audio/aac';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.zip':
        return 'application/zip';
      default:
        return 'audio/flac';
    }
  }

  Future<void> _deleteOutputIfPresent(String? path) async {
    if (path == null) return;
    if (Platform.isAndroid) {
      await deleteDownloadedFile(path);
    } else {
      await _deletePathIfPresent(path);
    }
  }

  Future<bool> deleteDownloadedFile(String? path) async {
    if (path == null || path.isEmpty) return false;
    try {
      final deleted = Platform.isAndroid
          ? await _mediaChannel.invokeMethod<bool>('deleteFile', {
                  'path': path,
                }) ??
                false
          : await _deleteLocalFile(path);
      if (deleted && !path.startsWith('content://')) {
        await deleteEmptyDirs(path);
      }
      return deleted;
    } catch (e) {
      debugPrint('Unable to delete downloaded file $path: $e');
      return false;
    }
  }

  Future<bool> _deleteLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  Future<bool> openDownloadedFile(String path) async {
    if (!Platform.isAndroid || !path.startsWith('content://')) return false;
    try {
      return await _mediaChannel.invokeMethod<bool>('openDocument', {
            'uri': path,
          }) ??
          false;
    } on PlatformException catch (e) {
      debugPrint('Unable to open custom download $path: $e');
      return false;
    }
  }

  Future<ResolvedTrackMetadata> _resolveTrackMetadata(DownloadTask task) async {
    MusicBrainzMetadata? musicBrainz;
    try {
      musicBrainz = await _musicBrainzService.resolveTrack(
        isrc: task.isrc,
        title: task.trackTitle,
        artist: task.artistName,
        album: task.albumTitle,
        albumArtist: task.albumArtist,
        durationSeconds: task.durationSeconds,
        year: task.year,
        trackNumber: task.trackNumber,
        discNumber: task.discNumber,
        totalTracks: task.totalTracks,
        totalDiscs: task.totalDiscs,
        barcode: task.barcode,
      );
    } catch (e) {
      debugPrint('MusicBrainz lookup failed: $e');
    }

    MusicBrainzCoverArt? coverArt;
    final releaseId = musicBrainz?.releaseId;
    if (releaseId != null && musicBrainz?.hasFrontCover == true) {
      coverArt = await _musicBrainzService.fetchCoverArt(releaseId);
    }
    if (coverArt == null && task.coverUrl.isNotEmpty) {
      final fullResolutionUrl = fullResolutionCoverUrl(task.coverUrl);
      coverArt = await _musicBrainzService.fetchImage(fullResolutionUrl);
    }

    return ResolvedTrackMetadata(
      task: task,
      musicBrainz: musicBrainz,
      coverArt: coverArt,
    );
  }

  static String fullResolutionCoverUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return url;
    final segments = List<String>.from(uri.pathSegments);
    if (RegExp(r'^\d+\.jpg$', caseSensitive: false).hasMatch(segments.last)) {
      segments[segments.length - 1] = 'org.jpg';
      return uri.replace(pathSegments: segments).toString();
    }
    return url;
  }

  Future<void> _applyMetadata(
    File audioFile,
    ResolvedTrackMetadata metadata,
  ) async {
    try {
      if (audioFile.path.endsWith('.flac')) {
        await FlacTagger.writeTags(
          filePath: audioFile.path,
          tags: metadata.flacTags,
          coverBytes: metadata.coverArt?.bytes,
          coverMimeType: metadata.coverArt?.mimeType,
        );
      } else {
        final tag = Tag(
          title: metadata.title,
          trackArtist: metadata.artist,
          album: metadata.album,
          albumArtist: metadata.albumArtist,
          trackNumber: metadata.trackNumber,
          trackTotal: metadata.totalTracks,
          discNumber: metadata.discNumber,
          discTotal: metadata.totalDiscs,
          year: metadata.year,
          genre: metadata.genre,
          pictures: metadata.coverArt != null
              ? [
                  Picture(
                    bytes: metadata.coverArt!.bytes,
                    mimeType: _pictureMimeType(metadata.coverArt!.mimeType),
                    pictureType: PictureType.coverFront,
                  ),
                ]
              : [],
        );
        await AudioTags.write(audioFile.path, tag);
      }
    } catch (e) {
      debugPrint('Metadata apply error: $e');
    }
  }

  static MimeType? _pictureMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return MimeType.jpeg;
      case 'image/png':
        return MimeType.png;
      case 'image/tiff':
        return MimeType.tiff;
      case 'image/bmp':
        return MimeType.bmp;
      case 'image/gif':
        return MimeType.gif;
      default:
        return null;
    }
  }

  static String _coverExtension(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/tiff':
        return '.tiff';
      case 'image/bmp':
        return '.bmp';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      default:
        return '.jpg';
    }
  }

  int _nextZipId() {
    _zipSequence = (_zipSequence + 1) % 1000;
    return (DateTime.now().millisecondsSinceEpoch % 2000000000) + _zipSequence;
  }

  Future<void> downloadAlbumAsZip({
    required QobuzAlbum album,
    required FetchedAlbumResponse fetchedData,
    required String qualityId,
  }) async {
    await _waitForInitialization();
    if (_isResetting) {
      throw StateError('Library storage is being reset.');
    }
    if (_isZipping) {
      throw StateError('Another album archive is already being created.');
    }

    _isZipping = true;
    final completion = Completer<void>();
    _zipCompletion = completion;
    final zipCancelToken = CancelToken();
    _zipCancelToken = zipCancelToken;
    final startId = _nextZipId();
    Directory? albumTempDir;
    File? outputTempFile;
    File? outputZipFile;
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
      await _ensureAndroidStoragePermission();
      await PermissionService.requestNotificationPermission();

      final albumInfo = fetchedData.album ?? album;
      final sanitizedArtist = _sanitizePathComponent(
        albumInfo.artist?.name ?? 'Unknown Artist',
        fallback: 'Unknown Artist',
      );
      final sanitizedAlbum = _sanitizePathComponent(
        album.title,
        fallback: 'Unknown Album',
      );

      final saveDir = Directory(p.join(_workingMusicDir, sanitizedArtist));
      debugPrint('[ZIP] Save directory: ${saveDir.path}');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);

      outputTempFile = await _reserveOutputFile(saveDir, '$sanitizedAlbum.zip');
      final zipPath = _finalPathFor(outputTempFile);
      debugPrint('[ZIP] Zip output path: $zipPath');

      final tempDir = await getTemporaryDirectory();
      final tempAlbumDir = Directory(
        p.join(tempDir.path, 'ganne_zip_$startId'),
      );
      albumTempDir = tempAlbumDir;
      if (await tempAlbumDir.exists()) {
        await tempAlbumDir.delete(recursive: true);
      }
      await tempAlbumDir.create(recursive: true);
      debugPrint('[ZIP] Temp directory: ${tempAlbumDir.path}');

      final tracks = fetchedData.tracks?.items ?? [];
      debugPrint('[ZIP] Total tracks to download: ${tracks.length}');
      if (tracks.isEmpty) {
        throw StateError('No tracks found in the selected album.');
      }
      final shouldApplyMetadata =
          await _secureStorage.readKey('setting_metadata') != 'false';

      File? coverFile;
      final coverUrl = albumInfo.getCoverLargeUrl();

      int completed = 0;
      final downloadedFiles = <File>[];
      final failedTracks = <String>[];

      for (var index = 0; index < tracks.length; index++) {
        final track = tracks[index];
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
          if (zipCancelToken.isCancelled) {
            throw StateError('ZIP download cancelled.');
          }
          debugPrint(
            '[ZIP] Downloading track ${completed + 1}/${tracks.length}: ${track.title}',
          );
          final downloadInfo = await _qobuzService.getDownloadUrl(
            track.id,
            qualityId,
          );
          debugPrint('[ZIP] Got download URL for track ${track.id}');

          // Determine correct extension from MIME type
          var trackExt = extensionFromMime(downloadInfo.mimeType, qualityId);

          final artistName = artistNameForTrack(track, album: albumInfo);
          final trackPrefix =
              '${(track.mediaNumber ?? 1).toString().padLeft(2, '0')}-'
              '${(track.trackNumber ?? index + 1).toString().padLeft(2, '0')} ';
          var tempTrackPath = p.join(
            tempAlbumDir.path,
            '$trackPrefix${formatFileName(artistName, track.title, track.version, trackExt)}',
          );

          await _downloadWithRetries(
            downloadInfo.url,
            tempTrackPath,
            cancelToken: zipCancelToken,
          );

          final raf = await File(tempTrackPath).open(mode: FileMode.read);
          late Uint8List headerBytes;
          try {
            headerBytes = await raf.read(12);
          } finally {
            await raf.close();
          }
          final detectedExt = detectExtensionFromBytes(headerBytes);
          if (detectedExt == null) {
            throw FormatException(
              'Downloaded file for ${track.title} is not supported audio.',
            );
          }
          if (detectedExt != trackExt) {
            debugPrint(
              '[ZIP] Magic-byte mismatch for ${track.title}: '
              'expected $trackExt, detected $detectedExt. Renaming.',
            );
            final correctedPath = p.join(
              tempAlbumDir.path,
              '$trackPrefix${formatFileName(artistName, track.title, track.version, detectedExt)}',
            );
            await File(tempTrackPath).rename(correctedPath);
            tempTrackPath = correctedPath;
            trackExt = detectedExt;
          }

          final downloadedFile = File(tempTrackPath);
          final fileSize = await downloadedFile.length();
          debugPrint(
            '[ZIP] Track downloaded: $tempTrackPath ($fileSize bytes)',
          );

          if (fileSize <= 0) {
            throw StateError('Downloaded file for ${track.title} is empty.');
          }
          downloadedFiles.add(downloadedFile);

          try {
            final task = DownloadTask(
              id: 0,
              trackId: track.id,
              trackTitle: track.title,
              albumTitle: albumInfo.title,
              artistName: artistName,
              coverUrl: coverUrl,
              quality: qualityId,
              status: 'completed',
              addedAt: 0,
              totalBytes: 0,
              downloadedBytes: 0,
              albumArtist: albumInfo.artist?.name ?? artistName,
              trackVersion: track.version ?? albumInfo.version,
              isrc: track.isrc,
              trackNumber: track.trackNumber,
              discNumber: track.mediaNumber,
              totalTracks: albumInfo.tracksCount ?? tracks.length,
              totalDiscs: albumInfo.mediaCount,
              durationSeconds: track.duration,
              year: albumInfo.releasedAt != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      albumInfo.releasedAt! * 1000,
                    ).year
                  : null,
              genre: albumInfo.genre?.name,
              copyright: albumInfo.copyright,
              label: albumInfo.label,
              barcode: albumInfo.upc,
            );
            ResolvedTrackMetadata? metadata;
            if (shouldApplyMetadata || coverFile == null) {
              metadata = await _resolveTrackMetadata(task);
              _throwIfCancelled(zipCancelToken);
            }
            final coverArt = metadata?.coverArt;
            if (coverFile == null && coverArt != null) {
              coverFile = File(
                p.join(
                  tempAlbumDir.path,
                  'cover${_coverExtension(coverArt.mimeType)}',
                ),
              );
              await coverFile.writeAsBytes(coverArt.bytes, flush: true);
            }
            if (shouldApplyMetadata && metadata != null) {
              await _applyMetadata(downloadedFile, metadata);
              debugPrint('[ZIP] Metadata applied for: ${track.title}');
            }
          } catch (e) {
            debugPrint('[ZIP] Metadata error for ${track.title}: $e');
          }
        } catch (e) {
          if (zipCancelToken.isCancelled) rethrow;
          failedTracks.add(track.title);
          debugPrint('[ZIP] FAILED to download track ${track.title}: $e');
        }
        completed++;
      }

      debugPrint(
        '[ZIP] Downloaded ${downloadedFiles.length} files successfully',
      );

      _throwIfCancelled(zipCancelToken);
      if (failedTracks.isNotEmpty || downloadedFiles.length != tracks.length) {
        throw StateError(
          'Failed to download ${failedTracks.length} of ${tracks.length} tracks.',
        );
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
      final tempZipPath = p.join(tempAlbumDir.path, '$sanitizedAlbum.zip');
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
      _throwIfCancelled(zipCancelToken);

      final tempZipFile = File(tempZipPath);
      final tempZipSize = await tempZipFile.length();
      debugPrint('[ZIP] Temp zip created: $tempZipPath ($tempZipSize bytes)');

      debugPrint('[ZIP] Copying zip to final path: $zipPath');
      await _copyFile(tempZipFile, outputTempFile);
      _throwIfCancelled(zipCancelToken);
      outputZipFile = await outputTempFile.rename(zipPath);
      outputTempFile = null;

      var publishedZipPath = zipPath;
      if (Platform.isAndroid) {
        publishedZipPath = await _publishAndroidFile(
          outputZipFile,
          relativeDirectory: sanitizedArtist,
          mimeType: 'application/zip',
        );
        outputZipFile = null;
      }

      final finalZipSize = Platform.isAndroid
          ? tempZipSize
          : await outputZipFile!.length();
      debugPrint(
        '[ZIP] Final zip copied: $publishedZipPath ($finalZipSize bytes)',
      );

      await tempAlbumDir.delete(recursive: true);
      albumTempDir = null;

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
      outputZipFile = null;

      await Future.delayed(const Duration(seconds: 2));
    } catch (e, stack) {
      debugPrint('[ZIP] FATAL ERROR: $e');
      debugPrint('[ZIP] Stack: $stack');
      await _deletePathIfPresent(outputTempFile?.path);
      await _deleteOutputIfPresent(outputZipFile?.path);
      _updateProgress(startId, -1.0);
      if (!zipCancelToken.isCancelled) {
        _showErrorNotification(startId, 'ZIP Failed: ${album.title}');
      }
      rethrow;
    } finally {
      if (albumTempDir != null) {
        try {
          if (await albumTempDir.exists()) {
            await albumTempDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint('[ZIP] Temp cleanup failed: $e');
        }
      }
      if (identical(_zipCancelToken, zipCancelToken)) {
        _zipCancelToken = null;
      }
      if (identical(_zipCompletion, completion)) {
        _zipCompletion = null;
        completion.complete();
      }
      _isZipping = false;
      _setActiveInfo(null);
    }
  }

  void cancelDownload(int trackId) {
    _cancelTokens[trackId]?.cancel('User cancelled');
    _cancelTokens.remove(trackId);
  }

  Future<void> removeTask(DownloadTask task) async {
    cancelDownload(task.trackId);
    final activeTask = _activeTasks[task.id];
    if (activeTask != null) {
      try {
        await activeTask;
      } catch (_) {}
    }
    await _db.deleteTask(task.id);
    _currentProgress.remove(task.trackId);
    _progressController.add(Map.from(_currentProgress));
    if (_activeInfo?.trackId == task.trackId) _setActiveInfo(null);
  }

  void cancelAll() {
    for (final token in _cancelTokens.values) {
      token.cancel('User cancelled all');
    }
    _cancelTokens.clear();
    _zipCancelToken?.cancel('User cancelled all');
  }

  Future<void> deleteEmptyDirs(String filePath) async {
    try {
      final baseDir = p.normalize(_baseMusicDir);
      final normalizedFilePath = p.normalize(filePath);
      if (!p.isWithin(baseDir, normalizedFilePath)) return;
      var currentDir = Directory(p.dirname(normalizedFilePath));

      while (p.isWithin(baseDir, currentDir.path)) {
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

  Future<void> resetLibraryStorage({
    Future<void> Function()? onStopPlayer,
  }) async {
    await _waitForInitialization();
    if (_isResetting) return;
    _isResetting = true;

    cancelAll();
    try {
      await Future.wait(_queueOperations.toList());
      final activeTasks = _activeTasks.values.toList();
      await Future.wait(
        activeTasks.map((task) async {
          try {
            await task;
          } catch (_) {}
        }),
      );
      final zipTask = _zipCompletion?.future;
      if (zipTask != null) {
        try {
          await zipTask;
        } catch (_) {}
      }

      if (onStopPlayer != null) await onStopPlayer();
      await _deleteTemporaryArtifacts();

      final tasks = await _db.getAllTasks();
      if (Platform.isAndroid) {
        for (final task in tasks.where(
          (task) => task.status == 'completed' || task.status == 'library',
        )) {
          await deleteDownloadedFile(task.savePath);
        }
        await _mediaChannel.invokeMethod<int>('deleteAllPublished');
      } else {
        for (final task in tasks.where(
          (task) => task.status == 'completed' || task.status == 'library',
        )) {
          await _deletePathIfPresent(task.savePath);
        }
      }

      final dir = Directory(_workingMusicDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint(
          'Successfully deleted music folder recursively: $_workingMusicDir',
        );
      }
      await dir.create(recursive: true);
      await _db.clearAllTasks();
      _currentProgress.clear();
      _progressController.add({});
    } finally {
      _setActiveInfo(null);
      _isResetting = false;
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
          icon: _notificationIcon,
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
          icon: _notificationIcon,
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
          icon: _notificationIcon,
          channelDescription: 'Active Downloads',
          importance: Importance.defaultImportance,
        ),
      ),
    );
  }
}

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
      await encoder.addFile(coverFile, p.basename(coverFile.path));
    }
  }

  encoder.close();
}
