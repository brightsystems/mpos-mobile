import 'dart:typed_data';

/// Uploads menu images to object storage and returns the public URL that is
/// stored on `MenuItem.ImageUrl`. Mirrors mpos-web `MposMediaService`.
abstract class MediaService {
  bool get isConfigured;

  Future<String> uploadMenuImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String organizationId,
  });
}

class MediaException implements Exception {
  MediaException(this.message);

  final String message;

  @override
  String toString() => message;
}

const int kMaxMenuImageBytes = 5 * 1024 * 1024;

String menuImageExtension(String fileName, String contentType) {
  final dot = fileName.lastIndexOf('.');
  if (dot != -1 && fileName.length - dot <= 5) {
    return fileName.substring(dot).toLowerCase();
  }

  switch (contentType) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    default:
      return '.jpg';
  }
}
