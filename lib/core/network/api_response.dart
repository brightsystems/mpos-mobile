class ApiResponse<T> {
  const ApiResponse({required this.success, this.data, this.message, this.errors = const []});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
    return ApiResponse(
      success: json['success'] as bool? ?? json['Success'] as bool? ?? false,
      data: json['data'] != null || json['Data'] != null ? fromJsonT(json['data'] ?? json['Data']) : null,
      message: json['message'] as String? ?? json['Message'] as String?,
      errors:
          (json['errors'] as List<dynamic>? ?? json['Errors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  final bool success;
  final T? data;
  final String? message;
  final List<String> errors;
}
