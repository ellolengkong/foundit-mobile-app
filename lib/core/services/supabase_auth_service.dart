import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_profile.dart';
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

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  bool get isAdminMode => _isAdminMode;

  @override
  bool get canAccessAdmin =>
      _isLoggedIn && (_currentUser?.isAdmin ?? false);

  void _init() {
    final currentSession = _client.auth.currentSession;
    if (currentSession != null) {
      _loadUserProfile(currentSession.user);
    }

    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadUserProfile(session.user);
      } else {
        _currentUser = null;
        _isLoggedIn = false;
        notifyListeners();
      }
    });
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
          .select('id, full_name, role, created_at, updated_at')
          .eq('id', user.id)
          .maybeSingle();

      final contactRes = await _client
          .from('user_contacts')
          .select('user_id, whatsapp_number, allow_whatsapp_contact, updated_at')
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
          fullName:
              (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
          email: user.email,
          role: 'user',
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
        fullName:
            (user.userMetadata?['full_name'] as String?) ?? 'Pengguna',
        email: user.email,
        role: 'user',
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
    String? whatsapp,
    bool allowWhatsappContact = false,
  }) async {
    try {
      // 1. Register with Supabase Auth
      // The on_auth_user_created trigger on auth.users will insert public.profiles
      // automatically using raw_user_meta_data ->> 'full_name' with role='user'.
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        throw const AuthFailure('Gagal mendaftarkan akun. Silakan coba kembali.');
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

      // 3. If session is immediately active, save contact preference if provided
      final normalized = normalizeWhatsapp(whatsapp);
      if (normalized != null || allowWhatsappContact) {
        try {
          await _client.from('user_contacts').upsert({
            'user_id': user.id,
            'whatsapp_number': normalized,
            'allow_whatsapp_contact': allowWhatsappContact,
          });
        } catch (_) {
          // Contact saving is non-blocking on sign up
        }
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
    String? whatsapp,
    bool? allowWhatsappContact,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthFailure('Tidak ada pengguna yang sedang masuk.');
    }

    try {
      // 1. Update full_name in public.profiles
      await _client.from('profiles').update({
        'full_name': fullName.trim(),
      }).eq('id', user.id);

      // 2. Upsert user_contacts
      final normalized = normalizeWhatsapp(whatsapp);
      final optIn =
          allowWhatsappContact ??
          _currentUser?.contact?.allowWhatsappContact ??
          false;

      await _client.from('user_contacts').upsert({
        'user_id': user.id,
        'whatsapp_number': normalized,
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
      await _client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthFailure(mapAuthException(e));
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure('Gagal mengirim email reset kata sandi.');
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
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('0')) {
      return '62${digits.substring(1)}';
    }
    return digits;
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
