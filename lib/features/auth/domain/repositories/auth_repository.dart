import '../entities/user_profile.dart';

abstract interface class AuthRepository {
  /// Sign in with email + password. Returns the loaded [UserProfile].
  Future<UserProfile> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Fetch the profile for the currently authenticated user.
  /// Throws [AuthException] if no session exists.
  Future<UserProfile> getProfile();

  /// Delete the current user's auth account. Irreversible.
  Future<void> deleteAccount();
}
