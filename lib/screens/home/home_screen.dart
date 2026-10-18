import 'package:flutter/material.dart';

import '../../core/constants/report_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../data/mock/foundit_scope.dart';
import '../../widgets/category_chips.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/report_card.dart';
import '../../widgets/search_field.dart';
import '../matches/matches_screen.dart';
import 'report_detail_screen.dart';

/// Beranda — the main home screen.
///
/// Shows the search field, type filter tabs (Semua/Hilang/Ditemukan),
/// category chips, a "Kemungkinan cocok" teaser, and the list of
/// recent public reports from [MockReportRepository].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Filter state ──────────────────────────────────────────────────────
  ReportType? _typeFilter;
  String? _categoryFilter;
  String? _campusAreaFilter;
  String? _buildingNameFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String _searchQuery = '';

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final result = await FilterBottomSheet.show(
      context,
      initialCriteria: FilterCriteria(
        type: _typeFilter,
        category: _categoryFilter,
        campusArea: _campusAreaFilter,
        buildingName: _buildingNameFilter,
        startDate: _startDateFilter,
        endDate: _endDateFilter,
      ),
    );

    if (result != null) {
      setState(() {
        _typeFilter = result.type;
        _categoryFilter = result.category;
        _campusAreaFilter = result.campusArea;
        _buildingNameFilter = result.buildingName;
        _startDateFilter = result.startDate;
        _endDateFilter = result.endDate;
      });
    }
  }

  void _clearActiveExtraFilters() {
    setState(() {
      _campusAreaFilter = null;
      _buildingNameFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = FoundItScope.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: scope.repository,
      builder: (context, _) {
        final reports = scope.repository.getPublicReports(
          type: _typeFilter,
          category: _categoryFilter,
          campusArea: _campusAreaFilter,
          buildingName: _buildingNameFilter,
          startDate: _startDateFilter,
          endDate: _endDateFilter,
          query: _searchQuery,
        );

        final hasLocationFilter =
            (_campusAreaFilter != null && _campusAreaFilter!.isNotEmpty) ||
            (_buildingNameFilter != null && _buildingNameFilter!.isNotEmpty);
        final hasDateFilter =
            _startDateFilter != null || _endDateFilter != null;

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FoundIt', style: textTheme.headlineLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Lost Today, Found Tomorrow.',
                        style: textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onFilterTap: _openFilterSheet,
                  ),
                ),
              ),

              // ── Type tabs ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _TypeTabs(
                    selected: _typeFilter,
                    onSelected: (type) => setState(() => _typeFilter = type),
                  ),
                ),
              ),

              // ── Category chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CategoryChips(
                    selectedKey: _categoryFilter,
                    onSelected: (key) => setState(() => _categoryFilter = key),
                  ),
                ),
              ),

              // ── Active Location Filter Chip (if applied via FilterSheet) ──
              if (hasLocationFilter)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Chip(
                          avatar: const Icon(Icons.location_on, size: 16),
                          label: Text(
                            _buildingNameFilter != null &&
                                    _buildingNameFilter!.isNotEmpty
                                ? '$_campusAreaFilter · $_buildingNameFilter'
                                : '$_campusAreaFilter',
                            style: textTheme.labelSmall,
                          ),
                          onDeleted: _clearActiveExtraFilters,
                          backgroundColor: AppColors.primarySoft,
                          deleteIconColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Active Date Filter Chip (if applied via FilterSheet) ──────
              if (hasDateFilter)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Chip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _startDateFilter != null && _endDateFilter != null
                                ? 'Tanggal: ${_startDateFilter!.day}/${_startDateFilter!.month} - ${_endDateFilter!.day}/${_endDateFilter!.month}'
                                : 'Filter Tanggal Aktif',
                            style: textTheme.labelSmall,
                          ),
                          onDeleted: () {
                            setState(() {
                              _startDateFilter = null;
                              _endDateFilter = null;
                            });
                          },
                          backgroundColor: AppColors.primarySoft,
                          deleteIconColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Kemungkinan cocok teaser ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchesScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: _MatchesTeaser(textTheme: textTheme),
                  ),
                ),
              ),

              // ── Section title ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Laporan Terbaru', style: textTheme.titleLarge),
                      Text(
                        '${reports.length} laporan',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Reports list or empty ─────────────────────────────────────
              if (reports.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'Tidak ada laporan ditemukan',
                    subtitle: 'Coba ubah filter atau kata kunci pencarian.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ReportCard(
                        report: report,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailScreen(reportId: report.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helper widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal tabs: Semua / Hilang / Ditemukan.
class _TypeTabs extends StatelessWidget {
  const _TypeTabs({required this.selected, required this.onSelected});

  final ReportType? selected;
  final ValueChanged<ReportType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: 'Semua',
          isActive: selected == null,
          onTap: () => onSelected(null),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: ReportType.lost.shortLabel,
          isActive: selected == ReportType.lost,
          onTap: () => onSelected(ReportType.lost),
          activeColor: AppColors.lost,
          activeBg: AppColors.lostSoft,
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: ReportType.found.shortLabel,
          isActive: selected == ReportType.found,
          onTap: () => onSelected(ReportType.found),
          activeColor: AppColors.found,
          activeBg: AppColors.foundSoft,
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor,
    this.activeBg,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? activeBg;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? AppColors.primary)
        : AppColors.textSecondary;
    final bg = isActive
        ? (activeBg ?? AppColors.primarySoft)
        : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Teaser card for the "Kemungkinan cocok" section.
class _MatchesTeaser extends StatelessWidget {
  const _MatchesTeaser({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kemungkinan cocok',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Laporan yang mungkin sesuai dengan pencarian kamu',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ],
      ),
    );
  }
}
