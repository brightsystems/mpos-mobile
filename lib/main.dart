import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/app/mpos_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();

  await configureDependencies(sharedPreferences);

  runApp(const MposApp());
}
