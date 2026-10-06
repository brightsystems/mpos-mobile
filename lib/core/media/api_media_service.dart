import 'dart:typed_data';

import 'package:mpos_mobile/core/media/media_service.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';

/// Uploads menu images through the MPOS API, which stores them in the
/// configured storage provider (Cloudinary or Supabase). No storage
/// credentials live on the device. Mirrors mpos-web `MposMediaService`.
class ApiMediaService implements MediaService {
  ApiMediaService(this._apiClient);

  final MposApiClient _apiClient;

  @override
  bool get isConfigured => true;

  @override
  Future<String> uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String organizationId,
  }) async {
    if (!contentType.startsWith('image/')) {
      throw MediaException('Only image files are allowed.');
    }

    if (bytes.lengthInBytes > kMaxMenuImageBytes) {
      throw MediaException('Image must be 5 MB or smaller.');
    }

    final response = await _apiClient.postMultipartFile<String>(
      '/organizations/$organizationId/media/images',
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return (json['publicUrl'] ?? json['PublicUrl'] ?? '') as String;
        }

        return '';
      },
    );

    final url = response.data;
    if (!response.success || url == null || url.isEmpty) {
      throw MediaException(response.message ?? 'Image upload failed.');
    }

    return url;
  }
}
