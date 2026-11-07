/// Base failure representation for domain & service layer responses.
abstract class AppFailure {
  final String message;
  final String? code;

  const AppFailure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Generic system or unexpected failure.
class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.code});
}

/// Offline or connection failure.
class ConnectionFailure extends AppFailure {
  const ConnectionFailure(super.message, {super.code});
}

/// Authorization or role permission failure.
class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(super.message, {super.code});
}
