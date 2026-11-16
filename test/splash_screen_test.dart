import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/widgets/foundit_splash_screen.dart';

void main() {
  testWidgets('splash screen shows white background and smaller logo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FoundItSplashScreen()));
    await tester.pumpAndSettle();

    expect(find.text('FoundIt'), findsOneWidget);
    expect(find.text('Temukan. Laporkan. Kembali.'), findsOneWidget);
    expect(find.text('UNIVERSITAS SAM RATULANGI'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == Colors.white,
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<AssetImage>().having(
        (image) => image.assetName,
        'assetName',
        'assets/icon/foundit_splash_logo.png',
      ),
    );
    expect(tester.getSize(find.byType(Image)), const Size(148, 148));
  });
}
