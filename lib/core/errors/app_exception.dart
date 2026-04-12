/// Base class for all domain-layer exceptions.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a Supabase / network call fails.
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Thrown when expected data is missing or malformed.
class DataException extends AppException {
  const DataException(super.message);
}

/// Thrown when the user is not authenticated.
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Thrown when the user lacks permission for an action.
class PermissionException extends AppException {
  const PermissionException(super.message);
}
