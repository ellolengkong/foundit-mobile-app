import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/constants/locations.dart';
import '../core/constants/report_enums.dart';
import '../core/theme/app_colors.dart';
import 'primary_button.dart';

class FilterCriteria {
  const FilterCriteria({
    this.type,
    this.category,
    this.campusArea,
    this.buildingName,
    this.startDate,
    this.endDate,
  });

  final ReportType? type;
  final String? category;
  final String? campusArea;
  final String? buildingName;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasActiveFilters =>
      type != null ||
      (category != null && category!.isNotEmpty) ||
      (campusArea != null && campusArea!.isNotEmpty) ||
      (buildingName != null && buildingName!.isNotEmpty) ||
      startDate != null ||
      endDate != null;
}

/// Bottom sheet dialog for filtering reports on Beranda.
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key, required this.initialCriteria});

  final FilterCriteria initialCriteria;

  static Future<FilterCriteria?> show(
    BuildContext context, {
    required FilterCriteria initialCriteria,
  }) {
    return showModalBottomSheet<FilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterBottomSheet(initialCriteria: initialCriteria),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ReportType? _selectedType;
  late String? _selectedCategory;
  late String? _selectedArea;
  late String? _selectedBuilding;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialCriteria.type;
    _selectedCategory = widget.initialCriteria.category;
    _selectedArea = widget.initialCriteria.campusArea;
    _selectedBuilding = widget.initialCriteria.buildingName;
    _startDate = widget.initialCriteria.startDate;
    _endDate = widget.initialCriteria.endDate;
  }

  void _reset() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _selectedArea = null;
      _selectedBuilding = null;
      _startDate = null;
      _endDate = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      FilterCriteria(
        type: _selectedType,
        category: _selectedCategory,
        campusArea: _selectedArea,
        buildingName: _selectedBuilding,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  bool _isTodayFilter() {
    if (_startDate == null || _endDate == null) return false;
    final now = DateTime.now();
    return _startDate!.year == now.year &&
        _startDate!.month == now.month &&
        _startDate!.day == now.day &&
        _endDate!.year == now.year &&
        _endDate!.month == now.month &&
        _endDate!.day == now.day;
  }

  bool _isLastDaysFilter(int days) {
    if (_startDate == null || _endDate == null) return false;
    final diff = (_endDate!.difference(_startDate!).inDays).abs();
    return diff >= days - 1 && diff <= days + 1;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final availableBuildings = _selectedArea != null
        ? buildingsForArea(_selectedArea!)
        : <String>[];

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Laporan', style: textTheme.titleLarge),
              TextButton(onPressed: _reset, child: const Text('Reset')),
            ],
          ),
          const Divider(),
          const SizedBox(height: 12),

          // ── Jenis Laporan ────────────────────────────────────────────────
          Text('Jenis Laporan', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ReportType?>(
            segments: const [
              ButtonSegment<ReportType?>(value: null, label: Text('Semua')),
              ButtonSegment<ReportType?>(
                value: ReportType.lost,
                label: Text('Hilang'),
              ),
              ButtonSegment<ReportType?>(
                value: ReportType.found,
                label: Text('Ditemukan'),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (set) {
              setState(() => _selectedType = set.first);
            },
          ),
          const SizedBox(height: 16),

          // ── Kategori ─────────────────────────────────────────────────────
          Text('Kategori Barang', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              hintText: 'Semua Kategori',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Semua Kategori'),
              ),
              ...kCategories.map(
                (c) => DropdownMenuItem(value: c.key, child: Text(c.label)),
              ),
            ],
            onChanged: (val) => setState(() => _selectedCategory = val),
          ),
          const SizedBox(height: 16),

          // ── Lokasi Kampus ────────────────────────────────────────────────
          Text('Area Kampus / Fakultas', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _selectedArea,
            decoration: const InputDecoration(
              hintText: 'Semua Area Kampus',
              prefixIcon: Icon(Icons.school_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Semua Area Kampus'),
              ),
              ...kCampusAreas.map(
                (a) => DropdownMenuItem(
                  value: a,
                  child: Text(a, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _selectedArea = val;
                _selectedBuilding = null;
              });
            },
          ),
          const SizedBox(height: 16),

          // ── Gedung / Fasilitas ───────────────────────────────────────────
          if (_selectedArea != null && availableBuildings.isNotEmpty) ...[
            Row(
              children: [
                Text('Gedung / Fasilitas', style: textTheme.labelLarge),
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
              'Daftar gedung belum diverifikasi resmi UNSRAT.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              key: ValueKey('filter_building_$_selectedArea'),
              initialValue: _selectedBuilding,
              decoration: const InputDecoration(
                hintText: 'Semua Gedung',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Semua Gedung'),
                ),
                ...availableBuildings.map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Text(
                      isExampleBuilding(b) ? '$b (Contoh)' : b,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedBuilding = val),
            ),
            const SizedBox(height: 16),
          ],

          // ── Tanggal Kejadian ─────────────────────────────────────────────
          Text('Tanggal Kejadian', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: _startDate == null && _endDate == null,
                onSelected: (_) {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Hari Ini'),
                selected: _isTodayFilter(),
                onSelected: (_) {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = DateTime(now.year, now.month, now.day);
                    _endDate = DateTime(now.year, now.month, now.day);
                  });
                },
              ),
              FilterChip(
                label: const Text('7 Hari Terakhir'),
                selected: _isLastDaysFilter(7),
                onSelected: (_) {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(const Duration(days: 7));
                    _endDate = now;
                  });
                },
              ),
              FilterChip(
                label: const Text('30 Hari Terakhir'),
                selected: _isLastDaysFilter(30),
                onSelected: (_) {
                  final now = DateTime.now();
                  setState(() {
                    _startDate = now.subtract(const Duration(days: 30));
                    _endDate = now;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked.start;
                  _endDate = picked.end;
                });
              }
            },
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(
              _startDate != null && _endDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'Pilih Rentang Tanggal Kustom',
            ),
          ),
          const SizedBox(height: 20),

          PrimaryButton(label: 'Terapkan Filter', onPressed: _apply),
        ],
      ),
    );
  }
}
