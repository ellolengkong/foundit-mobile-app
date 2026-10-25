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
          child: RefreshIndicator(
            onRefresh: () => scope.repository.refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Branded welcome panel ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6666E8), Color(0xFF4545B8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.22),
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
                              right: -30,
                              top: -42,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 20,
                              bottom: -55,
                              child: Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 24,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            13,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.travel_explore_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'FoundIt',
                                        style: textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'UNSRAT',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Temukan barangmu.',
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 1.12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lost Today, Found Tomorrow.',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Search ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: SearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onFilterTap: _openFilterSheet,
                    ),
                  ),
                ),

                // ── Type tabs ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                      onSelected: (key) =>
                          setState(() => _categoryFilter = key),
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Laporan Terbaru', style: textTheme.titleLarge),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${reports.length} laporan',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
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
