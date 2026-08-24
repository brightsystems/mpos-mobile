import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/auth/data/mappers/auth_tokens_mapper.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';

class OnboardingRemoteDatasource implements OnboardingDatasource {
  OnboardingRemoteDatasource(this._client);

  final MposApiClient _client;

  @override
  Future<AuthSessionEntity> createBusiness(Map<String, dynamic> body, {required String deviceId}) async {
    final response = await _client.post(
      '/onboarding/business',
      body: body,
      authenticated: true,
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        final auth = Map<String, dynamic>.from((map['auth'] ?? map['Auth']) as Map);
        return mapAuthTokens(auth, deviceId: deviceId, loginMethod: LoginMethod.otp);
      },
    );

    if (!response.success || response.data == null) {
      throw response.message ?? (response.errors.isNotEmpty ? response.errors.join(', ') : 'Onboarding failed.');
    }

    return response.data!;
  }

  @override
  Future<List<BusinessProfileEntity>> listBusinessTypes() async {
    final response = await _client.get(
      '/business-types',
      authenticated: true,
      fromJson: (json) {
        final list = json as List<dynamic>;
        return list
            .map((item) => BusinessProfileEntity.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      },
    );

    if (!response.success || response.data == null) {
      throw response.message ?? (response.errors.isNotEmpty ? response.errors.join(', ') : 'Failed to load business types.');
    }

    return response.data!;
  }
}
