import 'app_exception.dart';

/// A value-type wrapper around [AppException] for use in providers/UI.
sealed class Failure {
  final String message;
  const Failure(this.message);

  factory Failure.fromException(AppException e) => switch (e) {
        ServerException() => ServerFailure(e.message),
        DataException() => DataFailure(e.message),
        AuthException() => AuthFailure(e.message),
        PermissionException() => PermissionFailure(e.message),
      };

  factory Failure.fromError(Object e) {
    if (e is AppException) return Failure.fromException(e);
    return ServerFailure(e.toString());
  }
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
