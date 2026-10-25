import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/categories.dart';
import '../../core/constants/locations.dart';
import '../../core/constants/report_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/report.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/report_photo_viewer.dart';
import '../../widgets/report_status_badge.dart';
import '../../widgets/status_chip.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../matches/matches_screen.dart';
import '../report/create_report_screen.dart';

/// Detail screen for a single lost or found report.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: scope.repository,
      builder: (context, _) {
        final report = scope.repository.getReportById(reportId);

        if (report == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Laporan')),
            body: const Center(
              child: Text('Laporan tidak ditemukan atau telah dihapus.'),
            ),
          );
        }

        final currentUser = scope.authService.currentUser;
        final isOwner =
            currentUser != null &&
            (currentUser.id == report.ownerId ||
                scope.repository.isUserReportOwner(report.id, currentUser.id));
        final categoryLabel =
            categoryByKey(report.category)?.label ?? report.category;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Laporan'),
            actions: [
              if (!isOwner)
                IconButton(
                  icon: const Icon(Icons.flag_outlined, color: AppColors.error),
                  tooltip: 'Laporkan Laporan',
                  onPressed: () => _handleFlagPressed(context, report),
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Photo Banner ──────────────────────────────────────────
                Container(
                  height: 220,
                  color: AppColors.primarySoft,
                  child: report.publicPhotoUrl != null
                      ? ReportPhotoViewer(
                          imageUrl: report.publicPhotoUrl!,
                          height: 220,
                        )
                      : _buildPhotoFallback(report, textTheme),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Type & Status Badges ────────────────────────────
                      Row(
                        children: [
                          StatusChip(reportType: report.reportType),
                          const SizedBox(width: 8),
                          ReportStatusBadge(status: report.status),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Item Name ───────────────────────────────────────
                      Text(
                        report.itemName,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Meta Info Card ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.category_outlined,
                              label: 'Kategori',
                              value: categoryLabel,
                              textTheme: textTheme,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Tanggal Kejadian',
                              value: _formatDate(report.eventDate),
                              textTheme: textTheme,
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Lokasi Kampus',
                              value: _formatLocation(report),
                              textTheme: textTheme,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Public Description ──────────────────────────────
                      Text('Deskripsi Publik', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          report.description != null &&
                                  report.description!.isNotEmpty
                              ? report.description!
                              : 'Tidak ada deskripsi tambahan.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Privacy Note
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Data sensitif seperti nomor PIN/identitas disembunyikan untuk privasi.',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Kemungkinan Cocok Card ──────────────────────────
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MatchesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kemungkinan Cocok',
                                      style: textTheme.titleSmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Lihat daftar laporan yang berpotensi cocok.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Bottom Actions ──────────────────────────────────
                      if (isOwner) ...[
                        if (report.status == ReportStatus.active)
                          PrimaryButton(
                            label: 'Tandai Selesai (Ditemukan)',
                            icon: Icons.check,
                            onPressed: () async {
                              await scope.repository.resolveReport(report.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Laporan ditandai sebagai Selesai.',
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        else
                          PrimaryButton(
                            label: 'Aktifkan Kembali Laporan',
                            icon: Icons.refresh,
                            onPressed: () async {
                              await scope.repository.reopenReport(report.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Laporan diaktifkan kembali.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateReportScreen(initialReport: report),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Laporan'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, scope, report.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Hapus Laporan',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ] else ...[
                        PrimaryButton(
                          label: 'Hubungi via WhatsApp',
                          icon: Icons.chat_outlined,
                          onPressed: () =>
                              _handleWhatsAppContact(context, scope, report),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatLocation(Report report) {
    final buffer = StringBuffer(report.campusArea);
    if (report.buildingName != null &&
        report.buildingName!.isNotEmpty &&
        report.buildingName != 'Tidak tahu') {
      buffer.write(' · ${report.buildingName}');
      if (isExampleBuilding(report.buildingName)) {
        buffer.write(' (data contoh)');
      }
    }
    if (report.specificLocation != null &&
        report.specificLocation!.isNotEmpty) {
      buffer.write('\nDetail: ${report.specificLocation}');
    }
    return buffer.toString();
  }

  String _formatDate(DateTime d) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _handleWhatsAppContact(
    BuildContext context,
    FoundItScope scope,
    Report report,
  ) async {
    if (!scope.authService.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Perlu Masuk'),
          content: const Text(
            'Untuk menghubungi pemilik atau penemu barang via WhatsApp, Anda harus masuk ke akun terlebih dahulu demi keamanan bersama.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Nanti Saja'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const Text('Masuk'),
            ),
          ],
        ),
      );
      return;
    }

    if (!report.isPubliclyVisible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kontak hanya tersedia untuk laporan aktif dan terlihat.',
          ),
        ),
      );
      return;
    }

    try {
      final phone = await scope.authService.requestReporterWhatsapp(report.id);
      if (!context.mounted) return;
      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nomor WhatsApp tidak tersedia atau pemilik belum mengizinkan kontak.',
            ),
          ),
        );
        return;
      }

      final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (normalizedPhone.length < 10 || normalizedPhone.length > 15) {
        throw const FormatException(
          'Nomor WhatsApp yang diterima tidak valid.',
        );
      }

      final message =
          'Halo, saya melihat laporan "${report.itemName}" di FoundIt UNSRAT. '
          'Apakah barang ini masih tersedia untuk diverifikasi?';
      final uri = Uri.https('wa.me', '/$normalizedPhone', {'text': message});
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Perangkat tidak dapat membuka tautan WhatsApp.');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuka WhatsApp: $e')));
    }
  }

  void _handleFlagPressed(BuildContext context, Report report) {
    final scope = FoundItScope.of(context);
    if (!scope.authService.isLoggedIn) {
      _showLoginPromptForFlag(context, report);
      return;
    }
    _showFlagFormDialog(context, report);
  }

  void _showLoginPromptForFlag(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Perlu Masuk Akun'),
        content: const Text(
          'Untuk melaporkan indikasi penyalahgunaan atau pelanggaran, Anda harus masuk ke akun terlebih dahulu demi validitas laporan.',
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
              if (signedUp == true && context.mounted) {
                _showFlagFormDialog(context, report);
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
              if (loggedIn == true && context.mounted) {
                _showFlagFormDialog(context, report);
              }
            },
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  void _showFlagFormDialog(BuildContext context, Report report) {
    final scope = FoundItScope.of(context);
    final currentUserId = scope.authService.currentUser?.id;

    if (currentUserId == null) return;

    final isOwner =
        currentUserId == report.ownerId ||
        scope.repository.isUserReportOwner(report.id, currentUserId);

    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Anda tidak dapat melaporkan laporan milik Anda sendiri.',
          ),
        ),
      );
      return;
    }

    FlagReason selectedReason = FlagReason.spam;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Laporkan Laporan Ini'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih alasan mengapa laporan ini tidak pantas atau melanggar aturan:',
                ),
                const SizedBox(height: 12),
                RadioGroup<FlagReason>(
                  groupValue: selectedReason,
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedReason = val);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: FlagReason.values
                        .map(
                          (reason) => RadioListTile<FlagReason>(
                            title: Text(reason.label),
                            value: reason,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  final success = await scope.flagRepository.submitFlag(
                    reportId: report.id,
                    reporterId: currentUserId,
                    reason: selectedReason,
                  );

                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Laporan telah dikirim ke tim moderator untuk ditinjau.'
                            : 'Anda sudah pernah melaporkan laporan ini sebelumnya.',
                      ),
                    ),
                  );
                },
                child: const Text('Kirim Laporan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FoundItScope scope,
    String reportId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text(
          'Laporan yang dihapus tidak dapat dipulihkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await scope.repository.deleteReport(reportId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan berhasil dihapus.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus laporan: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback(Report report, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 56, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            'Foto Barang',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            report.photoPath == null || report.photoPath!.isEmpty
                ? 'Tidak ada foto yang dilampirkan'
                : 'Foto tersimpan di cloud',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
