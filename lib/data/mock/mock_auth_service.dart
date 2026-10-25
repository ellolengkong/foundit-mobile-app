import '../../core/services/auth_service.dart';
import '../../core/utils/whatsapp_number.dart';
import '../models/user_profile.dart';

/// Mock authentication service for M1 UI and workflow development.
///
/// Supports guest state, simulated login, sign up, logout, and a mock admin
/// mode toggle for testing admin features without real credentials.
class MockAuthService extends AuthService {
  bool _isLoggedIn = false;
  UserProfile? _currentUser;
  bool _isAdminMode = false;
  bool _isPasswordRecovery = false;
  String? _passwordRecoveryError;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  bool get isAdminMode => _isAdminMode;

  /// Whether current active session has admin privileges.
  /// In M1, this is active if [isAdminMode] is enabled or user role is admin.
  @override
  bool get canAccessAdmin =>
      _isLoggedIn && (_isAdminMode || (_currentUser?.isAdmin ?? false));

  @override
  bool get isEmailVerified => _isLoggedIn;

  @override
  bool get isPasswordRecovery => _isPasswordRecovery;

  @override
  String? get passwordRecoveryError => _passwordRecoveryError;

  /// Logs into mock session.
  @override
  Future<void> login({
    required String email,
    required String password,
    String? userId,
  }) {
    _isPasswordRecovery = false;
    _isLoggedIn = true;
    final resolvedId =
        userId ??
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
    return Future.value();
  }

  /// Registers a new mock user and logs in.
  @override
  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String whatsapp,
    AccountType accountType = AccountType.student,
    bool allowWhatsappContact = false,
  }) async {
    final normalized = normalizeWhatsappNumber(whatsapp);
    if (normalized == null) {
      throw const AuthFailure(
        'Nomor WhatsApp wajib diisi dengan 10-15 digit yang valid.',
      );
    }

    _isPasswordRecovery = false;
    _isLoggedIn = true;
    final now = DateTime.now();
    final userId = 'user-${now.millisecondsSinceEpoch}';

    _currentUser = UserProfile(
      id: userId,
      fullName: fullName.trim(),
      email: email.trim(),
      role: 'user',
      accountType: accountType,
      contact: UserContact(
        userId: userId,
        whatsappNumber: normalized,
        allowWhatsappContact: allowWhatsappContact,
        updatedAt: now,
      ),
      createdAt: now,
      updatedAt: now,
    );
    notifyListeners();
    return Future.value(
      AuthResult(
        requiresEmailConfirmation: false,
        message: 'Akun berhasil dibuat dan Anda telah masuk.',
        user: _currentUser,
      ),
    );
  }

  /// Logs out of mock session.
  @override
  Future<void> logout() {
    _isPasswordRecovery = false;
    _isLoggedIn = false;
    _currentUser = null;
    _isAdminMode = false;
    notifyListeners();
    return Future.value();
  }

  /// Toggles mock admin mode for testing.
  /// Per user rule: admin UI is only accessible through this mock toggle.
  @override
  void toggleAdminMode() {
    _isAdminMode = !_isAdminMode;
    notifyListeners();
  }

  /// Updates profile details and contact settings.
  @override
  Future<void> updateProfile({
    required String fullName,
    bool? allowWhatsappContact,
  }) {
    if (_currentUser != null) {
      final now = DateTime.now();
      UserContact? newContact;

      if (allowWhatsappContact != null) {
        newContact = UserContact(
          userId: _currentUser!.id,
          whatsappNumber: _currentUser!.contact?.whatsappNumber,
          allowWhatsappContact: allowWhatsappContact,
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
    return Future.value();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return Future.value();
  }

  @override
  Future<void> updatePassword(String password) async {
    if (!_isPasswordRecovery || !_isLoggedIn) {
      throw const AuthFailure('Sesi pemulihan kata sandi tidak aktif.');
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    if (!_isLoggedIn || _currentUser == null) {
      throw const AuthFailure('Masuk ke akun untuk menghapus akun.');
    }
    if (password.trim().isEmpty) {
      throw const AuthFailure('Kata sandi wajib diisi.');
    }

    await logout();
  }

  @override
  void completePasswordRecovery() {
    if (!_isPasswordRecovery && _passwordRecoveryError == null) return;
    _isPasswordRecovery = false;
    _passwordRecoveryError = null;
    notifyListeners();
  }

  void beginPasswordRecoveryForTesting() {
    _isLoggedIn = true;
    _isPasswordRecovery = true;
    _passwordRecoveryError = null;
    _currentUser ??= UserProfile(
      id: 'recovery-user',
      fullName: 'Pengguna',
      email: 'recovery@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void failPasswordRecoveryForTesting(String message) {
    _isPasswordRecovery = false;
    _passwordRecoveryError = message;
    notifyListeners();
  }

  @override
  Future<String?> requestReporterWhatsapp(String reportId) async {
    if (!_isLoggedIn) {
      throw const AuthFailure('Masuk ke akun untuk meminta kontak WhatsApp.');
    }
    return null;
  }
}
