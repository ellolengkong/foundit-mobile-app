import 'package:flutter/material.dart';

import 'mock_auth_service.dart';
import 'mock_flag_repository.dart';
import 'mock_report_repository.dart';

/// Provides [MockReportRepository], [MockAuthService], and [MockFlagRepository] down the widget tree.
class FoundItScope extends InheritedWidget {
  const FoundItScope({
    super.key,
    required this.repository,
    required this.authService,
    required this.flagRepository,
    required super.child,
  });

  final MockReportRepository repository;
  final MockAuthService authService;
  final MockFlagRepository flagRepository;

  static FoundItScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FoundItScope>();
    assert(scope != null, 'No FoundItScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(FoundItScope oldWidget) {
    return repository != oldWidget.repository ||
        authService != oldWidget.authService ||
        flagRepository != oldWidget.flagRepository;
  }
}
