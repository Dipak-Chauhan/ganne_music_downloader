import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class MusicBrainzMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? date;
  final String? originalDate;
  final String? genre;
  final String? isrc;
  final int? trackNumber;
  final int? totalTracks;
  final int? discNumber;
  final int? totalDiscs;
  final String? recordingId;
  final String? releaseTrackId;
  final String? releaseId;
  final String? releaseGroupId;
  final List<String> artistIds;
  final List<String> albumArtistIds;
  final String? barcode;
  final String? label;
  final String? catalogNumber;
  final String? releaseCountry;
  final String? releaseStatus;
  final String? releaseType;
  final bool hasFrontCover;

  const MusicBrainzMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.date,
    this.originalDate,
    this.genre,
    this.isrc,
    this.trackNumber,
    this.totalTracks,
    this.discNumber,
    this.totalDiscs,
    this.recordingId,
    this.releaseTrackId,
    this.releaseId,
    this.releaseGroupId,
    this.artistIds = const [],
    this.albumArtistIds = const [],
    this.barcode,
    this.label,
    this.catalogNumber,
    this.releaseCountry,
    this.releaseStatus,
    this.releaseType,
    this.hasFrontCover = false,
  });
}

class MusicBrainzCoverArt {
  final Uint8List bytes;
  final String mimeType;

  const MusicBrainzCoverArt({required this.bytes, required this.mimeType});
}

class MusicBrainzService {
  static const _userAgent =
      'Ganne/1.0.0 (https://github.com/Dipak-Chauhan/Ganne)';
  // A FLAC metadata block uses a 24-bit length field. Leave room for the
  // PICTURE block header so embedding original artwork cannot reject all tags.
  static const _maximumCoverBytes = 0xFFFFFF - 64;
  static const _maximumCachedCovers = 6;

  final http.Client _client;
  final Duration minimumRequestInterval;
  final Map<String, Future<MusicBrainzMetadata?>> _metadataCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _barcodeReleaseCache = {};
  final Map<String, Future<Map<String, dynamic>?>> _releaseCache = {};
  final Map<String, Future<MusicBrainzCoverArt?>> _coverCache = {};
  Future<void> _requestQueue = Future<void>.value();
  DateTime? _lastRequestStarted;

  MusicBrainzService({
    http.Client? client,
    this.minimumRequestInterval = const Duration(milliseconds: 1100),
  }) : _client = client ?? http.Client();

  Future<MusicBrainzMetadata?> resolveTrack({
    String? isrc,
    required String title,
    required String artist,
    required String album,
    String? albumArtist,
    int? durationSeconds,
    int? year,
    int? trackNumber,
    int? discNumber,
    int? totalTracks,
    int? totalDiscs,
    String? barcode,
  }) {
    final normalizedIsrc = _normalizeIsrc(isrc);
    final normalizedBarcode = _canonicalBarcode(barcode);
    final key = [
      normalizedIsrc ?? '',
      _normalizeText(title),
      _normalizeText(artist),
      _normalizeText(album),
      _normalizeText(albumArtist ?? ''),
      normalizedBarcode ?? '',
      durationSeconds?.toString() ?? '',
      year?.toString() ?? '',
      trackNumber?.toString() ?? '',
      discNumber?.toString() ?? '',
      totalTracks?.toString() ?? '',
      totalDiscs?.toString() ?? '',
    ].join('|');
    return _metadataCache.putIfAbsent(
      key,
      () => _resolveTrack(
        isrc: normalizedIsrc,
        title: title,
        artist: artist,
        album: album,
        albumArtist: albumArtist,
        durationSeconds: durationSeconds,
        year: year,
        trackNumber: trackNumber,
        discNumber: discNumber,
        totalTracks: totalTracks,
        totalDiscs: totalDiscs,
        barcode: normalizedBarcode,
      ),
    );
  }

  Future<MusicBrainzCoverArt?> fetchCoverArt(String releaseId) {
    return _cachedCover(
      'mb:$releaseId',
      () => _downloadImage(
        Uri.https('coverartarchive.org', '/release/$releaseId/front'),
      ),
    );
  }

  Future<MusicBrainzCoverArt?> fetchImage(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return Future.value(null);
    return _cachedCover('url:$url', () => _downloadImage(uri));
  }

  Future<MusicBrainzCoverArt?> _cachedCover(
    String key,
    Future<MusicBrainzCoverArt?> Function() loader,
  ) {
    final existing = _coverCache[key];
    if (existing != null) return existing;
    while (_coverCache.length >= _maximumCachedCovers) {
      _coverCache.remove(_coverCache.keys.first);
    }
    final cover = loader();
    _coverCache[key] = cover;
    return cover;
  }

