import 'package:equatable/equatable.dart';

class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.userPhone,
    this.userName,
    required this.organizationId,
    required this.branchId,
    this.organizationName,
    this.branchName,
    this.role,
    required this.deviceId,
  });

  factory AuthSessionEntity.fromJson(Map<String, dynamic> json) {
    return AuthSessionEntity(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
      userId: json['userId'] as String,
      userPhone: json['userPhone'] as String,
      userName: json['userName'] as String?,
      organizationId: json['organizationId'] as String,
      branchId: json['branchId'] as String,
      organizationName: json['organizationName'] as String?,
      branchName: json['branchName'] as String?,
      role: json['role'] as String?,
      deviceId: json['deviceId'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String userId;
  final String userPhone;
  final String? userName;
  final String organizationId;
  final String branchId;
  final String? organizationName;
  final String? branchName;
  final String? role;
  final String deviceId;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': expiresInSeconds,
    'userId': userId,
    'userPhone': userPhone,
    'userName': userName,
    'organizationId': organizationId,
    'branchId': branchId,
    'organizationName': organizationName,
    'branchName': branchName,
    'role': role,
    'deviceId': deviceId,
  };

  @override
  List<Object?> get props => [userId, branchId, accessToken];
}
