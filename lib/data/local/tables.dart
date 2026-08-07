import 'package:drift/drift.dart';

class DownloadTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer()();
  TextColumn get trackTitle => text()();
  TextColumn get albumTitle => text()();
  TextColumn get artistName => text()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get trackVersion => text().nullable()();
  TextColumn get isrc => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get totalTracks => integer().nullable()();
  IntColumn get totalDiscs => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get copyright => text().nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get releaseDate => text().nullable()();
  TextColumn get originalReleaseDate => text().nullable()();
  TextColumn get releaseCountry => text().nullable()();
  TextColumn get releaseStatus => text().nullable()();
  TextColumn get releaseType => text().nullable()();
  TextColumn get musicBrainzRecordingId => text().nullable()();
  TextColumn get musicBrainzReleaseTrackId => text().nullable()();
  TextColumn get musicBrainzReleaseId => text().nullable()();
  TextColumn get musicBrainzReleaseGroupId => text().nullable()();
  TextColumn get musicBrainzArtistIds => text().nullable()();
  TextColumn get musicBrainzAlbumArtistIds => text().nullable()();
  TextColumn get coverUrl => text()();
  TextColumn get quality => text()();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, downloading, paused, completed, failed
  TextColumn get savePath => text().nullable()();
  IntColumn get addedAt => integer()();
}