  Future<MusicBrainzMetadata?> _resolveTrack({
    required String? isrc,
    required String title,
    required String artist,
    required String album,
    required String? albumArtist,
    required int? durationSeconds,
    required int? year,
    required int? trackNumber,
    required int? discNumber,
    required int? totalTracks,
    required int? totalDiscs,
    required String? barcode,
  }) async {
    Map<String, dynamic>? release;
    _ReleaseTrackMatch? releaseTrack;

    if (barcode != null) {
      final releaseSummary = await _findReleaseByBarcode(barcode);
      final releaseId = _string(releaseSummary?['id']);
      if (releaseId != null) {
        release = await _getRelease(releaseId);
        releaseTrack = _findTrackInRelease(
          release,
          isrc: isrc,
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          expectedTrackNumber: trackNumber,
          expectedDiscNumber: discNumber,
        );
      }
    }

    Map<String, dynamic>? recording = releaseTrack?.recording;
    Map<String, dynamic>? track = releaseTrack?.track;
    Map<String, dynamic>? medium = releaseTrack?.medium;

    if (recording == null) {
      release = null;
      final search = await _searchRecording(
        isrc: isrc,
        title: title,
        artist: artist,
        album: album,
      );
      final recordings = _mapList(search?['recordings']);
      recording = _selectRecording(
        recordings,
        isrc: isrc,
        title: title,
        artist: artist,
        durationSeconds: durationSeconds,
      );
      if (recording == null) return null;

      final releaseSummary = _selectRelease(
        _mapList(recording['releases']),
        album: album,
        albumArtist: albumArtist ?? artist,
        year: year,
        trackNumber: trackNumber,
        discNumber: discNumber,
        totalTracks: totalTracks,
        totalDiscs: totalDiscs,
      );
      final releaseId = _string(releaseSummary?['id']);
      if (releaseId != null) {
        release = await _getRelease(releaseId) ?? releaseSummary;
        releaseTrack = _findTrackInRelease(
          release,
          isrc: isrc,
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          expectedTrackNumber: trackNumber,
          expectedDiscNumber: discNumber,
        );
        recording = releaseTrack?.recording ?? recording;
        track = releaseTrack?.track;
        medium = releaseTrack?.medium;
      }
    }

    final releaseGroup = _asMap(release?['release-group']);
    final recordingArtist = _artistCredit(recording['artist-credit']);
    final trackArtist = _artistCredit(track?['artist-credit']);
    final releaseArtistCredit = _artistCredit(release?['artist-credit']);
    final media = _mapList(release?['media']);
    final labelInfo = _mapList(release?['label-info']);
    final firstLabel = labelInfo.isEmpty ? null : labelInfo.first;
    final label = _asMap(firstLabel?['label']);
    final releaseTypes = _stringList(releaseGroup?['secondary-types']);
    final primaryReleaseType = _string(releaseGroup?['primary-type']);
    if (primaryReleaseType != null) releaseTypes.insert(0, primaryReleaseType);

    return MusicBrainzMetadata(
      title:
          _nonEmptyString(track?['title']) ??
          _nonEmptyString(recording['title']),
      artist: trackArtist.name ?? recordingArtist.name,
      album: _nonEmptyString(release?['title']),
      albumArtist: releaseArtistCredit.name,
      date: _nonEmptyString(release?['date']),
      originalDate:
          _nonEmptyString(releaseGroup?['first-release-date']) ??
          _nonEmptyString(recording['first-release-date']),
      genre: _genres(
        recording['genres'],
        releaseGroup?['genres'],
        release?['genres'],
      ),
      isrc: isrc ?? _stringList(recording['isrcs']).firstOrNull,
      trackNumber: _toInt(track?['position']),
      totalTracks: _toInt(medium?['track-count']),
      discNumber: _toInt(medium?['position']),
      totalDiscs: media.isEmpty ? null : media.length,
      recordingId: _string(recording['id']),
      releaseTrackId: _string(track?['id']),
      releaseId: _string(release?['id']),
      releaseGroupId: _string(releaseGroup?['id']),
      artistIds: trackArtist.ids.isNotEmpty
          ? trackArtist.ids
          : recordingArtist.ids,
      albumArtistIds: releaseArtistCredit.ids,
      barcode: _nonEmptyString(release?['barcode']),
      label: _nonEmptyString(label?['name']),
      catalogNumber: _nonEmptyString(firstLabel?['catalog-number']),
      releaseCountry: _nonEmptyString(release?['country']),
      releaseStatus: _nonEmptyString(release?['status']),
      releaseType: releaseTypes.isEmpty ? null : releaseTypes.join('; '),
      hasFrontCover: _asMap(release?['cover-art-archive'])?['front'] == true,
    );
  }

