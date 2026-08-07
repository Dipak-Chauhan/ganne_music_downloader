import 'package:drift/drift.dart' as drift;

import '../../data/local/database.dart';
import 'musicbrainz_service.dart';

class ResolvedTrackMetadata {
  final DownloadTask task;
  final MusicBrainzMetadata? musicBrainz;
  final MusicBrainzCoverArt? coverArt;

  const ResolvedTrackMetadata({
    required this.task,
    this.musicBrainz,
    this.coverArt,
  });

  String get title => _value(musicBrainz?.title) ?? task.trackTitle;
  String get artist => _value(musicBrainz?.artist) ?? task.artistName;
  String get album => _value(musicBrainz?.album) ?? task.albumTitle;
  String? get albumArtist =>
      _value(musicBrainz?.albumArtist) ?? _value(task.albumArtist);
  String? get date =>
      _value(musicBrainz?.date) ??
      _value(task.releaseDate) ??
      task.year?.toString();
  String? get originalDate =>
      _value(musicBrainz?.originalDate) ?? _value(task.originalReleaseDate);
  int? get year => _yearFromDate(date) ?? task.year;
  String? get genre => _value(musicBrainz?.genre) ?? _value(task.genre);
  String? get isrc => _value(musicBrainz?.isrc) ?? _value(task.isrc);
  int? get trackNumber => musicBrainz?.trackNumber ?? task.trackNumber;
  int? get totalTracks => musicBrainz?.totalTracks ?? task.totalTracks;
  int? get discNumber => musicBrainz?.discNumber ?? task.discNumber;
  int? get totalDiscs => musicBrainz?.totalDiscs ?? task.totalDiscs;
  String? get copyright => _value(task.copyright);
  String? get label => _value(musicBrainz?.label) ?? _value(task.label);
  String? get barcode => _value(musicBrainz?.barcode) ?? _value(task.barcode);
  String? get catalogNumber =>
      _value(musicBrainz?.catalogNumber) ?? _value(task.catalogNumber);
  String? get recordingId =>
      _value(musicBrainz?.recordingId) ?? _value(task.musicBrainzRecordingId);
  String? get releaseTrackId =>
      _value(musicBrainz?.releaseTrackId) ??
      _value(task.musicBrainzReleaseTrackId);
  String? get releaseId =>
      _value(musicBrainz?.releaseId) ?? _value(task.musicBrainzReleaseId);
  String? get releaseGroupId =>
      _value(musicBrainz?.releaseGroupId) ??
      _value(task.musicBrainzReleaseGroupId);

  String? get artistIds {
    final ids = musicBrainz?.artistIds;
    return ids != null && ids.isNotEmpty
        ? ids.join('; ')
        : _value(task.musicBrainzArtistIds);
  }

  String? get albumArtistIds {
    final ids = musicBrainz?.albumArtistIds;
    return ids != null && ids.isNotEmpty
        ? ids.join('; ')
        : _value(task.musicBrainzAlbumArtistIds);
  }

  String? get releaseCountry =>
      _value(musicBrainz?.releaseCountry) ?? _value(task.releaseCountry);
  String? get releaseStatus =>
      _value(musicBrainz?.releaseStatus) ?? _value(task.releaseStatus);
  String? get releaseType =>
      _value(musicBrainz?.releaseType) ?? _value(task.releaseType);

  Map<String, String> get flacTags {
    final tags = <String, String>{
      'TITLE': title,
      'ARTIST': artist,
      'ALBUM': album,
    };

    void add(String key, Object? value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) tags[key] = text;
    }

    add('ALBUMARTIST', albumArtist);
    add('ALBUM_ARTIST', albumArtist);
    add('TRACKNUMBER', trackNumber);
    add('TRACKTOTAL', totalTracks);
    add('TOTALTRACKS', totalTracks);
    add('DISCNUMBER', discNumber);
    add('DISCTOTAL', totalDiscs);
    add('TOTALDISCS', totalDiscs);
    add('DATE', date);
    add('ORIGINALDATE', originalDate);
    add('GENRE', genre);
    add('ISRC', isrc);
    add('COPYRIGHT', copyright);
    add('LABEL', label);
    add('BARCODE', barcode);
    add('CATALOGNUMBER', catalogNumber);
    add('VERSION', task.trackVersion);
    add('MUSICBRAINZ_TRACKID', recordingId);
    add('MUSICBRAINZ_RELEASETRACKID', releaseTrackId);
    add('MUSICBRAINZ_ALBUMID', releaseId);
    add('MUSICBRAINZ_RELEASEGROUPID', releaseGroupId);
    add('MUSICBRAINZ_ARTISTID', artistIds);
    add('MUSICBRAINZ_ALBUMARTISTID', albumArtistIds);
    add('RELEASECOUNTRY', releaseCountry);
    add('RELEASESTATUS', releaseStatus);
    add('RELEASETYPE', releaseType);
    return tags;
  }

  DownloadTask get persistedTask {
    if (musicBrainz == null) return task;
    return task.copyWith(
      trackTitle: title,
      albumTitle: album,
      artistName: artist,
      albumArtist: drift.Value(albumArtist),
      isrc: drift.Value(isrc),
      trackNumber: drift.Value(trackNumber),
      discNumber: drift.Value(discNumber),
      totalTracks: drift.Value(totalTracks),
      totalDiscs: drift.Value(totalDiscs),
      year: drift.Value(year),
      genre: drift.Value(genre),
      label: drift.Value(label),
      barcode: drift.Value(barcode),
      catalogNumber: drift.Value(catalogNumber),
      releaseDate: drift.Value(date),
      originalReleaseDate: drift.Value(originalDate),
      releaseCountry: drift.Value(releaseCountry),
      releaseStatus: drift.Value(releaseStatus),
      releaseType: drift.Value(releaseType),
      musicBrainzRecordingId: drift.Value(recordingId),
      musicBrainzReleaseTrackId: drift.Value(releaseTrackId),
      musicBrainzReleaseId: drift.Value(releaseId),
      musicBrainzReleaseGroupId: drift.Value(releaseGroupId),
      musicBrainzArtistIds: drift.Value(artistIds),
      musicBrainzAlbumArtistIds: drift.Value(albumArtistIds),
    );
  }

  static String? _value(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int? _yearFromDate(String? date) {
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }
}
