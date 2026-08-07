import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../secure_storage/secure_storage.dart';
import '../../services/api/api_client.dart';
import '../../services/api/qobuz_service.dart';
import '../../services/download/download_service.dart';
import '../local/database.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

final qobuzServiceProvider = Provider<QobuzService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return QobuzService(apiClient, secureStorage);
});

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final db = ref.watch(databaseProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final service = DownloadService.instance;
  unawaited(service.initialize(db, secureStorage));
  return service;
});
