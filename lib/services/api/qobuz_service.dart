import 'package:dio/dio.dart';
import '../../data/models/qobuz_models.dart';
import '../../core/utils/crypto_utils.dart';
import '../../data/secure_storage/secure_storage.dart';
import 'api_client.dart';
import '../../core/exceptions/app_exceptions.dart';

class QobuzService {
  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  QobuzService(this._apiClient, this._secureStorage);

  Future<SearchResults> search(String query, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _apiClient.dio.get(
        'catalog/search',
        queryParameters: {
          'query': query,
          'limit': limit,
          'offset': offset,
        },
      );
      return SearchResults.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Unknown API Error', statusCode: e.response?.statusCode);
    }
  }

  Future<FetchedAlbumResponse> getAlbumInfo(String albumId) async {
    try {
      final response = await _apiClient.dio.get(
        'album/get',
        queryParameters: {
          'album_id': albumId,
          'extra': 'track_ids',
        },
      );
      return FetchedAlbumResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Unknown API Error', statusCode: e.response?.statusCode);
    }
  }

  Future<String> getDownloadUrl(int trackId, String qualityId) async {
    try {
      final credentials = await _secureStorage.getCredentials();
      final appSecret = credentials['appSecret'];
      if (appSecret == null || appSecret.isEmpty) {
        throw AuthException('Missing app secret, please login again.');
      }

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final rSig = CryptoUtils.generateSignature(
        trackId: trackId,
        qualityId: qualityId,
        timestamp: timestamp,
        appSecret: appSecret,
      );

      final response = await _apiClient.dio.get(
        'track/getFileUrl',
        queryParameters: {
          'format_id': qualityId,
          'intent': 'stream',
          'track_id': trackId,
          'request_ts': timestamp,
          'request_sig': rSig,
        },
      );

      return response.data['url'];
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Unknown API Error', statusCode: e.response?.statusCode);
    }
  }
}
