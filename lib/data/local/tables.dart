import 'package:drift/drift.dart';

class DownloadTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer()();
  TextColumn get trackTitle => text()();
  TextColumn get albumTitle => text()();
  TextColumn get artistName => text()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get trackVersion => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get coverUrl => text()();
  TextColumn get quality => text()();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, downloading, paused, completed, failed
  TextColumn get savePath => text().nullable()();
  IntColumn get addedAt => integer()();
}
