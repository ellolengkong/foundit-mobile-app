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

    final profileNavFinder = find.ancestor(
      of: find.text('Profil'),
      matching: find.byType(GestureDetector),
    );
    final profileNavItem = tester.widget<GestureDetector>(profileNavFinder);
    expect(profileNavItem.behavior, HitTestBehavior.opaque);
    final touchSurfaceFinder = find.byKey(
      const ValueKey('nav-icon-touch-Profil'),
    );
    expect(touchSurfaceFinder, findsOneWidget);
    expect(
      find.descendant(
        of: touchSurfaceFinder,
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );

    final profileIcon = find.byIcon(Icons.person_outline);
    final press = await tester.startGesture(tester.getCenter(profileIcon));
    await tester.pump(const Duration(milliseconds: 100));
    final touchEffect = tester.widget<AnimatedScale>(
      find.descendant(
        of: touchSurfaceFinder,
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(touchEffect.scale, 0.72);
    expect(
      find.descendant(
        of: touchSurfaceFinder,
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );

    await press.up();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester
          .widget<AnimatedScale>(
            find.descendant(
              of: touchSurfaceFinder,
              matching: find.byType(AnimatedScale),
            ),
          )
          .scale,
      0.72,
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
