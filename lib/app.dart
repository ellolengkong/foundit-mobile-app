import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/mock/foundit_scope.dart';
import 'data/mock/mock_auth_service.dart';
import 'data/mock/mock_flag_repository.dart';
import 'data/mock/mock_report_repository.dart';
import 'screens/shell/app_shell.dart';

/// Root application widget.
class FoundItApp extends StatefulWidget {
  const FoundItApp({
    super.key,
    this.repository,
    this.authService,
    this.flagRepository,
  });

  final MockReportRepository? repository;
  final MockAuthService? authService;
  final MockFlagRepository? flagRepository;

  @override
  State<FoundItApp> createState() => _FoundItAppState();
}

class _FoundItAppState extends State<FoundItApp> {
  late final MockReportRepository _repository;
  late final MockAuthService _authService;
  late final MockFlagRepository _flagRepository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockReportRepository();
    _authService = widget.authService ?? MockAuthService();
    _flagRepository = widget.flagRepository ?? MockFlagRepository();
  }

  @override
  Widget build(BuildContext context) {
    return FoundItScope(
      repository: _repository,
      authService: _authService,
      flagRepository: _flagRepository,
      child: MaterialApp(
        title: 'FoundIt UNSRAT',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
      ),
    );
  }
}
