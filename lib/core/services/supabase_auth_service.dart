import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';
import '../utils/whatsapp_number.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Production authentication service powered by Supabase Auth and Database.
///
/// Handles user login, sign up, logout, session restoration,
/// and profile/contact synchronization with `public.profiles`
/// and `public.user_contacts`.
class SupabaseAuthService extends AuthService {
  SupabaseAuthService({SupabaseClient? client}) : _customClient = client {
    _init();
  }

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? SupabaseService.client;

  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoggedIn = false;
  UserProfile? _currentUser;
  bool _isAdminMode = false;
  bool _isPasswordRecovery = false;
  String? _passwordRecoveryError;

  static const passwordRecoveryRedirect =
      'com.example.foundit://reset-password';

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  bool get isAdminMode => _isAdminMode;

  @override
  bool get canAccessAdmin => _isLoggedIn && (_currentUser?.isAdmin ?? false);

  @override
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  @override
  bool get isPasswordRecovery => _isPasswordRecovery;

  @override
  String? get passwordRecoveryError => _passwordRecoveryError;

  void _init() {
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      _loadUserProfile(currentSession.user);
    }

    _authSubscription = _client.auth.onAuthStateChange.listen(
      (data) async {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecovery = true;
          _isLoggedIn = data.session != null;
          _passwordRecoveryError = null;
          notifyListeners();
        } else if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.signedOut) {
          _isPasswordRecovery = false;
          _passwordRecoveryError = null;
        }

