import 'dart:typed_data';

import 'package:mpos_mobile/core/media/media_service.dart';

/// Mock uploader for `MPOS_MOCK_MODE=true`. Returns a stable demo image URL so
/// the menu editor flow works end-to-end without a Supabase project.
class FakeMediaService implements MediaService {
  static const _demoImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=480&h=480&fit=crop',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=480&h=480&fit=crop',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=480&h=480&fit=crop',
  ];

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String organizationId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _demoImages[DateTime.now().millisecond % _demoImages.length];
  }
}
