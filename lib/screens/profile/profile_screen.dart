import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/report_enums.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/report.dart';
import '../../data/models/user_profile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/report_card.dart';
import '../../widgets/report_status_badge.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/forgot_password_screen.dart';
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
  bool _isDeletingAccount = false;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6666E8), Color(0xFF4545B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Positioned(
                    right: -32,
                    top: -45,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.explore_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'JELAJAHI FOUNDIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Anda Masuk sebagai Tamu',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Temukan laporan barang hilang dan ditemukan di sekitar kampus.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bergabung dan lakukan lebih banyak',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const _GuestBenefitRow(
                  icon: Icons.post_add_rounded,
                  title: 'Buat laporan barang',
                  subtitle: 'Laporkan barang hilang atau ditemukan.',
                ),
                const SizedBox(height: 12),
                const _GuestBenefitRow(
                  icon: Icons.manage_search_rounded,
                  title: 'Kelola laporan Anda',
                  subtitle: 'Pantau laporan dan hubungi pemilik barang.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Masuk ke Akun',
            icon: Icons.login_rounded,
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => _handleDebugTap(context, scope),
              onLongPress: kDebugMode
                  ? () => _showDebugSheet(context, scope)
                  : null,
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
  }

  Widget _buildLoggedInView(
    BuildContext context,
    FoundItScope scope,
    UserProfile user,
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
              _buildAccountCard(context, scope, user, textTheme),
              const SizedBox(height: 20),
              _buildReportActivitySummary(myReports, textTheme),
              const SizedBox(height: 20),
              _buildAccountSecurityCard(
                context,
                user,
                scope.authService,
                scope.authService.isEmailVerified,
                textTheme,
              ),
              const SizedBox(height: 24),

              // ── My Reports Section ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Saya',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Daftar barang yang Anda laporkan',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${myReports.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                  onLongPress: kDebugMode
                      ? () => _showDebugSheet(context, scope)
                      : null,
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

  Widget _buildReportActivitySummary(
    List<Report> reports,
    TextTheme textTheme,
  ) {
    final activeCount = reports
        .where((report) => report.status == ReportStatus.active)
        .length;
    final resolvedCount = reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Aktivitas',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ActivityMetric(
                value: reports.length,
                label: 'Total',
                icon: Icons.assignment_outlined,
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
              const SizedBox(width: 10),
              _ActivityMetric(
                value: activeCount,
                label: 'Aktif',
                icon: Icons.autorenew_rounded,
                color: AppColors.lost,
                background: AppColors.lostSoft,
              ),
              const SizedBox(width: 10),
              _ActivityMetric(
                value: resolvedCount,
                label: 'Selesai',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.found,
                background: AppColors.foundSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecurityCard(
    BuildContext context,
    UserProfile user,
    AuthService authService,
    bool isEmailVerified,
    TextTheme textTheme,
  ) {
    final email = user.email?.trim() ?? '';
    final statusColor = isEmailVerified ? AppColors.success : AppColors.lost;
    final statusBackground = isEmailVerified
        ? AppColors.foundSoft
        : AppColors.lostSoft;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan Akun',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                isEmailVerified
                    ? Icons.verified_user_outlined
                    : Icons.mark_email_unread_outlined,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmailVerified
                          ? 'Email terverifikasi'
                          : 'Email belum terverifikasi',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isEmailVerified ? 'Aman' : 'Perlu verifikasi',
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: email.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ForgotPasswordScreen(initialEmail: email),
                        ),
                      );
                    },
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Atur Ulang Kata Sandi'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isDeletingAccount
                  ? null
                  : () => _confirmAccountDeletion(context, authService),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Hapus Akun'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    AuthService authService,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await authService.deleteAccount(password: password);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Akun dan data terkait berhasil dihapus.'),
        ),
      );
    } on AuthFailure catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Widget _buildAccountCard(
    BuildContext context,
    FoundItScope scope,
    UserProfile user,
    TextTheme textTheme,
  ) {
    final admin = user.isAdmin;
    final accent = admin ? const Color(0xFF39356F) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: admin
              ? const [Color(0xFF544F9D), Color(0xFF39356F)]
              : const [Color(0xFF6666E8), Color(0xFF4545B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (admin ? AppColors.lost : AppColors.primary).withValues(
              alpha: 0.18,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(user.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        admin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.school_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          admin
                              ? 'Admin Kampus · ${user.accountType.label}'
                              : '${user.accountType.label} UNSRAT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: 'Edit Profil',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 19),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email != null && user.email!.isNotEmpty
                ? user.email!
                : 'Belum ada email',
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.contact?.whatsappNumber != null &&
                            user.contact!.whatsappNumber!.isNotEmpty
                        ? '${user.contact!.whatsappNumber!} · ${user.contact!.allowWhatsappContact ? "Kontak diizinkan" : "Kontak nonaktif"}'
                        : 'Nomor WhatsApp belum disimpan',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (scope.authService.canAccessAdmin) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.dashboard_customize_outlined, size: 19),
                label: const Text('Buka Dashboard Admin'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: accent,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return initials.isEmpty ? 'U' : initials;
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

class _GuestBenefitRow extends StatelessWidget {
  const _GuestBenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        key: Key('activity_metric_${label.toLowerCase()}'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(height: 5),
            Text(
              '$value',
              style: textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(label, style: textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorText = 'Kata sandi wajib diisi.');
      return;
    }
    if (_confirmationController.text.trim() != 'HAPUS') {
      setState(() => _errorText = 'Ketik HAPUS untuk mengonfirmasi.');
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
      title: const Text('Hapus Akun?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tindakan ini tidak dapat dibatalkan. Akun, semua laporan, kontak, '
              'dan foto laporan Anda akan dihapus permanen. Masukkan kata sandi '
              'dan ketik HAPUS untuk melanjutkan.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmationController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ketik HAPUS',
                prefixIcon: Icon(Icons.delete_outline),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Hapus Permanen'),
        ),
      ],
    );
  }
}
