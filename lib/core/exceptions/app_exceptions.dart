class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

class ApiException extends AppException {
  final int? statusCode;
  ApiException(super.message, {this.statusCode});
}

class AuthException extends AppException {
  AuthException(super.message);
}
