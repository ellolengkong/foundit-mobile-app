import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/data/mock/foundit_scope.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/screens/admin/admin_dashboard_screen.dart';

void main() {
  testWidgets('AdminDashboardScreen renders tabs and report list', (
    tester,
  ) async {
    final auth = MockAuthService();
    final repo = MockReportRepository();
    final flagRepo = MockFlagRepository();

    auth.login(email: 'admin@unsrat.ac.id', password: 'password123');
    auth.toggleAdminMode();

    await tester.pumpWidget(
      FoundItScope(
        repository: repo,
        authService: auth,
        flagRepository: flagRepo,
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Admin (Mock)'), findsOneWidget);
    expect(find.text('Semua Laporan'), findsOneWidget);
    expect(find.text('Dilaporkan'), findsOneWidget);
    expect(find.text('Disembunyikan'), findsOneWidget);

    // Check if reports are rendered in the first tab
    expect(find.text('Dompet hitam'), findsWidgets);
  });
}
