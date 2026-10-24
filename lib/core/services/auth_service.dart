import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';

/// Exception thrown during authentication and profile operations.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result returned from sign up operations.
class AuthResult {
  const AuthResult({
    required this.requiresEmailConfirmation,
    this.message,
    this.user,
  });

  /// True if Supabase requires email verification before granting an active session.
  final bool requiresEmailConfirmation;

  /// User-friendly message explaining the sign up status.
  final String? message;

  /// The resulting user profile if an active session was immediately created.
  final UserProfile? user;
}

/// Contract for authentication and user profile management in FoundIt.
///
/// Implemented by [SupabaseAuthService] for real Supabase Auth
/// and [MockAuthService] for offline/mock UI development and widget tests.
abstract class AuthService extends ChangeNotifier {
  /// Whether an authenticated session is currently active.
  bool get isLoggedIn;

  /// The profile of the currently logged-in user, or null if guest.
  UserProfile? get currentUser;

  /// Whether simulated or mock admin mode is active.
  bool get isAdminMode;

  /// Whether the current user has admin access (via database role or mock toggle).
  bool get canAccessAdmin;

  /// Signs in an existing user with email and password.
  Future<void> login({
    required String email,
    required String password,
    String? userId,
  });

  /// Registers a new user account with email, password, and profile metadata.
  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? whatsapp,
    bool allowWhatsappContact = false,
  });

  /// Terminates the current authenticated session.
  Future<void> logout();

  /// Updates full name and optional contact preferences for the active user.
  Future<void> updateProfile({
    required String fullName,
    String? whatsapp,
    bool? allowWhatsappContact,
  });

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email);

  /// Toggles admin mode for testing/development.
  void toggleAdminMode();
}
