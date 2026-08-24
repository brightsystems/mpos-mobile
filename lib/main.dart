import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/app/mpos_app.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!MposConfig.mockMode && MposConfig.supabaseConfigured) {
    await Supabase.initialize(url: MposConfig.supabaseUrl, anonKey: MposConfig.supabaseAnonKey);
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  await configureDependencies(sharedPreferences);

  runApp(const MposApp());
}
