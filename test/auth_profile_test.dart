import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/app.dart';
import 'package:foundit/core/services/auth_service.dart';
import 'package:foundit/data/mock/foundit_scope.dart';
import 'package:foundit/data/mock/mock_auth_service.dart';
import 'package:foundit/data/mock/mock_flag_repository.dart';
import 'package:foundit/data/mock/mock_report_repository.dart';
import 'package:foundit/data/models/user_profile.dart';
import 'package:foundit/screens/auth/signup_screen.dart';

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

    test('signUp rejects a missing WhatsApp number', () async {
      final auth = MockAuthService();
      await expectLater(
        auth.signUp(
          fullName: 'Bob Smith',
          email: 'bob@unsrat.ac.id',
          password: 'password123',
          whatsapp: '',
        ),
        throwsA(isA<AuthFailure>()),
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('signUp stores a normalized WhatsApp number and consent', () async {
      final auth = MockAuthService();
      await auth.signUp(
        fullName: 'Carol Danvers',
        email: 'carol@unsrat.ac.id',
        password: 'password123',
        whatsapp: '081122334455',
        allowWhatsappContact: true,
      );

      expect(auth.currentUser!.contact, isNotNull);
      expect(auth.currentUser!.contact!.whatsappNumber, '6281122334455');
      expect(auth.currentUser!.contact!.allowWhatsappContact, isTrue);
    });

    test(
      'signUp defaults allowWhatsappContact to false when not specified',
      () async {
        final auth = MockAuthService();
        await auth.signUp(
          fullName: 'Carol Danvers',
          email: 'carol@unsrat.ac.id',
          password: 'password123',
          whatsapp: '081122334455',
        );

        expect(auth.currentUser!.contact, isNotNull);
        expect(auth.currentUser!.contact!.whatsappNumber, '6281122334455');
        expect(auth.currentUser!.contact!.allowWhatsappContact, isFalse);
      },
    );

    test(
      'signUp stores lecturer account type separately from admin role',
      () async {
        final auth = MockAuthService();
        await auth.signUp(
          fullName: 'Dosen UNSRAT',
          email: 'dosen@unsrat.ac.id',
          password: 'password123',
          whatsapp: '081122334455',
          accountType: AccountType.lecturer,
        );

        expect(auth.currentUser!.accountType, AccountType.lecturer);
        expect(auth.currentUser!.role, 'user');
        expect(auth.currentUser!.isAdmin, isFalse);
      },
    );

    test(
      'updateProfile can change contact permission without changing phone',
      () async {
        final auth = MockAuthService();
        await auth.signUp(
          fullName: 'Dave Miller',
          email: 'dave@unsrat.ac.id',
          password: 'password123',
          whatsapp: '089988776655',
          allowWhatsappContact: false,
        );

        await auth.updateProfile(
          fullName: 'Dave Updated',
          allowWhatsappContact: true,
        );

        expect(auth.currentUser!.fullName, 'Dave Updated');
        expect(auth.currentUser!.contact, isNotNull);
        expect(auth.currentUser!.contact!.whatsappNumber, '6289988776655');
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

    test('deleteAccount logs out the mock account', () async {
      final auth = MockAuthService();
      await auth.login(email: 'user@unsrat.ac.id', password: 'password123');

      await auth.deleteAccount(password: 'password123');

      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
    });
  });

  group('Profile Screen & Hidden Debug Menu Widget Tests', () {
    testWidgets('Signup requires a WhatsApp number', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      final submitButton = find.text('Daftar Akun');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Nomor WhatsApp *'), findsOneWidget);
      expect(find.text('Nomor WhatsApp wajib diisi.'), findsOneWidget);
    });

    testWidgets('Signup lets a new user select lecturer', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.text('Status Akademik *'), findsOneWidget);
      final roleField = find.byType(DropdownButtonFormField<AccountType>);
      await tester.ensureVisible(roleField);
      await tester.tap(roleField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dosen').last);
      await tester.pumpAndSettle();

      expect(find.text('Dosen'), findsOneWidget);
    });

    testWidgets(
      'Signup screen consent checkbox defaults to unchecked and can be toggled',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

        final consentCheckbox = find.byType(CheckboxListTile);
        expect(consentCheckbox, findsOneWidget);
        expect(tester.widget<CheckboxListTile>(consentCheckbox).value, isFalse);

        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        expect(tester.widget<CheckboxListTile>(consentCheckbox).value, isTrue);

        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        expect(tester.widget<CheckboxListTile>(consentCheckbox).value, isFalse);
      },
    );

    testWidgets(
      'Signup passes allowWhatsappContact as false by default to AuthService',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        await tester.pumpWidget(
          FoundItScope(
            authService: auth,
            repository: repo,
            flagRepository: flagRepo,
            child: const MaterialApp(home: SignupScreen()),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama lengkap Anda'),
          'Budi Pengguna',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Anda'),
          'budi.pengguna@unsrat.ac.id',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nomor Whatsapp Anda'),
          '081234567890',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Minimal 6 karakter'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ulangi kata sandi'),
          'password123',
        );

        final submitButton = find.text('Daftar Akun');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUser?.contact?.allowWhatsappContact, isFalse);
      },
    );

    testWidgets(
      'Signup passes allowWhatsappContact as true when checkbox is opted in by user',
      (tester) async {
        final auth = MockAuthService();
        final repo = MockReportRepository();
        final flagRepo = MockFlagRepository();

        await tester.pumpWidget(
          FoundItScope(
            authService: auth,
            repository: repo,
            flagRepository: flagRepo,
            child: const MaterialApp(home: SignupScreen()),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama lengkap Anda'),
          'Siti Pengguna',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Anda'),
          'siti.pengguna@unsrat.ac.id',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nomor Whatsapp Anda'),
          '081234567891',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Minimal 6 karakter'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Ulangi kata sandi'),
          'password123',
        );

        final consentCheckbox = find.byType(CheckboxListTile);
        await tester.ensureVisible(consentCheckbox);
        await tester.tap(consentCheckbox);
        await tester.pumpAndSettle();

        final submitButton = find.text('Daftar Akun');
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(auth.isLoggedIn, isTrue);
        expect(auth.currentUser?.contact?.allowWhatsappContact, isTrue);
      },
    );

    testWidgets('Edit profile does not ask for a WhatsApp number again', (
      tester,
    ) async {
      final auth = MockAuthService();
      await auth.signUp(
        fullName: 'Eka Mahasiswa',
        email: 'eka@unsrat.ac.id',
        password: 'password123',
        whatsapp: '081234567890',
      );

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Profil'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Nomor WhatsApp'), findsNothing);
    });

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
      expect(find.text('mahasiswa.baru@unsrat.ac.id'), findsNWidgets(2));
      expect(find.text('Nomor WhatsApp belum disimpan'), findsOneWidget);
      expect(find.text('081234567890'), findsNothing);

      // Verify normal profile does NOT have a visible admin toggle card
      expect(find.text('Pengujian & Pengembangan'), findsNothing);
      expect(find.text('Mode Mock Admin'), findsNothing);
    });

    testWidgets('Profile summarizes the current users report statuses', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = MockAuthService();
      final repository = MockReportRepository();
      await auth.login(email: 'user@unsrat.ac.id', password: 'password123');
      await repository.resolveReport('mock-001');

      await tester.pumpWidget(
        FoundItApp(
          repository: repository,
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan Aktivitas'), findsOneWidget);
      final totalMetricTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('activity_metric_total')),
              matching: find.byType(Text),
            ),
          )
          .map((widget) => widget.data)
          .toList();
      expect(totalMetricTexts, contains('3'));
      expect(
        find.descendant(
          of: find.byKey(const Key('activity_metric_aktif')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('activity_metric_selesai')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Account security shows verification and password reset', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = MockAuthService();
      await auth.login(email: 'user@unsrat.ac.id', password: 'password123');

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Keamanan Akun'), findsOneWidget);
      expect(find.text('Email terverifikasi'), findsOneWidget);

      await tester.tap(find.text('Atur Ulang Kata Sandi'));
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi'), findsOneWidget);
      final emailField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(emailField.controller?.text, 'user@unsrat.ac.id');
    });

    testWidgets('Deleting account requires password and HAPUS confirmation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = MockAuthService();
      await auth.login(email: 'user@unsrat.ac.id', password: 'password123');

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Akun?'), findsOneWidget);
      await tester.tap(find.text('Hapus Permanen'));
      await tester.pumpAndSettle();
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
      expect(auth.isLoggedIn, isTrue);

      await tester.enterText(find.byType(TextField).first, 'password123');
      await tester.enterText(find.byType(TextField).last, 'HAPUS');
      await tester.tap(find.text('Hapus Permanen'));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(find.text('Anda Masuk sebagai Tamu'), findsOneWidget);
    });

    testWidgets('Admin profile provides access to the moderation dashboard', (
      tester,
    ) async {
      final auth = MockAuthService();
      await auth.login(email: 'admin@unsrat.ac.id', password: 'password123');
      auth.toggleAdminMode();

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Buka Dashboard Admin'), findsOneWidget);
      expect(find.byTooltip('Edit Profil'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Laporan Saya'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Laporan Saya'), findsOneWidget);
    });

    testWidgets('Lecturer profile displays Dosen UNSRAT', (tester) async {
      final auth = MockAuthService();
      await auth.signUp(
        fullName: 'Dosen UNSRAT',
        email: 'dosen@unsrat.ac.id',
        password: 'password123',
        whatsapp: '081122334455',
        accountType: AccountType.lecturer,
      );

      await tester.pumpWidget(
        FoundItApp(
          repository: MockReportRepository(),
          authService: auth,
          flagRepository: MockFlagRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Dosen UNSRAT'), findsNWidgets(2));
      expect(find.text('Mahasiswa UNSRAT'), findsNothing);
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
