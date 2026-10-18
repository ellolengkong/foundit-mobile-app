import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

/// Mock authentication service for M1 UI and workflow development.
///
/// Supports guest state, simulated login, sign up, logout, and a mock admin
/// mode toggle for testing admin features without real credentials.
class MockAuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserProfile? _currentUser;
  bool _isAdminMode = false;

  bool get isLoggedIn => _isLoggedIn;
  UserProfile? get currentUser => _currentUser;
  bool get isAdminMode => _isAdminMode;

  /// Whether current active session has admin privileges.
  /// In M1, this is active if [isAdminMode] is enabled or user role is admin.
  bool get canAccessAdmin =>
      _isLoggedIn && (_isAdminMode || (_currentUser?.isAdmin ?? false));

  /// Logs into mock session.
  void login({
    required String email,
    required String password,
    String? userId,
  }) {
    _isLoggedIn = true;
    final resolvedId = userId ??
        (email.trim().startsWith('user-')
            ? email.trim().split('@').first
            : 'user-001');

    _currentUser = UserProfile(
      id: resolvedId,
      fullName: 'Mahasiswa UNSRAT',
      email: email.trim(),
      role: 'user',
      contact: null, // No contact saved until explicitly added
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    notifyListeners();
  }

  /// Registers a new mock user and logs in.
  void signUp({
    required String fullName,
    required String email,
    required String password,
    String? whatsapp,
    bool allowWhatsappContact = false,
  }) {
    _isLoggedIn = true;
    final now = DateTime.now();
    final userId = 'user-${now.millisecondsSinceEpoch}';

    final hasContactInfo =
        (whatsapp != null && whatsapp.trim().isNotEmpty) ||
        allowWhatsappContact;

    _currentUser = UserProfile(
      id: userId,
      fullName: fullName.trim(),
      email: email.trim(),
      role: 'user',
      contact: hasContactInfo
          ? UserContact(
              userId: userId,
              whatsappNumber: whatsapp?.trim(),
              allowWhatsappContact: allowWhatsappContact,
              updatedAt: now,
            )
          : null,
      createdAt: now,
      updatedAt: now,
    );
    notifyListeners();
  }

  /// Logs out of mock session.
  void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    _isAdminMode = false;
    notifyListeners();
  }

  /// Toggles mock admin mode for testing.
  /// Per user rule: admin UI is only accessible through this mock toggle.
  void toggleAdminMode() {
    _isAdminMode = !_isAdminMode;
    notifyListeners();
  }

  /// Updates profile details and contact settings.
  void updateProfile({
    required String fullName,
    String? whatsapp,
    bool? allowWhatsappContact,
  }) {
    if (_currentUser != null) {
      final now = DateTime.now();
      UserContact? newContact;

      if (whatsapp != null || allowWhatsappContact != null) {
        newContact = UserContact(
          userId: _currentUser!.id,
          whatsappNumber: whatsapp ?? _currentUser!.contact?.whatsappNumber,
          allowWhatsappContact:
              allowWhatsappContact ??
              _currentUser!.contact?.allowWhatsappContact ??
              false,
          updatedAt: now,
        );
      } else {
        newContact = _currentUser!.contact;
      }

      _currentUser = _currentUser!.copyWith(
        fullName: fullName.trim(),
        contact: newContact,
        updatedAt: now,
      );
      notifyListeners();
    }
  }
}
