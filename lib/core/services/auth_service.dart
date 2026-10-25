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

  /// Whether the active account's email address has been verified.
  bool get isEmailVerified;

  /// Whether the active session was opened from a password-recovery link.
  bool get isPasswordRecovery;

  /// User-facing error when a password-recovery link cannot be verified.
  String? get passwordRecoveryError;

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
    required String whatsapp,
    AccountType accountType = AccountType.student,
    bool allowWhatsappContact = false,
  });

  /// Terminates the current authenticated session.
  Future<void> logout();

  /// Updates full name and optional contact preferences for the active user.
  Future<void> updateProfile({
    required String fullName,
    bool? allowWhatsappContact,
  });

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email);

  /// Sets a new password for the active password-recovery session.
  Future<void> updatePassword(String password);

  /// Deletes the active account after verifying the user's password.
  Future<void> deleteAccount({required String password});

  /// Leaves the password-recovery flow after the user confirms completion.
  void completePasswordRecovery();

  /// Requests another report owner's WhatsApp number through a
  /// permission-checked backend operation.
  Future<String?> requestReporterWhatsapp(String reportId);

  /// Toggles admin mode for testing/development.
  void toggleAdminMode();
}
