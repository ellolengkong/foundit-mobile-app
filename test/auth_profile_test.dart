import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/app.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';

void main() {
  group('Auth & Contact Privacy Unit Tests', () {
    test('login preserves email and leaves contact null if not yet saved', () {
      final auth = MockAuthService();
      auth.login(email: 'alice@unsrat.ac.id', password: 'password123');

      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser, isNotNull);
      expect(auth.currentUser!.email, 'alice@unsrat.ac.id');
      expect(auth.currentUser!.contact, isNull);
    });

    test('signUp without WhatsApp leaves contact null', () {
      final auth = MockAuthService();
      auth.signUp(
        fullName: 'Bob Smith',
        email: 'bob@unsrat.ac.id',
        password: 'password123',
        whatsapp: '',
        allowWhatsappContact: false,
      );

      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser!.fullName, 'Bob Smith');
      expect(auth.currentUser!.email, 'bob@unsrat.ac.id');
      expect(auth.currentUser!.contact, isNull);
    });

    test('signUp with WhatsApp and consent persists contact accurately', () {
      final auth = MockAuthService();
      auth.signUp(
        fullName: 'Carol Danvers',
        email: 'carol@unsrat.ac.id',
        password: 'password123',
        whatsapp: '081122334455',
        allowWhatsappContact: true,
      );

      expect(auth.currentUser!.contact, isNotNull);
      expect(auth.currentUser!.contact!.whatsappNumber, '081122334455');
      expect(auth.currentUser!.contact!.allowWhatsappContact, isTrue);
    });

    test(
      'updateProfile saves contact details only when explicitly updated',
      () {
        final auth = MockAuthService();
        auth.login(email: 'dave@unsrat.ac.id', password: 'password123');
        expect(auth.currentUser!.contact, isNull);

        auth.updateProfile(
          fullName: 'Dave Miller',
          whatsapp: '089988776655',
          allowWhatsappContact: true,
        );

        expect(auth.currentUser!.fullName, 'Dave Miller');
        expect(auth.currentUser!.contact, isNotNull);
        expect(auth.currentUser!.contact!.whatsappNumber, '089988776655');
        expect(auth.currentUser!.contact!.allowWhatsappContact, isTrue);
      },
    );

    test('logout resets session, user profile, and admin mode', () {
      final auth = MockAuthService();
      auth.login(email: 'admin@unsrat.ac.id', password: 'password123');
      auth.toggleAdminMode();
      expect(auth.isAdminMode, isTrue);

      auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.isAdminMode, isFalse);
    });
  });

  group('Profile Screen & Hidden Debug Menu Widget Tests', () {
    testWidgets('Profile shows un-saved status when contact is not stored', (
      tester,
    ) async {
      final auth = MockAuthService();
      final repo = MockReportRepository();
      final flagRepo = MockFlagRepository();

      // Log in with email, no WhatsApp contact saved
      auth.login(email: 'mahasiswa.baru@unsrat.ac.id', password: 'password123');

      await tester.pumpWidget(
        FoundItApp(
          repository: repo,
          authService: auth,
          flagRepository: flagRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Verify email is shown, WhatsApp status shows 'Nomor WhatsApp belum disimpan'
      expect(find.text('mahasiswa.baru@unsrat.ac.id'), findsOneWidget);
      expect(find.text('Nomor WhatsApp belum disimpan'), findsOneWidget);
      expect(find.text('081234567890'), findsNothing);

      // Verify normal profile does NOT have a visible admin toggle card
      expect(find.text('Pengujian & Pengembangan'), findsNothing);
      expect(find.text('Mode Mock Admin'), findsNothing);
    });

    testWidgets(
      'Long pressing version footer reveals hidden debug sheet with local disclaimer',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        auth.login(email: 'user@unsrat.ac.id', password: 'password123');

        await tester.pumpWidget(
          FoundItApp(
            repository: repo,
            authService: auth,
            flagRepository: flagRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Go to Profil
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();

        // Scroll down to version footer
        final versionFinder = find.text('FoundIt UNSRAT v1.0.0 (M1 Prototype)');
        await tester.scrollUntilVisible(
          versionFinder,
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(versionFinder, findsOneWidget);
        await tester.longPress(versionFinder);
        await tester.pumpAndSettle();

        // Verify debug bottom sheet appears with disclaimer
        expect(find.text('Akses Debug & Simulasi Lokal'), findsOneWidget);
        expect(
          find.textContaining('BUKAN mekanisme keamanan produksi'),
          findsOneWidget,
        );
        expect(find.text('Mode Mock Admin'), findsOneWidget);

        // Toggle admin mode inside sheet
        await tester.tap(find.text('Mode Mock Admin'));
        await tester.pumpAndSettle();

        expect(auth.isAdminMode, isTrue);
        expect(find.text('Buka Dashboard Admin'), findsOneWidget);
      },
    );
  });
}
