import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foundit/app.dart';

void main() {
  testWidgets('FoundItApp smoke test - verifies Beranda and navigation', (
    WidgetTester tester,
  ) async {
    // Build FoundItApp and trigger a frame.
    await tester.pumpWidget(const FoundItApp());
    await tester.pumpAndSettle();

    // Verify app brand title is rendered.
    expect(find.text('FoundIt'), findsOneWidget);

    // Verify type tabs exist.
    expect(find.text('Semua'), findsWidgets);
    expect(find.text('Hilang'), findsWidgets);
    expect(find.text('Ditemukan'), findsWidgets);

    // Verify bottom navigation items exist.
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Verify center FAB exists.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