  Future<Map<String, dynamic>?> _searchRecording({
    required String? isrc,
    required String title,
    required String artist,
    required String album,
  }) {
    final query = isrc != null
        ? 'isrc:$isrc'
        : [
            'recording:${_quoted(title)}',
            'artist:${_quoted(artist)}',
            if (album.trim().isNotEmpty) 'release:${_quoted(album)}',
          ].join(' AND ');
    return _requestJson(
      Uri.https('musicbrainz.org', '/ws/2/recording', {
        'query': query,
        'limit': isrc == null ? '10' : '5',
        'fmt': 'json',
      }),
    );
  }

  Future<Map<String, dynamic>?> _findReleaseByBarcode(String barcode) {
    final cacheKey = _canonicalBarcode(barcode) ?? barcode;
    return _barcodeReleaseCache.putIfAbsent(cacheKey, () async {
      final response = await _requestJson(
        Uri.https('musicbrainz.org', '/ws/2/release', {
          'query': 'barcode:$barcode',
          'limit': '5',
          'fmt': 'json',
        }),
      );
      final releases = _mapList(response?['releases']);
      for (final release in releases) {
        if (_canonicalBarcode(_string(release['barcode'])) == cacheKey) {
          return release;
        }
      }
      return null;
    });
  }

  Future<Map<String, dynamic>?> _getRelease(String releaseId) {
    return _releaseCache.putIfAbsent(
      releaseId,
      () => _requestJson(
        Uri.https('musicbrainz.org', '/ws/2/release/$releaseId', {
          'inc': [
            'artist-credits',
            'recordings',
            'release-groups',
            'media',
            'labels',
            'genres',
            'isrcs',
          ].join('+'),
          'fmt': 'json',
        }),
      ),
    );
  }

