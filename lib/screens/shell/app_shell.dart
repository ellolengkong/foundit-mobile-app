import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../report/create_report_screen.dart';

/// AppShell provides the main scaffolding with three-part navigation:
/// - Beranda (left)
/// - Center Docked FloatingActionButton (+ Lapor)
/// - Profil (right)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _onFabPressed() {
    final scope = FoundItScope.of(context);
    if (!scope.authService.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Perlu Masuk Akun'),
          content: const Text(
            'Untuk membuat laporan kehilangan atau penemuan barang, Anda harus masuk terlebih dahulu demi keamanan dan validitas informasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.of(ctx).pop();
                final signedUp = await nav.push<bool>(
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
                if (signedUp == true && mounted) {
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => const CreateReportScreen(),
                    ),
                  );
                }
              },
              child: const Text('Daftar'),
            ),
            FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.of(ctx).pop();
                final loggedIn = await nav.push<bool>(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
                if (loggedIn == true && mounted) {
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => const CreateReportScreen(),
                    ),
                  );
                }
              },
              child: const Text('Masuk'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CreateReportScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [HomeScreen(), ProfileScreen()],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        tooltip: 'Lapor Barang',
        elevation: 4,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 9,
        color: AppColors.surface,
        elevation: 8,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItemButton(
                key: const ValueKey('nav-icon-touch-Beranda'),
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 48), // Notch space for FAB
              _NavItemButton(
                key: const ValueKey('nav-icon-touch-Profil'),
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatefulWidget {
  const _NavItemButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _isPressed = false;
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _releaseAfterFeedback() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(milliseconds: 160), () {
      if (mounted && _isPressed) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? AppColors.primary
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          _releaseTimer?.cancel();
          if (!_isPressed) setState(() => _isPressed = true);
        },
        onTapUp: (_) => _releaseAfterFeedback(),
        onTapCancel: () {
          _releaseTimer?.cancel();
          if (_isPressed) setState(() => _isPressed = false);
        },
        onTap: widget.onTap,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: _isPressed ? 0.72 : 1,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Icon(
                    widget.isSelected ? widget.activeIcon : widget.icon,
                    color: color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
