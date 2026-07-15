import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/usecase/usecase.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/repositories/auth_repository.dart';

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
