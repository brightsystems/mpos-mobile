import 'package:equatable/equatable.dart';

/// Response of `POST /auth/otp/request`.
class OtpRequestEntity extends Equatable {
  const OtpRequestEntity({required this.requestId, required this.expiresInSeconds, this.devOtp});

  factory OtpRequestEntity.fromJson(Map<String, dynamic> json) {
    return OtpRequestEntity(
      requestId: '${json['requestId'] ?? json['RequestId'] ?? ''}',
      expiresInSeconds: (json['expiresInSeconds'] ?? json['ExpiresInSeconds'] ?? 300) as int,
      devOtp: (json['devOtp'] ?? json['DevOtp']) as String?,
    );
  }

  final String requestId;
  final int expiresInSeconds;

  /// Only present when the API runs with `Auth:ExposeDevOtp=true` (dev).
  final String? devOtp;

  @override
  List<Object?> get props => [requestId, expiresInSeconds, devOtp];
}