  Map<String, dynamic>? _selectRecording(
    List<Map<String, dynamic>> recordings, {
    required String? isrc,
    required String title,
    required String artist,
    required int? durationSeconds,
  }) {
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final recording in recordings) {
      final candidateIsrcs = _stringList(
        recording['isrcs'],
      ).map(_normalizeIsrc).whereType<String>();
      final exactIsrc = isrc != null && candidateIsrcs.contains(isrc);
      if (isrc != null && !exactIsrc) continue;

      final candidateTitle = _string(recording['title']) ?? '';
      final candidateArtist =
          _artistCredit(recording['artist-credit']).name ?? '';
      if (!exactIsrc &&
          (!_conservativelyMatches(candidateTitle, title) ||
              !_conservativelyMatches(candidateArtist, artist))) {
        continue;
      }

      var score = exactIsrc ? 300 : 0;
      score += _textScore(candidateTitle, title, exact: 100, partial: 35);
      score += _textScore(candidateArtist, artist, exact: 70, partial: 25);
      final candidateDuration = _toInt(recording['length']);
      if (durationSeconds != null && candidateDuration != null) {
        final difference = (candidateDuration - durationSeconds * 1000).abs();
        if (difference <= 2500) {
          score += 20;
        } else if (difference <= 6000) {
          score += 10;
        }
      }
      score += ((_toInt(recording['score']) ?? 0) / 10).round();
      if (score > bestScore) {
        best = recording;
        bestScore = score;
      }
    }
    return best;
  }

  Map<String, dynamic>? _selectRelease(
    List<Map<String, dynamic>> releases, {
    required String album,
    String? albumArtist,
    int? year,
    int? trackNumber,
    int? discNumber,
    int? totalTracks,
    int? totalDiscs,
  }) {
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final release in releases) {
      final candidateAlbum = _string(release['title']) ?? '';
      if (album.isNotEmpty && !_conservativelyMatches(candidateAlbum, album)) {
        continue;
      }

      var score = _textScore(candidateAlbum, album, exact: 100, partial: 35);
      if (albumArtist != null && albumArtist.isNotEmpty) {
        score += _textScore(
          _artistCredit(release['artist-credit']).name ?? '',
          albumArtist,
          exact: 30,
          partial: 10,
        );
      }
      final releaseYear = _yearFromDate(_string(release['date']));
      if (year != null && releaseYear == year) score += 20;
      if ((_string(release['status']) ?? '').toLowerCase() == 'official') {
        score += 10;
      }
      final releaseGroup = _asMap(release['release-group']);
      if ((_string(releaseGroup?['primary-type']) ?? '').toLowerCase() ==
          'album') {
        score += 5;
      }

      final media = _mapList(release['media']);
      if (totalDiscs != null && media.length == totalDiscs) score += 5;
      final medium = _findMedium(media, discNumber);
      if (totalTracks != null &&
          _toInt(medium?['track-count']) == totalTracks) {
        score += 5;
      }
      if (trackNumber != null && _toInt(medium?['track-count']) != null) {
        if (trackNumber <= _toInt(medium?['track-count'])!) score += 2;
      }
      if (score > bestScore) {
        best = release;
        bestScore = score;
      }
    }
    return best;
  }

  _ReleaseTrackMatch? _findTrackInRelease(
    Map<String, dynamic>? release, {
    required String? isrc,
    required String title,
    required String artist,
    required int? durationSeconds,
    required int? expectedTrackNumber,
    required int? expectedDiscNumber,
  }) {
    if (release == null) return null;
    _ReleaseTrackMatch? best;
    var bestScore = -1;
    for (final medium in _mapList(release['media'])) {
      for (final track in _mapList(medium['tracks'])) {
        final recording = _asMap(track['recording']);
        if (recording == null) continue;
        final candidateIsrcs = _stringList(
          recording['isrcs'],
        ).map(_normalizeIsrc).whereType<String>();
        final exactIsrc = isrc != null && candidateIsrcs.contains(isrc);
        if (isrc != null && !exactIsrc) continue;
        final candidateTitle =
            _string(track['title']) ?? _string(recording['title']) ?? '';
        final candidateArtist =
            _artistCredit(track['artist-credit']).name ??
            _artistCredit(recording['artist-credit']).name ??
            '';
        if (!exactIsrc &&
            (!_conservativelyMatches(candidateTitle, title) ||
                !_conservativelyMatches(candidateArtist, artist))) {
          continue;
        }

        var score = exactIsrc ? 300 : 0;
        score += _textScore(candidateTitle, title, exact: 100, partial: 35);
        score += _textScore(candidateArtist, artist, exact: 70, partial: 25);
        if (expectedTrackNumber != null &&
            _toInt(track['position']) == expectedTrackNumber) {
          score += 15;
        }
        if (expectedDiscNumber != null &&
            _toInt(medium['position']) == expectedDiscNumber) {
          score += 15;
        }
        final candidateDuration =
            _toInt(track['length']) ?? _toInt(recording['length']);
        if (durationSeconds != null && candidateDuration != null) {
          final difference = (candidateDuration - durationSeconds * 1000).abs();
          if (difference <= 2500) score += 20;
        }
        if (score > bestScore) {
          best = _ReleaseTrackMatch(
            recording: recording,
            track: track,
            medium: medium,
          );
          bestScore = score;
        }
      }
    }
    return best;
  }

  Future<Map<String, dynamic>?> _requestJson(Uri uri) {
    final completer = Completer<Map<String, dynamic>?>();
    _requestQueue = _requestQueue.then((_) async {
      final lastStarted = _lastRequestStarted;
      if (lastStarted != null) {
        final remaining =
            minimumRequestInterval - DateTime.now().difference(lastStarted);
        if (remaining > Duration.zero) {
          // Timers can fire slightly early on Windows; keep the public API
          // below MusicBrainz's request-rate limit rather than merely near it.
          await Future<void>.delayed(
            remaining + const Duration(milliseconds: 5),
          );
        }
      }
      _lastRequestStarted = DateTime.now();
      try {
        final response = await _client
            .get(
              uri,
              headers: const {
                'Accept': 'application/json',
                'User-Agent': _userAgent,
              },
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          completer.complete(null);
          return;
        }
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        completer.complete(_asMap(decoded));
      } catch (_) {
        completer.complete(null);
      }
    });
    return completer.future;
  }

  Future<MusicBrainzCoverArt?> _downloadImage(Uri uri) async {
    try {
      final request = http.Request('GET', uri)
        ..headers.addAll(const {'Accept': 'image/*', 'User-Agent': _userAgent});
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final contentLength = response.contentLength;
      if (contentLength != null && contentLength > _maximumCoverBytes) {
        return null;
      }

      final bytes = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        length += chunk.length;
        if (length > _maximumCoverBytes) return null;
        bytes.add(chunk);
      }
      final data = bytes.takeBytes();
      final mimeType = _detectImageMime(data);
      if (mimeType == null) return null;
      return MusicBrainzCoverArt(bytes: data, mimeType: mimeType);
    } catch (_) {
      return null;
    }
  }

  static String? _detectImageMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 6) {
      final signature = ascii.decode(bytes.sublist(0, 6), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') return 'image/gif';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }
    if (bytes.length >= 4 &&
        ((bytes[0] == 0x49 &&
                bytes[1] == 0x49 &&
                bytes[2] == 0x2A &&
                bytes[3] == 0x00) ||
            (bytes[0] == 0x4D &&
                bytes[1] == 0x4D &&
                bytes[2] == 0x00 &&
                bytes[3] == 0x2A))) {
      return 'image/tiff';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  static Map<String, dynamic>? _findMedium(
    List<Map<String, dynamic>> media,
    int? discNumber,
  ) {
    if (media.isEmpty) return null;
    if (discNumber != null) {
      for (final medium in media) {
        if (_toInt(medium['position']) == discNumber) return medium;
      }
    }
    return media.first;
  }

  static _ArtistCredit _artistCredit(dynamic value) {
    final credits = _mapList(value);
    if (credits.isEmpty) return const _ArtistCredit();
    final text = StringBuffer();
    final ids = <String>[];
    for (final credit in credits) {
      text.write(
        _string(credit['name']) ??
            _string(_asMap(credit['artist'])?['name']) ??
            '',
      );
      text.write(_string(credit['joinphrase']) ?? '');
      final id = _string(_asMap(credit['artist'])?['id']);
      if (id != null && !ids.contains(id)) ids.add(id);
    }
    final name = text.toString().trim();
    return _ArtistCredit(name: name.isEmpty ? null : name, ids: ids);
  }

  static String? _genres(dynamic first, dynamic second, dynamic third) {
    final byName = <String, int>{};
    for (final source in [first, second, third]) {
      for (final genre in _mapList(source)) {
        final name = _nonEmptyString(genre['name']);
        if (name == null) continue;
        final count = _toInt(genre['count']) ?? 0;
        if (count > (byName[name] ?? -1)) byName[name] = count;
      }
    }
    final entries = byName.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        return countComparison != 0 ? countComparison : a.key.compareTo(b.key);
      });
    if (entries.isEmpty) return null;
    return entries.take(3).map((entry) => entry.key).join('; ');
  }

  static int _textScore(
    String candidate,
    String expected, {
    required int exact,
    required int partial,
  }) {
    final normalizedCandidate = _normalizeText(candidate);
    final normalizedExpected = _normalizeText(expected);
    if (normalizedCandidate.isEmpty || normalizedExpected.isEmpty) return 0;
    if (normalizedCandidate == normalizedExpected) return exact;
    if (normalizedCandidate.contains(normalizedExpected) ||
        normalizedExpected.contains(normalizedCandidate)) {
      return partial;
    }
    return 0;
  }

  static bool _conservativelyMatches(String candidate, String expected) {
    if (expected.trim().isEmpty) return true;
    return _normalizeText(candidate) == _normalizeText(expected);
  }

  static String _normalizeText(String value) => value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll('\u2019', '')
      .replaceAll(RegExp(r'''[\s\-_.:,;!?()\[\]{}"'/\\]+'''), '');

  static String? _normalizeIsrc(String? value) {
    if (value == null) return null;
    final normalized = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return normalized.length == 12 ? normalized : null;
  }

  static String? _normalizeBarcode(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(RegExp(r'\D'), '');
    return normalized.length >= 8 ? normalized : null;
  }

  static String? _canonicalBarcode(String? value) {
    final normalized = _normalizeBarcode(value);
    if (normalized == null) return null;
    var canonical = normalized;
    while (canonical.length > 12 && canonical.startsWith('0')) {
      canonical = canonical.substring(1);
    }
    return canonical;
  }

  static String _quoted(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  static int? _yearFromDate(String? value) {
    if (value == null || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_asMap).whereType<Map<String, dynamic>>().toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }

  static String? _string(dynamic value) => value is String ? value : null;

  static String? _nonEmptyString(dynamic value) {
    final string = _string(value)?.trim();
    return string == null || string.isEmpty ? null : string;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _ReleaseTrackMatch {
  final Map<String, dynamic> recording;
  final Map<String, dynamic> track;
  final Map<String, dynamic> medium;

  const _ReleaseTrackMatch({
    required this.recording,
    required this.track,
    required this.medium,
  });
}

class _ArtistCredit {
  final String? name;
  final List<String> ids;

  const _ArtistCredit({this.name, this.ids = const []});
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
