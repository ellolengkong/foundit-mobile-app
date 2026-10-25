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
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                index: 0,
              ),
              const SizedBox(width: 48), // Notch space for FAB
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 21),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
