import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/whatsapp_number.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/user_profile.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

/// Screen for creating a new user account.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _whatsappConsent = true;
  bool _isLoading = false;
  AccountType _accountType = AccountType.student;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final scope = FoundItScope.of(context);
      final result = await scope.authService.signUp(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        whatsapp: _phoneController.text.trim(),
        accountType: _accountType,
        allowWhatsappContact: _whatsappConsent,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.requiresEmailConfirmation) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Verifikasi Email Anda'),
            content: Text(
              'Pendaftaran berhasil! Tautan verifikasi telah dikirim ke ${_emailController.text.trim()}.\n\n'
              'Silakan periksa kotak masuk (atau folder spam) email Anda dan lakukan konfirmasi sebelum masuk.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(false);
        }
      } else {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'Akun berhasil dibuat dan Anda telah masuk.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = e is AuthFailure
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun FoundIt',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bergabung untuk saling membantu menemukan barang hilang di UNSRAT.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Full Name ─────────────────────────────────────────────
                Text('Nama Lengkap *', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nama lengkap Anda',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Nama lengkap minimal 2 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ─────────────────────────────────────────────────
                Text('Email Kampus / Pribadi *', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email Anda',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email wajib diisi.';
                    }
                    if (!val.contains('@')) {
                      return 'Format email tidak valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Account Type ─────────────────────────────────────────
                DropdownButtonFormField<AccountType>(
                  initialValue: _accountType,
                  decoration: const InputDecoration(
                    labelText: 'Status Akademik *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: AccountType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (type) {
                          if (type != null) {
                            setState(() => _accountType = type);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // ── WhatsApp ──────────────────────────────────────────────
                Text('Nomor WhatsApp *', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Nomor Whatsapp Anda',
                    helperText: 'Contoh : 08xxxxxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nomor WhatsApp wajib diisi.';
                    }
                    if (normalizeWhatsappNumber(val) == null) {
                      return 'Nomor WhatsApp harus 10-15 digit angka.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────
                Text('Kata Sandi *', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return 'Kata sandi minimal 6 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm Password ──────────────────────────────────────
                Text('Konfirmasi Kata Sandi *', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(
                    hintText: 'Ulangi kata sandi',
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Kata sandi tidak cocok.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Consent Checkbox ──────────────────────────────────────
                CheckboxListTile(
                  value: _whatsappConsent,
                  onChanged: (val) =>
                      setState(() => _whatsappConsent = val ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'Saya bersedia dihubungi via WhatsApp oleh pihak penemu/pemilik barang terkait pengembalian barang.',
                    style: textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit CTA
                PrimaryButton(
                  label: 'Daftar Akun',
                  loading: _isLoading,
                  onPressed: _signUp,
                ),
                const SizedBox(height: 16),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun?', style: textTheme.bodySmall),
                    TextButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final loggedIn = await nav.push<bool>(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        if (loggedIn == true && mounted) {
                          nav.pop(true);
                        }
                      },
                      child: const Text('Masuk di sini'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
