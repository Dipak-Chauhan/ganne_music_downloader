// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DownloadTasksTable extends DownloadTasks
    with TableInfo<$DownloadTasksTable, DownloadTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackTitleMeta = const VerificationMeta(
    'trackTitle',
  );
  @override
  late final GeneratedColumn<String> trackTitle = GeneratedColumn<String>(
    'track_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumTitleMeta = const VerificationMeta(
    'albumTitle',
  );
  @override
  late final GeneratedColumn<String> albumTitle = GeneratedColumn<String>(
    'album_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackVersionMeta = const VerificationMeta(
    'trackVersion',
  );
  @override
  late final GeneratedColumn<String> trackVersion = GeneratedColumn<String>(
    'track_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isrcMeta = const VerificationMeta('isrc');
  @override
  late final GeneratedColumn<String> isrc = GeneratedColumn<String>(
    'isrc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackNumberMeta = const VerificationMeta(
    'trackNumber',
  );
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
    'track_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _discNumberMeta = const VerificationMeta(
    'discNumber',
  );
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
    'disc_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalTracksMeta = const VerificationMeta(
    'totalTracks',
  );
  @override
  late final GeneratedColumn<int> totalTracks = GeneratedColumn<int>(
    'total_tracks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDiscsMeta = const VerificationMeta(
    'totalDiscs',
  );
  @override
  late final GeneratedColumn<int> totalDiscs = GeneratedColumn<int>(
    'total_discs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _copyrightMeta = const VerificationMeta(
    'copyright',
  );
  @override
  late final GeneratedColumn<String> copyright = GeneratedColumn<String>(
    'copyright',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogNumberMeta = const VerificationMeta(
    'catalogNumber',
  );
  @override
  late final GeneratedColumn<String> catalogNumber = GeneratedColumn<String>(
    'catalog_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalReleaseDateMeta =
      const VerificationMeta('originalReleaseDate');
  @override
  late final GeneratedColumn<String> originalReleaseDate =
      GeneratedColumn<String>(
        'original_release_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _releaseCountryMeta = const VerificationMeta(
    'releaseCountry',
  );
  @override
  late final GeneratedColumn<String> releaseCountry = GeneratedColumn<String>(
    'release_country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseStatusMeta = const VerificationMeta(
    'releaseStatus',
  );
  @override
  late final GeneratedColumn<String> releaseStatus = GeneratedColumn<String>(
    'release_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseTypeMeta = const VerificationMeta(
    'releaseType',
  );
  @override
  late final GeneratedColumn<String> releaseType = GeneratedColumn<String>(
    'release_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _musicBrainzRecordingIdMeta =
      const VerificationMeta('musicBrainzRecordingId');
  @override
  late final GeneratedColumn<String> musicBrainzRecordingId =
      GeneratedColumn<String>(
        'music_brainz_recording_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _musicBrainzReleaseTrackIdMeta =
      const VerificationMeta('musicBrainzReleaseTrackId');
  @override
  late final GeneratedColumn<String> musicBrainzReleaseTrackId =
      GeneratedColumn<String>(
        'music_brainz_release_track_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _musicBrainzReleaseIdMeta =
      const VerificationMeta('musicBrainzReleaseId');
  @override
  late final GeneratedColumn<String> musicBrainzReleaseId =
      GeneratedColumn<String>(
        'music_brainz_release_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _musicBrainzReleaseGroupIdMeta =
      const VerificationMeta('musicBrainzReleaseGroupId');
  @override
  late final GeneratedColumn<String> musicBrainzReleaseGroupId =
      GeneratedColumn<String>(
        'music_brainz_release_group_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _musicBrainzArtistIdsMeta =
      const VerificationMeta('musicBrainzArtistIds');
  @override
  late final GeneratedColumn<String> musicBrainzArtistIds =
      GeneratedColumn<String>(
        'music_brainz_artist_ids',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _musicBrainzAlbumArtistIdsMeta =
      const VerificationMeta('musicBrainzAlbumArtistIds');
  @override
  late final GeneratedColumn<String> musicBrainzAlbumArtistIds =
      GeneratedColumn<String>(
        'music_brainz_album_artist_ids',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _savePathMeta = const VerificationMeta(
    'savePath',
  );
  @override
  late final GeneratedColumn<String> savePath = GeneratedColumn<String>(
    'save_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    trackTitle,
    albumTitle,
    artistName,
    albumArtist,
    trackVersion,
    isrc,
    trackNumber,
    discNumber,
    totalTracks,
    totalDiscs,
    durationSeconds,
    year,
    genre,
    copyright,
    label,
    barcode,
    catalogNumber,
    releaseDate,
    originalReleaseDate,
    releaseCountry,
    releaseStatus,
    releaseType,
    musicBrainzRecordingId,
    musicBrainzReleaseTrackId,
    musicBrainzReleaseId,
    musicBrainzReleaseGroupId,
    musicBrainzArtistIds,
    musicBrainzAlbumArtistIds,
    coverUrl,
    quality,
    totalBytes,
    downloadedBytes,
    status,
    savePath,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('track_title')) {
      context.handle(
        _trackTitleMeta,
        trackTitle.isAcceptableOrUnknown(data['track_title']!, _trackTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_trackTitleMeta);
    }
    if (data.containsKey('album_title')) {
      context.handle(
        _albumTitleMeta,
        albumTitle.isAcceptableOrUnknown(data['album_title']!, _albumTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_albumTitleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('track_version')) {
      context.handle(
        _trackVersionMeta,
        trackVersion.isAcceptableOrUnknown(
          data['track_version']!,
          _trackVersionMeta,
        ),
      );
    }
    if (data.containsKey('isrc')) {
      context.handle(
        _isrcMeta,
        isrc.isAcceptableOrUnknown(data['isrc']!, _isrcMeta),
      );
    }
    if (data.containsKey('track_number')) {
      context.handle(
        _trackNumberMeta,
        trackNumber.isAcceptableOrUnknown(
          data['track_number']!,
          _trackNumberMeta,
        ),
      );
    }
    if (data.containsKey('disc_number')) {
      context.handle(
        _discNumberMeta,
        discNumber.isAcceptableOrUnknown(data['disc_number']!, _discNumberMeta),
      );
    }
    if (data.containsKey('total_tracks')) {
      context.handle(
        _totalTracksMeta,
        totalTracks.isAcceptableOrUnknown(
          data['total_tracks']!,
          _totalTracksMeta,
        ),
      );
    }
    if (data.containsKey('total_discs')) {
      context.handle(
        _totalDiscsMeta,
        totalDiscs.isAcceptableOrUnknown(data['total_discs']!, _totalDiscsMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('copyright')) {
      context.handle(
        _copyrightMeta,
        copyright.isAcceptableOrUnknown(data['copyright']!, _copyrightMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('catalog_number')) {
      context.handle(
        _catalogNumberMeta,
        catalogNumber.isAcceptableOrUnknown(
          data['catalog_number']!,
          _catalogNumberMeta,
        ),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('original_release_date')) {
      context.handle(
        _originalReleaseDateMeta,
        originalReleaseDate.isAcceptableOrUnknown(
          data['original_release_date']!,
          _originalReleaseDateMeta,
        ),
      );
    }
    if (data.containsKey('release_country')) {
      context.handle(
        _releaseCountryMeta,
        releaseCountry.isAcceptableOrUnknown(
          data['release_country']!,
          _releaseCountryMeta,
        ),
      );
    }
    if (data.containsKey('release_status')) {
      context.handle(
        _releaseStatusMeta,
        releaseStatus.isAcceptableOrUnknown(
          data['release_status']!,
          _releaseStatusMeta,
        ),
      );
    }
    if (data.containsKey('release_type')) {
      context.handle(
        _releaseTypeMeta,
        releaseType.isAcceptableOrUnknown(
          data['release_type']!,
          _releaseTypeMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_recording_id')) {
      context.handle(
        _musicBrainzRecordingIdMeta,
        musicBrainzRecordingId.isAcceptableOrUnknown(
          data['music_brainz_recording_id']!,
          _musicBrainzRecordingIdMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_release_track_id')) {
      context.handle(
        _musicBrainzReleaseTrackIdMeta,
        musicBrainzReleaseTrackId.isAcceptableOrUnknown(
          data['music_brainz_release_track_id']!,
          _musicBrainzReleaseTrackIdMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_release_id')) {
      context.handle(
        _musicBrainzReleaseIdMeta,
        musicBrainzReleaseId.isAcceptableOrUnknown(
          data['music_brainz_release_id']!,
          _musicBrainzReleaseIdMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_release_group_id')) {
      context.handle(
        _musicBrainzReleaseGroupIdMeta,
        musicBrainzReleaseGroupId.isAcceptableOrUnknown(
          data['music_brainz_release_group_id']!,
          _musicBrainzReleaseGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_artist_ids')) {
      context.handle(
        _musicBrainzArtistIdsMeta,
        musicBrainzArtistIds.isAcceptableOrUnknown(
          data['music_brainz_artist_ids']!,
          _musicBrainzArtistIdsMeta,
        ),
      );
    }
    if (data.containsKey('music_brainz_album_artist_ids')) {
      context.handle(
        _musicBrainzAlbumArtistIdsMeta,
        musicBrainzAlbumArtistIds.isAcceptableOrUnknown(
          data['music_brainz_album_artist_ids']!,
          _musicBrainzAlbumArtistIdsMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('save_path')) {
      context.handle(
        _savePathMeta,
        savePath.isAcceptableOrUnknown(data['save_path']!, _savePathMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      trackTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_title'],
      )!,
      albumTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_title'],
      )!,
      artistName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_name'],
      )!,
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      trackVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_version'],
      ),
      isrc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isrc'],
      ),
      trackNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_number'],
      ),
      discNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disc_number'],
      ),
      totalTracks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_tracks'],
      ),
      totalDiscs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_discs'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      copyright: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}copyright'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      catalogNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_number'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      originalReleaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_release_date'],
      ),
      releaseCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_country'],
      ),
      releaseStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_status'],
      ),
      releaseType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_type'],
      ),
      musicBrainzRecordingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_recording_id'],
      ),
      musicBrainzReleaseTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_release_track_id'],
      ),
      musicBrainzReleaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_release_id'],
      ),
      musicBrainzReleaseGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_release_group_id'],
      ),
      musicBrainzArtistIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_artist_ids'],
      ),
      musicBrainzAlbumArtistIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}music_brainz_album_artist_ids'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      savePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}save_path'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $DownloadTasksTable createAlias(String alias) {
    return $DownloadTasksTable(attachedDatabase, alias);
  }
}

class DownloadTask extends DataClass implements Insertable<DownloadTask> {
  final int id;
  final int trackId;
  final String trackTitle;
  final String albumTitle;
  final String artistName;
  final String? albumArtist;
  final String? trackVersion;
  final String? isrc;
  final int? trackNumber;
  final int? discNumber;
  final int? totalTracks;
  final int? totalDiscs;
  final int? durationSeconds;
  final int? year;
  final String? genre;
  final String? copyright;
  final String? label;
  final String? barcode;
  final String? catalogNumber;
  final String? releaseDate;
  final String? originalReleaseDate;
  final String? releaseCountry;
  final String? releaseStatus;
  final String? releaseType;
  final String? musicBrainzRecordingId;
  final String? musicBrainzReleaseTrackId;
  final String? musicBrainzReleaseId;
  final String? musicBrainzReleaseGroupId;
  final String? musicBrainzArtistIds;
  final String? musicBrainzAlbumArtistIds;
  final String coverUrl;
  final String quality;
  final int totalBytes;
  final int downloadedBytes;
  final String status;
  final String? savePath;
  final int addedAt;
  const DownloadTask({
    required this.id,
    required this.trackId,
    required this.trackTitle,
    required this.albumTitle,
    required this.artistName,
    this.albumArtist,
    this.trackVersion,
    this.isrc,
    this.trackNumber,
    this.discNumber,
    this.totalTracks,
    this.totalDiscs,
    this.durationSeconds,
    this.year,
    this.genre,
    this.copyright,
    this.label,
    this.barcode,
    this.catalogNumber,
    this.releaseDate,
    this.originalReleaseDate,
    this.releaseCountry,
    this.releaseStatus,
    this.releaseType,
    this.musicBrainzRecordingId,
    this.musicBrainzReleaseTrackId,
    this.musicBrainzReleaseId,
    this.musicBrainzReleaseGroupId,
    this.musicBrainzArtistIds,
    this.musicBrainzAlbumArtistIds,
    required this.coverUrl,
    required this.quality,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.status,
    this.savePath,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['track_title'] = Variable<String>(trackTitle);
    map['album_title'] = Variable<String>(albumTitle);
    map['artist_name'] = Variable<String>(artistName);
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || trackVersion != null) {
      map['track_version'] = Variable<String>(trackVersion);
    }
    if (!nullToAbsent || isrc != null) {
      map['isrc'] = Variable<String>(isrc);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    if (!nullToAbsent || totalTracks != null) {
      map['total_tracks'] = Variable<int>(totalTracks);
    }
    if (!nullToAbsent || totalDiscs != null) {
      map['total_discs'] = Variable<int>(totalDiscs);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || copyright != null) {
      map['copyright'] = Variable<String>(copyright);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || catalogNumber != null) {
      map['catalog_number'] = Variable<String>(catalogNumber);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || originalReleaseDate != null) {
      map['original_release_date'] = Variable<String>(originalReleaseDate);
    }
    if (!nullToAbsent || releaseCountry != null) {
      map['release_country'] = Variable<String>(releaseCountry);
    }
    if (!nullToAbsent || releaseStatus != null) {
      map['release_status'] = Variable<String>(releaseStatus);
    }
    if (!nullToAbsent || releaseType != null) {
      map['release_type'] = Variable<String>(releaseType);
    }
    if (!nullToAbsent || musicBrainzRecordingId != null) {
      map['music_brainz_recording_id'] = Variable<String>(
        musicBrainzRecordingId,
      );
    }
    if (!nullToAbsent || musicBrainzReleaseTrackId != null) {
      map['music_brainz_release_track_id'] = Variable<String>(
        musicBrainzReleaseTrackId,
      );
    }
    if (!nullToAbsent || musicBrainzReleaseId != null) {
      map['music_brainz_release_id'] = Variable<String>(musicBrainzReleaseId);
    }
    if (!nullToAbsent || musicBrainzReleaseGroupId != null) {
      map['music_brainz_release_group_id'] = Variable<String>(
        musicBrainzReleaseGroupId,
      );
    }
    if (!nullToAbsent || musicBrainzArtistIds != null) {
      map['music_brainz_artist_ids'] = Variable<String>(musicBrainzArtistIds);
    }
    if (!nullToAbsent || musicBrainzAlbumArtistIds != null) {
      map['music_brainz_album_artist_ids'] = Variable<String>(
        musicBrainzAlbumArtistIds,
      );
    }
    map['cover_url'] = Variable<String>(coverUrl);
    map['quality'] = Variable<String>(quality);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || savePath != null) {
      map['save_path'] = Variable<String>(savePath);
    }
    map['added_at'] = Variable<int>(addedAt);
    return map;
  }

  DownloadTasksCompanion toCompanion(bool nullToAbsent) {
    return DownloadTasksCompanion(
      id: Value(id),
      trackId: Value(trackId),
      trackTitle: Value(trackTitle),
      albumTitle: Value(albumTitle),
      artistName: Value(artistName),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      trackVersion: trackVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(trackVersion),
      isrc: isrc == null && nullToAbsent ? const Value.absent() : Value(isrc),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      totalTracks: totalTracks == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTracks),
      totalDiscs: totalDiscs == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDiscs),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      copyright: copyright == null && nullToAbsent
          ? const Value.absent()
          : Value(copyright),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      catalogNumber: catalogNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogNumber),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      originalReleaseDate: originalReleaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originalReleaseDate),
      releaseCountry: releaseCountry == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseCountry),
      releaseStatus: releaseStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseStatus),
      releaseType: releaseType == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseType),
      musicBrainzRecordingId: musicBrainzRecordingId == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzRecordingId),
      musicBrainzReleaseTrackId:
          musicBrainzReleaseTrackId == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzReleaseTrackId),
      musicBrainzReleaseId: musicBrainzReleaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzReleaseId),
      musicBrainzReleaseGroupId:
          musicBrainzReleaseGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzReleaseGroupId),
      musicBrainzArtistIds: musicBrainzArtistIds == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzArtistIds),
      musicBrainzAlbumArtistIds:
          musicBrainzAlbumArtistIds == null && nullToAbsent
          ? const Value.absent()
          : Value(musicBrainzAlbumArtistIds),
      coverUrl: Value(coverUrl),
      quality: Value(quality),
      totalBytes: Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      status: Value(status),
      savePath: savePath == null && nullToAbsent
          ? const Value.absent()
          : Value(savePath),
      addedAt: Value(addedAt),
    );
  }

  factory DownloadTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTask(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      trackTitle: serializer.fromJson<String>(json['trackTitle']),
      albumTitle: serializer.fromJson<String>(json['albumTitle']),
      artistName: serializer.fromJson<String>(json['artistName']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      trackVersion: serializer.fromJson<String?>(json['trackVersion']),
      isrc: serializer.fromJson<String?>(json['isrc']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      totalTracks: serializer.fromJson<int?>(json['totalTracks']),
      totalDiscs: serializer.fromJson<int?>(json['totalDiscs']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      year: serializer.fromJson<int?>(json['year']),
      genre: serializer.fromJson<String?>(json['genre']),
      copyright: serializer.fromJson<String?>(json['copyright']),
      label: serializer.fromJson<String?>(json['label']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      catalogNumber: serializer.fromJson<String?>(json['catalogNumber']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      originalReleaseDate: serializer.fromJson<String?>(
        json['originalReleaseDate'],
      ),
      releaseCountry: serializer.fromJson<String?>(json['releaseCountry']),
      releaseStatus: serializer.fromJson<String?>(json['releaseStatus']),
      releaseType: serializer.fromJson<String?>(json['releaseType']),
      musicBrainzRecordingId: serializer.fromJson<String?>(
        json['musicBrainzRecordingId'],
      ),
      musicBrainzReleaseTrackId: serializer.fromJson<String?>(
        json['musicBrainzReleaseTrackId'],
      ),
      musicBrainzReleaseId: serializer.fromJson<String?>(
        json['musicBrainzReleaseId'],
      ),
      musicBrainzReleaseGroupId: serializer.fromJson<String?>(
        json['musicBrainzReleaseGroupId'],
      ),
      musicBrainzArtistIds: serializer.fromJson<String?>(
        json['musicBrainzArtistIds'],
      ),
      musicBrainzAlbumArtistIds: serializer.fromJson<String?>(
        json['musicBrainzAlbumArtistIds'],
      ),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      quality: serializer.fromJson<String>(json['quality']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      status: serializer.fromJson<String>(json['status']),
      savePath: serializer.fromJson<String?>(json['savePath']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'trackTitle': serializer.toJson<String>(trackTitle),
      'albumTitle': serializer.toJson<String>(albumTitle),
      'artistName': serializer.toJson<String>(artistName),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'trackVersion': serializer.toJson<String?>(trackVersion),
      'isrc': serializer.toJson<String?>(isrc),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'totalTracks': serializer.toJson<int?>(totalTracks),
      'totalDiscs': serializer.toJson<int?>(totalDiscs),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'year': serializer.toJson<int?>(year),
      'genre': serializer.toJson<String?>(genre),
      'copyright': serializer.toJson<String?>(copyright),
      'label': serializer.toJson<String?>(label),
      'barcode': serializer.toJson<String?>(barcode),
      'catalogNumber': serializer.toJson<String?>(catalogNumber),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'originalReleaseDate': serializer.toJson<String?>(originalReleaseDate),
      'releaseCountry': serializer.toJson<String?>(releaseCountry),
      'releaseStatus': serializer.toJson<String?>(releaseStatus),
      'releaseType': serializer.toJson<String?>(releaseType),
      'musicBrainzRecordingId': serializer.toJson<String?>(
        musicBrainzRecordingId,
      ),
      'musicBrainzReleaseTrackId': serializer.toJson<String?>(
        musicBrainzReleaseTrackId,
      ),
      'musicBrainzReleaseId': serializer.toJson<String?>(musicBrainzReleaseId),
      'musicBrainzReleaseGroupId': serializer.toJson<String?>(
        musicBrainzReleaseGroupId,
      ),
      'musicBrainzArtistIds': serializer.toJson<String?>(musicBrainzArtistIds),
      'musicBrainzAlbumArtistIds': serializer.toJson<String?>(
        musicBrainzAlbumArtistIds,
      ),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'quality': serializer.toJson<String>(quality),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'status': serializer.toJson<String>(status),
      'savePath': serializer.toJson<String?>(savePath),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  DownloadTask copyWith({
    int? id,
    int? trackId,
    String? trackTitle,
    String? albumTitle,
    String? artistName,
    Value<String?> albumArtist = const Value.absent(),
    Value<String?> trackVersion = const Value.absent(),
    Value<String?> isrc = const Value.absent(),
    Value<int?> trackNumber = const Value.absent(),
    Value<int?> discNumber = const Value.absent(),
    Value<int?> totalTracks = const Value.absent(),
    Value<int?> totalDiscs = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> copyright = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> catalogNumber = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    Value<String?> originalReleaseDate = const Value.absent(),
    Value<String?> releaseCountry = const Value.absent(),
    Value<String?> releaseStatus = const Value.absent(),
    Value<String?> releaseType = const Value.absent(),
    Value<String?> musicBrainzRecordingId = const Value.absent(),
    Value<String?> musicBrainzReleaseTrackId = const Value.absent(),
    Value<String?> musicBrainzReleaseId = const Value.absent(),
    Value<String?> musicBrainzReleaseGroupId = const Value.absent(),
    Value<String?> musicBrainzArtistIds = const Value.absent(),
    Value<String?> musicBrainzAlbumArtistIds = const Value.absent(),
    String? coverUrl,
    String? quality,
    int? totalBytes,
    int? downloadedBytes,
    String? status,
    Value<String?> savePath = const Value.absent(),
    int? addedAt,
  }) => DownloadTask(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    trackTitle: trackTitle ?? this.trackTitle,
    albumTitle: albumTitle ?? this.albumTitle,
    artistName: artistName ?? this.artistName,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    trackVersion: trackVersion.present ? trackVersion.value : this.trackVersion,
    isrc: isrc.present ? isrc.value : this.isrc,
    trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
    discNumber: discNumber.present ? discNumber.value : this.discNumber,
    totalTracks: totalTracks.present ? totalTracks.value : this.totalTracks,
    totalDiscs: totalDiscs.present ? totalDiscs.value : this.totalDiscs,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    year: year.present ? year.value : this.year,
    genre: genre.present ? genre.value : this.genre,
    copyright: copyright.present ? copyright.value : this.copyright,
    label: label.present ? label.value : this.label,
    barcode: barcode.present ? barcode.value : this.barcode,
    catalogNumber: catalogNumber.present
        ? catalogNumber.value
        : this.catalogNumber,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    originalReleaseDate: originalReleaseDate.present
        ? originalReleaseDate.value
        : this.originalReleaseDate,
    releaseCountry: releaseCountry.present
        ? releaseCountry.value
        : this.releaseCountry,
    releaseStatus: releaseStatus.present
        ? releaseStatus.value
        : this.releaseStatus,
    releaseType: releaseType.present ? releaseType.value : this.releaseType,
    musicBrainzRecordingId: musicBrainzRecordingId.present
        ? musicBrainzRecordingId.value
        : this.musicBrainzRecordingId,
    musicBrainzReleaseTrackId: musicBrainzReleaseTrackId.present
        ? musicBrainzReleaseTrackId.value
        : this.musicBrainzReleaseTrackId,
    musicBrainzReleaseId: musicBrainzReleaseId.present
        ? musicBrainzReleaseId.value
        : this.musicBrainzReleaseId,
    musicBrainzReleaseGroupId: musicBrainzReleaseGroupId.present
        ? musicBrainzReleaseGroupId.value
        : this.musicBrainzReleaseGroupId,
    musicBrainzArtistIds: musicBrainzArtistIds.present
        ? musicBrainzArtistIds.value
        : this.musicBrainzArtistIds,
    musicBrainzAlbumArtistIds: musicBrainzAlbumArtistIds.present
        ? musicBrainzAlbumArtistIds.value
        : this.musicBrainzAlbumArtistIds,
    coverUrl: coverUrl ?? this.coverUrl,
    quality: quality ?? this.quality,
    totalBytes: totalBytes ?? this.totalBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    status: status ?? this.status,
    savePath: savePath.present ? savePath.value : this.savePath,
    addedAt: addedAt ?? this.addedAt,
  );
  DownloadTask copyWithCompanion(DownloadTasksCompanion data) {
    return DownloadTask(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      trackTitle: data.trackTitle.present
          ? data.trackTitle.value
          : this.trackTitle,
      albumTitle: data.albumTitle.present
          ? data.albumTitle.value
          : this.albumTitle,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      trackVersion: data.trackVersion.present
          ? data.trackVersion.value
          : this.trackVersion,
      isrc: data.isrc.present ? data.isrc.value : this.isrc,
      trackNumber: data.trackNumber.present
          ? data.trackNumber.value
          : this.trackNumber,
      discNumber: data.discNumber.present
          ? data.discNumber.value
          : this.discNumber,
      totalTracks: data.totalTracks.present
          ? data.totalTracks.value
          : this.totalTracks,
      totalDiscs: data.totalDiscs.present
          ? data.totalDiscs.value
          : this.totalDiscs,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      year: data.year.present ? data.year.value : this.year,
      genre: data.genre.present ? data.genre.value : this.genre,
      copyright: data.copyright.present ? data.copyright.value : this.copyright,
      label: data.label.present ? data.label.value : this.label,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      catalogNumber: data.catalogNumber.present
          ? data.catalogNumber.value
          : this.catalogNumber,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      originalReleaseDate: data.originalReleaseDate.present
          ? data.originalReleaseDate.value
          : this.originalReleaseDate,
      releaseCountry: data.releaseCountry.present
          ? data.releaseCountry.value
          : this.releaseCountry,
      releaseStatus: data.releaseStatus.present
          ? data.releaseStatus.value
          : this.releaseStatus,
      releaseType: data.releaseType.present
          ? data.releaseType.value
          : this.releaseType,
      musicBrainzRecordingId: data.musicBrainzRecordingId.present
          ? data.musicBrainzRecordingId.value
          : this.musicBrainzRecordingId,
      musicBrainzReleaseTrackId: data.musicBrainzReleaseTrackId.present
          ? data.musicBrainzReleaseTrackId.value
          : this.musicBrainzReleaseTrackId,
      musicBrainzReleaseId: data.musicBrainzReleaseId.present
          ? data.musicBrainzReleaseId.value
          : this.musicBrainzReleaseId,
      musicBrainzReleaseGroupId: data.musicBrainzReleaseGroupId.present
          ? data.musicBrainzReleaseGroupId.value
          : this.musicBrainzReleaseGroupId,
      musicBrainzArtistIds: data.musicBrainzArtistIds.present
          ? data.musicBrainzArtistIds.value
          : this.musicBrainzArtistIds,
      musicBrainzAlbumArtistIds: data.musicBrainzAlbumArtistIds.present
          ? data.musicBrainzAlbumArtistIds.value
          : this.musicBrainzAlbumArtistIds,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      quality: data.quality.present ? data.quality.value : this.quality,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      status: data.status.present ? data.status.value : this.status,
      savePath: data.savePath.present ? data.savePath.value : this.savePath,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTask(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('trackTitle: $trackTitle, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('artistName: $artistName, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackVersion: $trackVersion, ')
          ..write('isrc: $isrc, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('totalTracks: $totalTracks, ')
          ..write('totalDiscs: $totalDiscs, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('copyright: $copyright, ')
          ..write('label: $label, ')
          ..write('barcode: $barcode, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('originalReleaseDate: $originalReleaseDate, ')
          ..write('releaseCountry: $releaseCountry, ')
          ..write('releaseStatus: $releaseStatus, ')
          ..write('releaseType: $releaseType, ')
          ..write('musicBrainzRecordingId: $musicBrainzRecordingId, ')
          ..write('musicBrainzReleaseTrackId: $musicBrainzReleaseTrackId, ')
          ..write('musicBrainzReleaseId: $musicBrainzReleaseId, ')
          ..write('musicBrainzReleaseGroupId: $musicBrainzReleaseGroupId, ')
          ..write('musicBrainzArtistIds: $musicBrainzArtistIds, ')
          ..write('musicBrainzAlbumArtistIds: $musicBrainzAlbumArtistIds, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('quality: $quality, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('savePath: $savePath, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    trackId,
    trackTitle,
    albumTitle,
    artistName,
    albumArtist,
    trackVersion,
    isrc,
    trackNumber,
    discNumber,
    totalTracks,
    totalDiscs,
    durationSeconds,
    year,
    genre,
    copyright,
    label,
    barcode,
    catalogNumber,
    releaseDate,
    originalReleaseDate,
    releaseCountry,
    releaseStatus,
    releaseType,
    musicBrainzRecordingId,
    musicBrainzReleaseTrackId,
    musicBrainzReleaseId,
    musicBrainzReleaseGroupId,
    musicBrainzArtistIds,
    musicBrainzAlbumArtistIds,
    coverUrl,
    quality,
    totalBytes,
    downloadedBytes,
    status,
    savePath,
    addedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTask &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.trackTitle == this.trackTitle &&
          other.albumTitle == this.albumTitle &&
          other.artistName == this.artistName &&
          other.albumArtist == this.albumArtist &&
          other.trackVersion == this.trackVersion &&
          other.isrc == this.isrc &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.totalTracks == this.totalTracks &&
          other.totalDiscs == this.totalDiscs &&
          other.durationSeconds == this.durationSeconds &&
          other.year == this.year &&
          other.genre == this.genre &&
          other.copyright == this.copyright &&
          other.label == this.label &&
          other.barcode == this.barcode &&
          other.catalogNumber == this.catalogNumber &&
          other.releaseDate == this.releaseDate &&
          other.originalReleaseDate == this.originalReleaseDate &&
          other.releaseCountry == this.releaseCountry &&
          other.releaseStatus == this.releaseStatus &&
          other.releaseType == this.releaseType &&
          other.musicBrainzRecordingId == this.musicBrainzRecordingId &&
          other.musicBrainzReleaseTrackId == this.musicBrainzReleaseTrackId &&
          other.musicBrainzReleaseId == this.musicBrainzReleaseId &&
          other.musicBrainzReleaseGroupId == this.musicBrainzReleaseGroupId &&
          other.musicBrainzArtistIds == this.musicBrainzArtistIds &&
          other.musicBrainzAlbumArtistIds == this.musicBrainzAlbumArtistIds &&
          other.coverUrl == this.coverUrl &&
          other.quality == this.quality &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.status == this.status &&
          other.savePath == this.savePath &&
          other.addedAt == this.addedAt);
}

class DownloadTasksCompanion extends UpdateCompanion<DownloadTask> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<String> trackTitle;
  final Value<String> albumTitle;
  final Value<String> artistName;
  final Value<String?> albumArtist;
  final Value<String?> trackVersion;
  final Value<String?> isrc;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int?> totalTracks;
  final Value<int?> totalDiscs;
  final Value<int?> durationSeconds;
  final Value<int?> year;
  final Value<String?> genre;
  final Value<String?> copyright;
  final Value<String?> label;
  final Value<String?> barcode;
  final Value<String?> catalogNumber;
  final Value<String?> releaseDate;
  final Value<String?> originalReleaseDate;
  final Value<String?> releaseCountry;
  final Value<String?> releaseStatus;
  final Value<String?> releaseType;
  final Value<String?> musicBrainzRecordingId;
  final Value<String?> musicBrainzReleaseTrackId;
  final Value<String?> musicBrainzReleaseId;
  final Value<String?> musicBrainzReleaseGroupId;
  final Value<String?> musicBrainzArtistIds;
  final Value<String?> musicBrainzAlbumArtistIds;
  final Value<String> coverUrl;
  final Value<String> quality;
  final Value<int> totalBytes;
  final Value<int> downloadedBytes;
  final Value<String> status;
  final Value<String?> savePath;
  final Value<int> addedAt;
  const DownloadTasksCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.trackTitle = const Value.absent(),
    this.albumTitle = const Value.absent(),
    this.artistName = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.trackVersion = const Value.absent(),
    this.isrc = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.totalTracks = const Value.absent(),
    this.totalDiscs = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.copyright = const Value.absent(),
    this.label = const Value.absent(),
    this.barcode = const Value.absent(),
    this.catalogNumber = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.originalReleaseDate = const Value.absent(),
    this.releaseCountry = const Value.absent(),
    this.releaseStatus = const Value.absent(),
    this.releaseType = const Value.absent(),
    this.musicBrainzRecordingId = const Value.absent(),
    this.musicBrainzReleaseTrackId = const Value.absent(),
    this.musicBrainzReleaseId = const Value.absent(),
    this.musicBrainzReleaseGroupId = const Value.absent(),
    this.musicBrainzArtistIds = const Value.absent(),
    this.musicBrainzAlbumArtistIds = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.quality = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.savePath = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  DownloadTasksCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required String trackTitle,
    required String albumTitle,
    required String artistName,
    this.albumArtist = const Value.absent(),
    this.trackVersion = const Value.absent(),
    this.isrc = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.totalTracks = const Value.absent(),
    this.totalDiscs = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.year = const Value.absent(),
    this.genre = const Value.absent(),
    this.copyright = const Value.absent(),
    this.label = const Value.absent(),
    this.barcode = const Value.absent(),
    this.catalogNumber = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.originalReleaseDate = const Value.absent(),
    this.releaseCountry = const Value.absent(),
    this.releaseStatus = const Value.absent(),
    this.releaseType = const Value.absent(),
    this.musicBrainzRecordingId = const Value.absent(),
    this.musicBrainzReleaseTrackId = const Value.absent(),
    this.musicBrainzReleaseId = const Value.absent(),
    this.musicBrainzReleaseGroupId = const Value.absent(),
    this.musicBrainzArtistIds = const Value.absent(),
    this.musicBrainzAlbumArtistIds = const Value.absent(),
    required String coverUrl,
    required String quality,
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.savePath = const Value.absent(),
    required int addedAt,
  }) : trackId = Value(trackId),
       trackTitle = Value(trackTitle),
       albumTitle = Value(albumTitle),
       artistName = Value(artistName),
       coverUrl = Value(coverUrl),
       quality = Value(quality),
       addedAt = Value(addedAt);
  static Insertable<DownloadTask> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<String>? trackTitle,
    Expression<String>? albumTitle,
    Expression<String>? artistName,
    Expression<String>? albumArtist,
    Expression<String>? trackVersion,
    Expression<String>? isrc,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? totalTracks,
    Expression<int>? totalDiscs,
    Expression<int>? durationSeconds,
    Expression<int>? year,
    Expression<String>? genre,
    Expression<String>? copyright,
    Expression<String>? label,
    Expression<String>? barcode,
    Expression<String>? catalogNumber,
    Expression<String>? releaseDate,
    Expression<String>? originalReleaseDate,
    Expression<String>? releaseCountry,
    Expression<String>? releaseStatus,
    Expression<String>? releaseType,
    Expression<String>? musicBrainzRecordingId,
    Expression<String>? musicBrainzReleaseTrackId,
    Expression<String>? musicBrainzReleaseId,
    Expression<String>? musicBrainzReleaseGroupId,
    Expression<String>? musicBrainzArtistIds,
    Expression<String>? musicBrainzAlbumArtistIds,
    Expression<String>? coverUrl,
    Expression<String>? quality,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? status,
    Expression<String>? savePath,
    Expression<int>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (trackTitle != null) 'track_title': trackTitle,
      if (albumTitle != null) 'album_title': albumTitle,
      if (artistName != null) 'artist_name': artistName,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (trackVersion != null) 'track_version': trackVersion,
      if (isrc != null) 'isrc': isrc,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (totalTracks != null) 'total_tracks': totalTracks,
      if (totalDiscs != null) 'total_discs': totalDiscs,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (year != null) 'year': year,
      if (genre != null) 'genre': genre,
      if (copyright != null) 'copyright': copyright,
      if (label != null) 'label': label,
      if (barcode != null) 'barcode': barcode,
      if (catalogNumber != null) 'catalog_number': catalogNumber,
      if (releaseDate != null) 'release_date': releaseDate,
      if (originalReleaseDate != null)
        'original_release_date': originalReleaseDate,
      if (releaseCountry != null) 'release_country': releaseCountry,
      if (releaseStatus != null) 'release_status': releaseStatus,
      if (releaseType != null) 'release_type': releaseType,
      if (musicBrainzRecordingId != null)
        'music_brainz_recording_id': musicBrainzRecordingId,
      if (musicBrainzReleaseTrackId != null)
        'music_brainz_release_track_id': musicBrainzReleaseTrackId,
      if (musicBrainzReleaseId != null)
        'music_brainz_release_id': musicBrainzReleaseId,
      if (musicBrainzReleaseGroupId != null)
        'music_brainz_release_group_id': musicBrainzReleaseGroupId,
      if (musicBrainzArtistIds != null)
        'music_brainz_artist_ids': musicBrainzArtistIds,
      if (musicBrainzAlbumArtistIds != null)
        'music_brainz_album_artist_ids': musicBrainzAlbumArtistIds,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (quality != null) 'quality': quality,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (status != null) 'status': status,
      if (savePath != null) 'save_path': savePath,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  DownloadTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<String>? trackTitle,
    Value<String>? albumTitle,
    Value<String>? artistName,
    Value<String?>? albumArtist,
    Value<String?>? trackVersion,
    Value<String?>? isrc,
    Value<int?>? trackNumber,
    Value<int?>? discNumber,
    Value<int?>? totalTracks,
    Value<int?>? totalDiscs,
    Value<int?>? durationSeconds,
    Value<int?>? year,
    Value<String?>? genre,
    Value<String?>? copyright,
    Value<String?>? label,
    Value<String?>? barcode,
    Value<String?>? catalogNumber,
    Value<String?>? releaseDate,
    Value<String?>? originalReleaseDate,
    Value<String?>? releaseCountry,
    Value<String?>? releaseStatus,
    Value<String?>? releaseType,
    Value<String?>? musicBrainzRecordingId,
    Value<String?>? musicBrainzReleaseTrackId,
    Value<String?>? musicBrainzReleaseId,
    Value<String?>? musicBrainzReleaseGroupId,
    Value<String?>? musicBrainzArtistIds,
    Value<String?>? musicBrainzAlbumArtistIds,
    Value<String>? coverUrl,
    Value<String>? quality,
    Value<int>? totalBytes,
    Value<int>? downloadedBytes,
    Value<String>? status,
    Value<String?>? savePath,
    Value<int>? addedAt,
  }) {
    return DownloadTasksCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      trackTitle: trackTitle ?? this.trackTitle,
      albumTitle: albumTitle ?? this.albumTitle,
      artistName: artistName ?? this.artistName,
      albumArtist: albumArtist ?? this.albumArtist,
      trackVersion: trackVersion ?? this.trackVersion,
      isrc: isrc ?? this.isrc,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      totalTracks: totalTracks ?? this.totalTracks,
      totalDiscs: totalDiscs ?? this.totalDiscs,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      copyright: copyright ?? this.copyright,
      label: label ?? this.label,
      barcode: barcode ?? this.barcode,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      releaseDate: releaseDate ?? this.releaseDate,
      originalReleaseDate: originalReleaseDate ?? this.originalReleaseDate,
      releaseCountry: releaseCountry ?? this.releaseCountry,
      releaseStatus: releaseStatus ?? this.releaseStatus,
      releaseType: releaseType ?? this.releaseType,
      musicBrainzRecordingId:
          musicBrainzRecordingId ?? this.musicBrainzRecordingId,
      musicBrainzReleaseTrackId:
          musicBrainzReleaseTrackId ?? this.musicBrainzReleaseTrackId,
      musicBrainzReleaseId: musicBrainzReleaseId ?? this.musicBrainzReleaseId,
      musicBrainzReleaseGroupId:
          musicBrainzReleaseGroupId ?? this.musicBrainzReleaseGroupId,
      musicBrainzArtistIds: musicBrainzArtistIds ?? this.musicBrainzArtistIds,
      musicBrainzAlbumArtistIds:
          musicBrainzAlbumArtistIds ?? this.musicBrainzAlbumArtistIds,
      coverUrl: coverUrl ?? this.coverUrl,
      quality: quality ?? this.quality,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      savePath: savePath ?? this.savePath,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (trackTitle.present) {
      map['track_title'] = Variable<String>(trackTitle.value);
    }
    if (albumTitle.present) {
      map['album_title'] = Variable<String>(albumTitle.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (trackVersion.present) {
      map['track_version'] = Variable<String>(trackVersion.value);
    }
    if (isrc.present) {
      map['isrc'] = Variable<String>(isrc.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (totalTracks.present) {
      map['total_tracks'] = Variable<int>(totalTracks.value);
    }
    if (totalDiscs.present) {
      map['total_discs'] = Variable<int>(totalDiscs.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (copyright.present) {
      map['copyright'] = Variable<String>(copyright.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (catalogNumber.present) {
      map['catalog_number'] = Variable<String>(catalogNumber.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (originalReleaseDate.present) {
      map['original_release_date'] = Variable<String>(
        originalReleaseDate.value,
      );
    }
    if (releaseCountry.present) {
      map['release_country'] = Variable<String>(releaseCountry.value);
    }
    if (releaseStatus.present) {
      map['release_status'] = Variable<String>(releaseStatus.value);
    }
    if (releaseType.present) {
      map['release_type'] = Variable<String>(releaseType.value);
    }
    if (musicBrainzRecordingId.present) {
      map['music_brainz_recording_id'] = Variable<String>(
        musicBrainzRecordingId.value,
      );
    }
    if (musicBrainzReleaseTrackId.present) {
      map['music_brainz_release_track_id'] = Variable<String>(
        musicBrainzReleaseTrackId.value,
      );
    }
    if (musicBrainzReleaseId.present) {
      map['music_brainz_release_id'] = Variable<String>(
        musicBrainzReleaseId.value,
      );
    }
    if (musicBrainzReleaseGroupId.present) {
      map['music_brainz_release_group_id'] = Variable<String>(
        musicBrainzReleaseGroupId.value,
      );
    }
    if (musicBrainzArtistIds.present) {
      map['music_brainz_artist_ids'] = Variable<String>(
        musicBrainzArtistIds.value,
      );
    }
    if (musicBrainzAlbumArtistIds.present) {
      map['music_brainz_album_artist_ids'] = Variable<String>(
        musicBrainzAlbumArtistIds.value,
      );
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (savePath.present) {
      map['save_path'] = Variable<String>(savePath.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTasksCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('trackTitle: $trackTitle, ')
          ..write('albumTitle: $albumTitle, ')
          ..write('artistName: $artistName, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('trackVersion: $trackVersion, ')
          ..write('isrc: $isrc, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('totalTracks: $totalTracks, ')
          ..write('totalDiscs: $totalDiscs, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('year: $year, ')
          ..write('genre: $genre, ')
          ..write('copyright: $copyright, ')
          ..write('label: $label, ')
          ..write('barcode: $barcode, ')
          ..write('catalogNumber: $catalogNumber, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('originalReleaseDate: $originalReleaseDate, ')
          ..write('releaseCountry: $releaseCountry, ')
          ..write('releaseStatus: $releaseStatus, ')
          ..write('releaseType: $releaseType, ')
          ..write('musicBrainzRecordingId: $musicBrainzRecordingId, ')
          ..write('musicBrainzReleaseTrackId: $musicBrainzReleaseTrackId, ')
          ..write('musicBrainzReleaseId: $musicBrainzReleaseId, ')
          ..write('musicBrainzReleaseGroupId: $musicBrainzReleaseGroupId, ')
          ..write('musicBrainzArtistIds: $musicBrainzArtistIds, ')
          ..write('musicBrainzAlbumArtistIds: $musicBrainzAlbumArtistIds, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('quality: $quality, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('status: $status, ')
          ..write('savePath: $savePath, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadTasksTable downloadTasks = $DownloadTasksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloadTasks];
}

typedef $$DownloadTasksTableCreateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      required int trackId,
      required String trackTitle,
      required String albumTitle,
      required String artistName,
      Value<String?> albumArtist,
      Value<String?> trackVersion,
      Value<String?> isrc,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> totalTracks,
      Value<int?> totalDiscs,
      Value<int?> durationSeconds,
      Value<int?> year,
      Value<String?> genre,
      Value<String?> copyright,
      Value<String?> label,
      Value<String?> barcode,
      Value<String?> catalogNumber,
      Value<String?> releaseDate,
      Value<String?> originalReleaseDate,
      Value<String?> releaseCountry,
      Value<String?> releaseStatus,
      Value<String?> releaseType,
      Value<String?> musicBrainzRecordingId,
      Value<String?> musicBrainzReleaseTrackId,
      Value<String?> musicBrainzReleaseId,
      Value<String?> musicBrainzReleaseGroupId,
      Value<String?> musicBrainzArtistIds,
      Value<String?> musicBrainzAlbumArtistIds,
      required String coverUrl,
      required String quality,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      Value<String> status,
      Value<String?> savePath,
      required int addedAt,
    });
typedef $$DownloadTasksTableUpdateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      Value<int> trackId,
      Value<String> trackTitle,
      Value<String> albumTitle,
      Value<String> artistName,
      Value<String?> albumArtist,
      Value<String?> trackVersion,
      Value<String?> isrc,
      Value<int?> trackNumber,
      Value<int?> discNumber,
      Value<int?> totalTracks,
      Value<int?> totalDiscs,
      Value<int?> durationSeconds,
      Value<int?> year,
      Value<String?> genre,
      Value<String?> copyright,
      Value<String?> label,
      Value<String?> barcode,
      Value<String?> catalogNumber,
      Value<String?> releaseDate,
      Value<String?> originalReleaseDate,
      Value<String?> releaseCountry,
      Value<String?> releaseStatus,
      Value<String?> releaseType,
      Value<String?> musicBrainzRecordingId,
      Value<String?> musicBrainzReleaseTrackId,
      Value<String?> musicBrainzReleaseId,
      Value<String?> musicBrainzReleaseGroupId,
      Value<String?> musicBrainzArtistIds,
      Value<String?> musicBrainzAlbumArtistIds,
      Value<String> coverUrl,
      Value<String> quality,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      Value<String> status,
      Value<String?> savePath,
      Value<int> addedAt,
    });

class $$DownloadTasksTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackVersion => $composableBuilder(
    column: $table.trackVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalTracks => $composableBuilder(
    column: $table.totalTracks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDiscs => $composableBuilder(
    column: $table.totalDiscs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get copyright => $composableBuilder(
    column: $table.copyright,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalReleaseDate => $composableBuilder(
    column: $table.originalReleaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseStatus => $composableBuilder(
    column: $table.releaseStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzRecordingId => $composableBuilder(
    column: $table.musicBrainzRecordingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzReleaseTrackId => $composableBuilder(
    column: $table.musicBrainzReleaseTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzReleaseId => $composableBuilder(
    column: $table.musicBrainzReleaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzReleaseGroupId => $composableBuilder(
    column: $table.musicBrainzReleaseGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzArtistIds => $composableBuilder(
    column: $table.musicBrainzArtistIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicBrainzAlbumArtistIds => $composableBuilder(
    column: $table.musicBrainzAlbumArtistIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savePath => $composableBuilder(
    column: $table.savePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackVersion => $composableBuilder(
    column: $table.trackVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isrc => $composableBuilder(
    column: $table.isrc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalTracks => $composableBuilder(
    column: $table.totalTracks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDiscs => $composableBuilder(
    column: $table.totalDiscs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get copyright => $composableBuilder(
    column: $table.copyright,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalReleaseDate => $composableBuilder(
    column: $table.originalReleaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseStatus => $composableBuilder(
    column: $table.releaseStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzRecordingId => $composableBuilder(
    column: $table.musicBrainzRecordingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzReleaseTrackId => $composableBuilder(
    column: $table.musicBrainzReleaseTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzReleaseId => $composableBuilder(
    column: $table.musicBrainzReleaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzReleaseGroupId => $composableBuilder(
    column: $table.musicBrainzReleaseGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzArtistIds => $composableBuilder(
    column: $table.musicBrainzArtistIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicBrainzAlbumArtistIds => $composableBuilder(
    column: $table.musicBrainzAlbumArtistIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savePath => $composableBuilder(
    column: $table.savePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get trackTitle => $composableBuilder(
    column: $table.trackTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumTitle => $composableBuilder(
    column: $table.albumTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackVersion => $composableBuilder(
    column: $table.trackVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isrc =>
      $composableBuilder(column: $table.isrc, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
    column: $table.trackNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discNumber => $composableBuilder(
    column: $table.discNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalTracks => $composableBuilder(
    column: $table.totalTracks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDiscs => $composableBuilder(
    column: $table.totalDiscs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get copyright =>
      $composableBuilder(column: $table.copyright, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get catalogNumber => $composableBuilder(
    column: $table.catalogNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalReleaseDate => $composableBuilder(
    column: $table.originalReleaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseStatus => $composableBuilder(
    column: $table.releaseStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseType => $composableBuilder(
    column: $table.releaseType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzRecordingId => $composableBuilder(
    column: $table.musicBrainzRecordingId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzReleaseTrackId => $composableBuilder(
    column: $table.musicBrainzReleaseTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzReleaseId => $composableBuilder(
    column: $table.musicBrainzReleaseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzReleaseGroupId => $composableBuilder(
    column: $table.musicBrainzReleaseGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzArtistIds => $composableBuilder(
    column: $table.musicBrainzArtistIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicBrainzAlbumArtistIds => $composableBuilder(
    column: $table.musicBrainzAlbumArtistIds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get savePath =>
      $composableBuilder(column: $table.savePath, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$DownloadTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadTasksTable,
          DownloadTask,
          $$DownloadTasksTableFilterComposer,
          $$DownloadTasksTableOrderingComposer,
          $$DownloadTasksTableAnnotationComposer,
          $$DownloadTasksTableCreateCompanionBuilder,
          $$DownloadTasksTableUpdateCompanionBuilder,
          (
            DownloadTask,
            BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTask>,
          ),
          DownloadTask,
          PrefetchHooks Function()
        > {
  $$DownloadTasksTableTableManager(_$AppDatabase db, $DownloadTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<String> trackTitle = const Value.absent(),
                Value<String> albumTitle = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> trackVersion = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> totalTracks = const Value.absent(),
                Value<int?> totalDiscs = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> copyright = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> catalogNumber = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> originalReleaseDate = const Value.absent(),
                Value<String?> releaseCountry = const Value.absent(),
                Value<String?> releaseStatus = const Value.absent(),
                Value<String?> releaseType = const Value.absent(),
                Value<String?> musicBrainzRecordingId = const Value.absent(),
                Value<String?> musicBrainzReleaseTrackId = const Value.absent(),
                Value<String?> musicBrainzReleaseId = const Value.absent(),
                Value<String?> musicBrainzReleaseGroupId = const Value.absent(),
                Value<String?> musicBrainzArtistIds = const Value.absent(),
                Value<String?> musicBrainzAlbumArtistIds = const Value.absent(),
                Value<String> coverUrl = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> savePath = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
              }) => DownloadTasksCompanion(
                id: id,
                trackId: trackId,
                trackTitle: trackTitle,
                albumTitle: albumTitle,
                artistName: artistName,
                albumArtist: albumArtist,
                trackVersion: trackVersion,
                isrc: isrc,
                trackNumber: trackNumber,
                discNumber: discNumber,
                totalTracks: totalTracks,
                totalDiscs: totalDiscs,
                durationSeconds: durationSeconds,
                year: year,
                genre: genre,
                copyright: copyright,
                label: label,
                barcode: barcode,
                catalogNumber: catalogNumber,
                releaseDate: releaseDate,
                originalReleaseDate: originalReleaseDate,
                releaseCountry: releaseCountry,
                releaseStatus: releaseStatus,
                releaseType: releaseType,
                musicBrainzRecordingId: musicBrainzRecordingId,
                musicBrainzReleaseTrackId: musicBrainzReleaseTrackId,
                musicBrainzReleaseId: musicBrainzReleaseId,
                musicBrainzReleaseGroupId: musicBrainzReleaseGroupId,
                musicBrainzArtistIds: musicBrainzArtistIds,
                musicBrainzAlbumArtistIds: musicBrainzAlbumArtistIds,
                coverUrl: coverUrl,
                quality: quality,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                status: status,
                savePath: savePath,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required String trackTitle,
                required String albumTitle,
                required String artistName,
                Value<String?> albumArtist = const Value.absent(),
                Value<String?> trackVersion = const Value.absent(),
                Value<String?> isrc = const Value.absent(),
                Value<int?> trackNumber = const Value.absent(),
                Value<int?> discNumber = const Value.absent(),
                Value<int?> totalTracks = const Value.absent(),
                Value<int?> totalDiscs = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> copyright = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> catalogNumber = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> originalReleaseDate = const Value.absent(),
                Value<String?> releaseCountry = const Value.absent(),
                Value<String?> releaseStatus = const Value.absent(),
                Value<String?> releaseType = const Value.absent(),
                Value<String?> musicBrainzRecordingId = const Value.absent(),
                Value<String?> musicBrainzReleaseTrackId = const Value.absent(),
                Value<String?> musicBrainzReleaseId = const Value.absent(),
                Value<String?> musicBrainzReleaseGroupId = const Value.absent(),
                Value<String?> musicBrainzArtistIds = const Value.absent(),
                Value<String?> musicBrainzAlbumArtistIds = const Value.absent(),
                required String coverUrl,
                required String quality,
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> savePath = const Value.absent(),
                required int addedAt,
              }) => DownloadTasksCompanion.insert(
                id: id,
                trackId: trackId,
                trackTitle: trackTitle,
                albumTitle: albumTitle,
                artistName: artistName,
                albumArtist: albumArtist,
                trackVersion: trackVersion,
                isrc: isrc,
                trackNumber: trackNumber,
                discNumber: discNumber,
                totalTracks: totalTracks,
                totalDiscs: totalDiscs,
                durationSeconds: durationSeconds,
                year: year,
                genre: genre,
                copyright: copyright,
                label: label,
                barcode: barcode,
                catalogNumber: catalogNumber,
                releaseDate: releaseDate,
                originalReleaseDate: originalReleaseDate,
                releaseCountry: releaseCountry,
                releaseStatus: releaseStatus,
                releaseType: releaseType,
                musicBrainzRecordingId: musicBrainzRecordingId,
                musicBrainzReleaseTrackId: musicBrainzReleaseTrackId,
                musicBrainzReleaseId: musicBrainzReleaseId,
                musicBrainzReleaseGroupId: musicBrainzReleaseGroupId,
                musicBrainzArtistIds: musicBrainzArtistIds,
                musicBrainzAlbumArtistIds: musicBrainzAlbumArtistIds,
                coverUrl: coverUrl,
                quality: quality,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                status: status,
                savePath: savePath,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadTasksTable,
      DownloadTask,
      $$DownloadTasksTableFilterComposer,
      $$DownloadTasksTableOrderingComposer,
      $$DownloadTasksTableAnnotationComposer,
      $$DownloadTasksTableCreateCompanionBuilder,
      $$DownloadTasksTableUpdateCompanionBuilder,
      (
        DownloadTask,
        BaseReferences<_$AppDatabase, $DownloadTasksTable, DownloadTask>,
      ),
      DownloadTask,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadTasksTableTableManager get downloadTasks =>
      $$DownloadTasksTableTableManager(_db, _db.downloadTasks);
}
