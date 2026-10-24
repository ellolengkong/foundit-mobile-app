import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/report.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/report_card.dart';
import '../../widgets/report_status_badge.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../home/report_detail_screen.dart';
import 'edit_profile_screen.dart';

/// Profil screen displaying user info, My Reports, and auth actions.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _debugTapCount = 0;

  void _handleDebugTap(BuildContext context, FoundItScope scope) {
    if (!kDebugMode) return;
    _debugTapCount++;
    if (_debugTapCount >= 5) {
      _debugTapCount = 0;
      _showDebugSheet(context, scope);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);

    return ListenableBuilder(
      listenable: scope.authService,
      builder: (context, _) {
        final isLoggedIn = scope.authService.isLoggedIn;
        final user = scope.authService.currentUser;

        return Scaffold(
          appBar: AppBar(title: const Text('Profil Pengguna')),
          body: isLoggedIn && user != null
              ? _buildLoggedInView(context, scope, user)
              : _buildGuestView(context, scope),
        );
      },
    );
  }

  Widget _buildGuestView(BuildContext context, FoundItScope scope) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Anda Masuk sebagai Tamu',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sebagai tamu, Anda dapat mencari dan melihat laporan. Masuk atau daftar akun untuk membuat laporan baru, mengelola barang hilang, dan menghubungi pihak terkait.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Masuk ke Akun',
              icon: Icons.login,
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Daftar Akun Baru'),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _handleDebugTap(context, scope),
              onLongPress: kDebugMode ? () => _showDebugSheet(context, scope) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Text(
                  'FoundIt UNSRAT v1.0.0 (M1 Prototype)',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(
    BuildContext context,
    FoundItScope scope,
    dynamic user,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: scope.repository,
      builder: (context, _) {
        final myReports = scope.repository.getUserReports(user.id);

        return RefreshIndicator(
          onRefresh: () => scope.repository.refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
            // ── User Card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName
                                .trim()
                                .split(' ')
                                .map((w) => w[0])
                                .take(2)
                                .join()
                                .toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email != null && user.email!.isNotEmpty
                              ? user.email!
                              : 'Belum ada email',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.contact?.whatsappNumber != null &&
                                        user.contact!.whatsappNumber!.isNotEmpty
                                    ? '${user.contact!.whatsappNumber!} (${user.contact!.allowWhatsappContact ? "Kontak diizinkan" : "Kontak nonaktif"})'
                                    : 'Nomor WhatsApp belum disimpan',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.isAdmin
                                    ? AppColors.lostSoft
                                    : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.isAdmin
                                    ? 'Admin Kampus'
                                    : 'Mahasiswa UNSRAT',
                                style: textTheme.labelSmall?.copyWith(
                                  color: user.isAdmin
                                      ? AppColors.lost
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (scope.authService.canAccessAdmin) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminDashboardScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lostSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Dashboard Admin',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: AppColors.lost,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: AppColors.lost,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Profil',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── My Reports Section ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Laporan Saya (${myReports.length})',
                  style: textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (myReports.isEmpty)
              const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'Belum Ada Laporan',
                subtitle: 'Laporan kehilangan atau penemuan barang yang Anda buat akan muncul di sini.',
              )
            else
              ...myReports.map(
                (report) => _buildMyReportCard(context, report, scope),
              ),

            const SizedBox(height: 16),

            // ── Logout Button ─────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _showLogoutConfirm(context, scope),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Version Footer (Tap 5x or Long Press for Hidden Debug Access) ─
            Center(
              child: GestureDetector(
                onTap: () => _handleDebugTap(context, scope),
                onLongPress: kDebugMode ? () => _showDebugSheet(context, scope) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Text(
                    'FoundIt UNSRAT v1.0.0 (M1 Prototype)',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  }

  Widget _buildMyReportCard(
    BuildContext context,
    Report report,
    FoundItScope scope,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ReportCard(
            report: report,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportDetailScreen(reportId: report.id),
                ),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: ReportStatusBadge(status: report.status),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, FoundItScope scope) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await scope.authService.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anda telah keluar dari akun.')),
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _showDebugSheet(BuildContext context, FoundItScope scope) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final textTheme = Theme.of(ctx).textTheme;
          final isAdmin = scope.authService.isAdminMode;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.developer_mode, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Akses Debug & Simulasi Lokal',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lostSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lost.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.lost,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PERINGATAN: Akses ini hanya untuk simulasi pengujian prototipe M1 secara lokal, BUKAN mekanisme keamanan produksi. Hak akses admin di produksi ditentukan oleh server/RLS Supabase dan tidak dapat dimanipulasi dari klien.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: isAdmin,
                  onChanged: (val) {
                    scope.authService.toggleAdminMode();
                    setSheetState(() {});
                  },
                  title: const Text('Mode Mock Admin'),
                  subtitle: const Text(
                    'Aktifkan untuk menguji antarmuka dan dashboard moderasi admin.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (scope.authService.canAccessAdmin) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      Navigator.of(ctx).pop();
                      await Future.delayed(const Duration(milliseconds: 150));
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Buka Dashboard Admin'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
