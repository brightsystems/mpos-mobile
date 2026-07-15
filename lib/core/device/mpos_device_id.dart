import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MposDeviceId {
  MposDeviceId._();

  static const _key = 'mpos_device_id';

  static Future<String> getOrCreate(SharedPreferences prefs) async {
    final existing = prefs.getString(_key);

    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = 'mpos-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
    await prefs.setString(_key, id);

    return id;
  }
}
