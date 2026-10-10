import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/usecase/usecase.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';
import 'package:mpos_mobile/features/auth/domain/repositories/auth_repository.dart';

class RequestOtpUsecase extends Usecase<Result<OtpRequestEntity>, String> {
  RequestOtpUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<OtpRequestEntity>> call(String phone) {
    return _repository.requestOtp(phone: phone);
  }
}

class VerifyOtpParams {
  const VerifyOtpParams({required this.requestId, required this.code, required this.deviceId, this.deviceName});

  final String requestId;
  final String code;
  final String deviceId;
  final String? deviceName;
}

class VerifyOtpUsecase extends Usecase<Result<SignInResult>, VerifyOtpParams> {
  VerifyOtpUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<SignInResult>> call(VerifyOtpParams params) {
    return _repository.verifyOtp(
      requestId: params.requestId,
      code: params.code,
      deviceId: params.deviceId,
      deviceName: params.deviceName,
    );
  }
}

class SelectTenantParams {
  const SelectTenantParams({required this.challengeId, required this.tenantId, required this.deviceId});

  final String challengeId;
  final String tenantId;
  final String deviceId;
}

/// Signs in to the chosen workspace when the phone is known in several.
class SelectTenantUsecase extends Usecase<Result<SignInResult>, SelectTenantParams> {
  SelectTenantUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<SignInResult>> call(SelectTenantParams params) {
    return _repository.selectTenant(
      challengeId: params.challengeId,
      tenantId: params.tenantId,
      deviceId: params.deviceId,
    );
  }
}

class ShiftLoginParams {
  const ShiftLoginParams({required this.token, required this.deviceId, this.deviceName});

  final String token;
  final String deviceId;
  final String? deviceName;
}

class ShiftLoginUsecase extends Usecase<Result<AuthSessionEntity>, ShiftLoginParams> {
  ShiftLoginUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSessionEntity>> call(ShiftLoginParams params) {
    return _repository.shiftLogin(token: params.token, deviceId: params.deviceId, deviceName: params.deviceName);
  }
}

class RefreshSessionParams {
  const RefreshSessionParams({required this.refreshToken, required this.deviceId});

  final String refreshToken;
  final String deviceId;
}

class RefreshSessionUsecase extends Usecase<Result<AuthSessionEntity>, RefreshSessionParams> {
  RefreshSessionUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSessionEntity>> call(RefreshSessionParams params) {
    return _repository.refresh(refreshToken: params.refreshToken, deviceId: params.deviceId);
  }
}

class SaveSessionUsecase extends Usecase<Result<void>, AuthSessionEntity> {
  SaveSessionUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(AuthSessionEntity session) {
    return _repository.saveSession(session);
  }
}

class LoadSessionUsecase extends Usecase<Result<AuthSessionEntity?>, NoParam> {
  LoadSessionUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSessionEntity?>> call(NoParam params) {
    return _repository.loadSavedSession();
  }
}

class LogoutUsecase extends Usecase<Result<void>, NoParam> {
  LogoutUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(NoParam params) {
    return _repository.logout();
  }
}