        final session = data.session;
        if (session != null) {
          await _loadUserProfile(session.user);
        } else {
          _currentUser = null;
          _isLoggedIn = false;
          _isPasswordRecovery = false;
          _passwordRecoveryError = null;
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (error is AuthException) {
          _isPasswordRecovery = false;
          _passwordRecoveryError = error.statusCode == 'otp_expired'
              ? 'Tautan reset sudah kedaluwarsa atau pernah digunakan. Minta tautan baru dan buka tautan terbaru satu kali saja.'
              : 'Tautan reset tidak dapat diverifikasi. Minta tautan reset baru lalu buka dari email terbaru.';
          notifyListeners();
          return;
        }

        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Supabase authentication',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Loads `public.profiles` and `public.user_contacts` for [user].
  Future<void> _loadUserProfile(User user) async {
    try {
      final profileRes = await _client
          .from('profiles')
          .select('id, full_name, role, account_type, created_at, updated_at')
          .eq('id', user.id)
          .maybeSingle();

      final contactRes = await _client
          .from('user_contacts')
          .select(
            'user_id, whatsapp_number, allow_whatsapp_contact, updated_at',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      UserContact? contact;
      if (contactRes != null) {
        contact = UserContact(
          userId: contactRes['user_id'] as String,
          whatsappNumber: contactRes['whatsapp_number'] as String?,
          allowWhatsappContact:
              contactRes['allow_whatsapp_contact'] as bool? ?? false,
          updatedAt:
              DateTime.tryParse(contactRes['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }

      if (profileRes != null) {
        _currentUser = UserProfile(
          id: profileRes['id'] as String,
          fullName:
              (profileRes['full_name'] as String?)?.trim().isNotEmpty == true
              ? profileRes['full_name'] as String
              : (user.userMetadata?['full_name'] as String? ?? 'Pengguna'),
          email: user.email,
          role: profileRes['role'] as String? ?? 'user',
          accountType: AccountType.fromKey(
            profileRes['account_type'] as String?,
          ),
          contact: contact,
          createdAt:
              DateTime.tryParse(profileRes['created_at'] as String? ?? '') ??
              DateTime.now(),
          updatedAt:
              DateTime.tryParse(profileRes['updated_at'] as String? ?? '') ??
              DateTime.now(),
        );
      } else {
        _currentUser = UserProfile(
          id: user.id,
          fullName: (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
          email: user.email,
          role: 'user',
          accountType: AccountType.fromKey(
            user.userMetadata?['account_type'] as String?,
          ),
          contact: contact,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      _isLoggedIn = true;
      notifyListeners();
    } catch (_) {
      _currentUser = UserProfile(
        id: user.id,
        fullName: (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
        email: user.email,
        role: 'user',
        accountType: AccountType.fromKey(
          user.userMetadata?['account_type'] as String?,
        ),
        contact: null,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  @override
  Future<void> login({
    required String email,
    required String password,
    String? userId,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!);
      }
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal terhubung ke server Supabase. Pastikan koneksi internet Anda aktif.',
      );
    }
  }

  @override
  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    required String whatsapp,
    AccountType accountType = AccountType.student,
    bool allowWhatsappContact = false,
  }) async {
    final normalized = normalizeWhatsapp(whatsapp);
    if (normalized == null) {
      throw const AuthFailure(
        'Nomor WhatsApp wajib diisi dengan 10-15 digit yang valid.',
      );
    }

    try {
      // 1. Register with Supabase Auth
      // The on_auth_user_created trigger on auth.users will insert public.profiles
      // and the private contact row using the signup metadata.
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'account_type': accountType.key,
          'whatsapp_number': normalized,
          'allow_whatsapp_contact': allowWhatsappContact,
        },
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        throw const AuthFailure(
          'Gagal mendaftarkan akun. Silakan coba kembali.',
        );
      }

      // 2. Handle email confirmation if active
      if (session == null) {
        return AuthResult(
          requiresEmailConfirmation: true,
          message:
              'Pendaftaran berhasil! Tautan verifikasi telah dikirim ke ${email.trim()}. '
              'Silakan periksa kotak masuk email Anda dan klik tautan verifikasi sebelum masuk.',
        );
      }

      await _loadUserProfile(user);

      return AuthResult(
        requiresEmailConfirmation: false,
        message: 'Akun berhasil dibuat dan Anda telah masuk.',
        user: _currentUser,
      );
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal terhubung ke server Supabase. Pastikan koneksi internet Anda aktif.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Ignored
    } finally {
      _currentUser = null;
      _isLoggedIn = false;
      _isAdminMode = false;
      notifyListeners();
    }
  }

  @override
  Future<void> updateProfile({
    required String fullName,
    bool? allowWhatsappContact,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Tidak ada pengguna yang sedang masuk.');
    }

    try {
      // 1. Update full_name in public.profiles
      await _client
          .from('profiles')
          .update({'full_name': fullName.trim()})
          .eq('id', user.id);

      // 2. Update contact permission without changing the signup phone number.
      final optIn =
          allowWhatsappContact ??
          _currentUser?.contact?.allowWhatsappContact ??
          false;

      await _client.from('user_contacts').upsert({
        'user_id': user.id,
        'allow_whatsapp_contact': optIn,
      });

      // 3. Reload profile
      await _loadUserProfile(user);
    } on PostgrestException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal memperbarui profil. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: passwordRecoveryRedirect,
      );
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure('Gagal mengirim email reset kata sandi.');
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    if (!_isPasswordRecovery || !_isLoggedIn) {
      throw const AuthFailure(
        'Tautan pemulihan tidak aktif. Minta tautan reset kata sandi yang baru.',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal memperbarui kata sandi. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    if (_client.auth.currentUser == null) {
      throw const AuthFailure('Masuk ke akun untuk menghapus akun.');
    }

    try {
      await _client.functions.invoke(
        'delete-account',
        body: {'password': password},
      );
      await _client.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map
          ? details['error']?.toString()
          : details?.toString();
      throw AuthFailure(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Gagal menghapus akun. Silakan coba lagi.',
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal menghapus akun. Periksa koneksi internet Anda lalu coba lagi.',
      );
    }
  }

  @override
  void completePasswordRecovery() {
    if (!_isPasswordRecovery && _passwordRecoveryError == null) return;
    _isPasswordRecovery = false;
    _passwordRecoveryError = null;
    notifyListeners();
  }

  @override
  Future<String?> requestReporterWhatsapp(String reportId) async {
    if (!_isLoggedIn) {
      throw const AuthFailure('Masuk ke akun untuk meminta kontak WhatsApp.');
    }

    try {
      final result = await _client.rpc(
        'get_reporter_whatsapp_for_report',
        params: {'p_report_id': reportId},
      );
      if (result is! String || result.trim().isEmpty) return null;
      return result.trim();
    } on PostgrestException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        'Gagal meminta kontak WhatsApp. Periksa koneksi internet Anda.',
      );
    }
  }

  @override
  void toggleAdminMode() {
    // No-op in production — admin role is determined solely by
    // public.profiles.role fetched from the database.
    // toggleAdminMode() is only functional in MockAuthService.
  }

  @visibleForTesting
  static String? normalizeWhatsapp(String? raw) {
    return normalizeWhatsappNumber(raw);
  }

  @visibleForTesting
  static String mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Email atau kata sandi yang Anda masukkan salah.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('user_already_exists')) {
      return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk ke akun Anda.';
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak_password')) {
      return 'Kata sandi minimal 6 karakter.';
    }
    if (msg.contains('rate limit') ||
        msg.contains('over_email_send_rate_limit')) {
      return 'Terlalu banyak permintaan. Silakan coba lagi beberapa saat lagi.';
    }
    return e.message;
  }
}
