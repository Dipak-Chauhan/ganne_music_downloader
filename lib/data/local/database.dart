import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [DownloadTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // Drop and recreate table to avoid adding individual columns manually
        await m.issueCustomQuery('DROP TABLE IF EXISTS download_tasks');
        await m.createTable(downloadTasks);
      }
    },
  );

  Stream<List<DownloadTask>> watchAllTasks() => select(downloadTasks).watch();
  Stream<List<DownloadTask>> watchCompletedTasks() => 
      (select(downloadTasks)..where((t) => t.status.equals('completed'))).watch();
  Future<List<DownloadTask>> getAllTasks() => select(downloadTasks).get();
  Future<int> insertTask(DownloadTasksCompanion task) => into(downloadTasks).insert(task);
  Future<bool> updateTask(DownloadTask task) => update(downloadTasks).replace(task);
  Future<int> deleteTask(int id) => (delete(downloadTasks)..where((t) => t.id.equals(id))).go();
  Future<int> clearCompleted() => (delete(downloadTasks)..where((t) => t.status.equals('completed'))).go();
  Future<int> clearFailed() => (delete(downloadTasks)..where((t) => t.status.equals('failed'))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'qobuz_downloads.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
