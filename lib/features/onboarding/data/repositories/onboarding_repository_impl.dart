import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:mpos_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._datasource);

  final OnboardingDatasource _datasource;

  @override
  Future<Result<AuthSessionEntity>> createBusiness(Map<String, dynamic> body, {required String deviceId}) async {
    try {
      final session = await _datasource.createBusiness(body, deviceId: deviceId);
      return Result.success(data: session);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<BusinessProfileEntity>>> listBusinessTypes() async {
    try {
      final types = await _datasource.listBusinessTypes();
      return Result.success(data: types);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
