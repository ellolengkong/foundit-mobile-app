import 'package:flutter/material.dart';

import '../../core/constants/categories.dart';
import '../../core/constants/locations.dart';
import '../../core/constants/report_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../data/models/report.dart';
import '../../widgets/primary_button.dart';

/// Form screen to create a new Lost or Found report.
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  ReportType _reportType = ReportType.lost;
  final _itemNameController = TextEditingController();
  String? _selectedCategory;
  String? _selectedArea;
  String? _selectedBuilding;
  final _specificLocationController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _eventDate = DateTime.now();

  bool _hasPhoto = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _specificLocationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori barang terlebih dahulu.')),
      );
      return;
    }
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih area kampus terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final scope = FoundItScope.of(context);
    final ownerId = scope.authService.currentUser?.id ?? 'user-001';
    final now = DateTime.now();

    final newReport = Report(
      id: 'report-${now.millisecondsSinceEpoch}',
      ownerId: ownerId,
      reportType: _reportType,
      itemName: _itemNameController.text.trim(),
      category: _selectedCategory!,
      campusArea: _selectedArea!,
      buildingName: _selectedBuilding,
      specificLocation: _specificLocationController.text.trim().isNotEmpty
          ? _specificLocationController.text.trim()
          : null,
      eventDate: _eventDate,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      photoPath: _hasPhoto ? '$ownerId/mock-photo.jpg' : null,
      createdAt: now,
      updatedAt: now,
    );

    scope.repository.createReport(newReport);

    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _reportType == ReportType.lost
              ? 'Laporan barang hilang berhasil diterbitkan!'
              : 'Laporan barang ditemukan berhasil diterbitkan!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availableBuildings = _selectedArea != null
        ? buildingsForArea(_selectedArea!)
        : <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Segmented Toggle Type ─────────────────────────────────────
            Text('Jenis Laporan', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReportType>(
              segments: const [
                ButtonSegment(
                  value: ReportType.lost,
                  label: Text('Barang Hilang'),
                  icon: Icon(Icons.search),
                ),
                ButtonSegment(
                  value: ReportType.found,
                  label: Text('Barang Ditemukan'),
                  icon: Icon(Icons.check_circle_outline),
                ),
              ],
              selected: {_reportType},
              onSelectionChanged: (set) {
                setState(() => _reportType = set.first);
              },
            ),
            const SizedBox(height: 20),

            // ── Photo Picker (Optional) ───────────────────────────────────
            Text('Foto Barang (Opsional)', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() => _hasPhoto = !_hasPhoto);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 1),
                    content: Text(
                      _hasPhoto
                          ? 'Foto barang simulasi terpilih.'
                          : 'Foto barang dihapus.',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: _hasPhoto ? AppColors.foundSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasPhoto ? AppColors.found : AppColors.border,
                    width: _hasPhoto ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasPhoto
                            ? Icons.check_circle
                            : Icons.add_a_photo_outlined,
                        size: 36,
                        color: _hasPhoto
                            ? AppColors.found
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasPhoto
                            ? 'Foto siap diunggah (Ketuk untuk hapus)'
                            : 'Ketuk untuk memilih foto barang',
                        style: textTheme.bodySmall?.copyWith(
                          color: _hasPhoto
                              ? AppColors.found
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Item Name ─────────────────────────────────────────────────
            Text('Nama Barang *', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                hintText: 'Contoh: KTM Biru, Dompet Kulit Cokelat',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 3) {
                  return 'Nama barang minimal 3 karakter.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Category ──────────────────────────────────────────────────
            Text('Kategori Barang *', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                hintText: 'Pilih kategori barang',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: kCategories
                  .map(
                    (c) => DropdownMenuItem(value: c.key, child: Text(c.label)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) =>
                  val == null ? 'Kategori wajib dipilih.' : null,
            ),
            const SizedBox(height: 20),

            // ── Campus Area ───────────────────────────────────────────────
            Text('Area Kampus / Fakultas *', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedArea,
              decoration: const InputDecoration(
                hintText: 'Pilih area kampus',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: kCampusAreas
                  .map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(a, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedArea = val;
                  _selectedBuilding = null;
                });
              },
              validator: (val) =>
                  val == null ? 'Area kampus wajib dipilih.' : null,
            ),
            const SizedBox(height: 20),

            // ── Building Name (Optional) ──────────────────────────────────
            if (_selectedArea != null && availableBuildings.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Gedung / Fasilitas (Opsional)',
                    style: textTheme.labelLarge,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Data Contoh',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Nama gedung di bawah belum diverifikasi resmi dengan pihak kampus.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('building_$_selectedArea'),
                initialValue: _selectedBuilding,
                decoration: const InputDecoration(
                  hintText: 'Pilih gedung jika diketahui (data contoh)',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
                items: availableBuildings
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text(
                          isExampleBuilding(b) ? '$b (Contoh)' : b,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBuilding = val),
              ),
              const SizedBox(height: 20),
            ],

            // ── Specific Location (Optional) ──────────────────────────────
            Text('Lokasi Spesifik (Opsional)', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _specificLocationController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Lantai 2, dekat meja dosen',
                prefixIcon: Icon(Icons.pin_drop_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // ── Event Date ────────────────────────────────────────────────
            Text('Tanggal Kejadian *', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Description (Optional) ────────────────────────────────────
            Text('Deskripsi Publik (Opsional)', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Deskripsikan ciri umum barang. Hindari menuliskan detail rahasia seperti nomor PIN atau isi saldo.',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠️ Jangan tuliskan nomor identitas lengkap, saldo, atau ciri rahasia bukti kepemilikan di sini.',
              style: textTheme.labelSmall?.copyWith(color: AppColors.lost),
            ),
            const SizedBox(height: 32),

            // ── Submit Button ─────────────────────────────────────────────
            PrimaryButton(
              label: 'Kirim Laporan',
              loading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
