/// Base exception class for EasyCheck Online.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

/// Authentication specific exception.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

/// Network / Real-time synchronization exception.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}
