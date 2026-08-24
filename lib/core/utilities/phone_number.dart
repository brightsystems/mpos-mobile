/// Phone helpers aligned with mpos-api `PhoneNormalizer`.
class PhoneNumber {
  PhoneNumber._();

  static const emptyGuid = '00000000-0000-0000-0000-000000000000';

  /// Normalize Ethiopia-local and E.164 inputs the same way the API does.
  static String normalize(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return cleaned;
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    if (cleaned.startsWith('0')) {
      return '+251${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('251')) {
      return '+$cleaned';
    }
    return '+$cleaned';
  }

  /// Returns null when valid; otherwise an error message.
  static String? validate(String phone) {
    final normalized = normalize(phone);
    if (normalized.isEmpty) {
      return 'Enter your phone number.';
    }
    // Ethiopia mobile: +2519xxxxxxxx or +2517xxxxxxxx (10 digits after country code)
    final ethiopian = RegExp(r'^\+251[79]\d{8}$');
    final genericE164 = RegExp(r'^\+[1-9]\d{7,14}$');
    if (ethiopian.hasMatch(normalized) || genericE164.hasMatch(normalized)) {
      return null;
    }
    return 'Enter a valid phone number (e.g. 0911… or +251911…).';
  }

  static bool isUsableId(String? id) {
    final value = id?.trim() ?? '';
    return value.isNotEmpty && value != emptyGuid;
  }
}
