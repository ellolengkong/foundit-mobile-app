import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/flag_repository.dart';
import '../../core/services/report_repository.dart';

/// Provides [ReportRepository], [AuthService], and [FlagRepository] down the widget tree.
class FoundItScope extends InheritedWidget {
  const FoundItScope({
    super.key,
    required this.repository,
    required this.authService,
    required this.flagRepository,
    required super.child,
  });

  final ReportRepository repository;
  final AuthService authService;
  final FlagRepository flagRepository;

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
