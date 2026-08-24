import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';

abstract class OnboardingDatasource {
  /// Creates the organization + first branch and returns a fresh Owner session.
  Future<AuthSessionEntity> createBusiness(Map<String, dynamic> body, {required String deviceId});

  Future<List<BusinessProfileEntity>> listBusinessTypes();
}
