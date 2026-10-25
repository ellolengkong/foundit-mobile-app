import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/widgets/report_photo_viewer.dart';

void main() {
  testWidgets('only the full-screen photo supports zoom and can be closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportPhotoViewer(
            imageUrl: 'https://example.com/report-photo.jpg',
            height: 220,
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.byTooltip('Perbesar foto'));
    await tester.pumpAndSettle();

    final zoomViewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(zoomViewer.minScale, 1);
    expect(zoomViewer.maxScale, 5);
    expect(find.byTooltip('Tutup foto'), findsOneWidget);

    await tester.tap(find.byTooltip('Tutup foto'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
