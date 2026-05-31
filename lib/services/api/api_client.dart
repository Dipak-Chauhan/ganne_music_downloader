import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../data/secure_storage/secure_storage.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorage _secureStorage;

  ApiClient(this._secureStorage) : _dio = Dio(BaseOptions(baseUrl: ApiConstants.qobuzBaseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final credentials = await _secureStorage.getCredentials();
          final appId = credentials['appId'];
          final userAuthToken = credentials['userAuthToken'];

          if (appId != null && appId.isNotEmpty) {
            options.headers['x-app-id'] = appId;
          }
          if (userAuthToken != null && userAuthToken.isNotEmpty) {
            options.headers['x-user-auth-token'] = userAuthToken;
          }

          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
