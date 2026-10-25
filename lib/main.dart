import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initializeIfConfigured();
  runApp(const FoundItApp());
}
