import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_screen.dart';

/// Screen shown after Supabase opens a password-recovery deep link.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isComplete = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FoundItScope.of(context).authService
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isComplete = true;
      });
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

  void _finish() {
    final navigator = Navigator.of(context);
    FoundItScope.of(context).authService.completePasswordRecovery();
    navigator.popUntil((route) => route.isFirst);
  }

  void _requestNewLink() {
    final navigator = Navigator.of(context);
    FoundItScope.of(context).authService.completePasswordRecovery();
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Ulang Kata Sandi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: widget.errorMessage != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.link_off,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tautan Reset Tidak Berlaku',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Minta Tautan Reset Baru',
                        onPressed: _requestNewLink,
                      ),
                    ],
                  )
                : _isComplete
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Kata Sandi Berhasil Diperbarui',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda sekarang dapat menggunakan kata sandi baru untuk masuk.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: 'Lanjut ke FoundIt',
                        onPressed: _finish,
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Buat Kata Sandi Baru',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gunakan sedikitnya 6 karakter untuk kata sandi baru Anda.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Kata Sandi Baru *', style: textTheme.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('recovery-password'),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Kata sandi minimal 6 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Konfirmasi Kata Sandi *',
                          style: textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const Key('recovery-password-confirmation'),
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmation,
                          decoration: InputDecoration(
                            hintText: 'Ulangi kata sandi baru',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmation
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',
                              onPressed: () => setState(
                                () => _obscureConfirmation =
                                    !_obscureConfirmation,
                              ),
                              icon: Icon(
                                _obscureConfirmation
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Simpan Kata Sandi Baru',
                          loading: _isLoading,
                          onPressed: _updatePassword,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
