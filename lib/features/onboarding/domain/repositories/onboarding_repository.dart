import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';

abstract class OnboardingRepository {
  Future<Result<AuthSessionEntity>> createBusiness(Map<String, dynamic> body, {required String deviceId});

  Future<Result<List<BusinessProfileEntity>>> listBusinessTypes();
}
