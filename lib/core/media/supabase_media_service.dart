import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/media/media_service.dart';

class SupabaseMediaService implements MediaService {
  @override
  bool get isConfigured => MposConfig.supabaseConfigured;

  @override
  Future<String> uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String organizationId,
  }) async {
    if (!isConfigured) {
      throw MediaException('Supabase is not configured. Set MPOS_SUPABASE_URL and MPOS_SUPABASE_ANON_KEY.');
    }

    if (!contentType.startsWith('image/')) {
      throw MediaException('Only image files are allowed.');
    }

    if (bytes.lengthInBytes > kMaxMenuImageBytes) {
      throw MediaException('Image must be 5 MB or smaller.');
    }

    final bucket = MposConfig.supabaseMenuBucket;
    final path = '$organizationId/${_objectId()}${menuImageExtension(fileName, contentType)}';
    final storage = Supabase.instance.client.storage.from(bucket);

    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(cacheControl: '3600', upsert: false, contentType: contentType),
    );

    return storage.getPublicUrl(path);
  }

  String _objectId() {
    final random = Random();
    final suffix = List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
