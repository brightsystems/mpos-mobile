import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

/// A workspace (tenant) the user can sign in to; every session belongs to exactly one.
class TenantChoiceEntity extends Equatable {
  const TenantChoiceEntity({required this.tenantId, required this.slug, required this.businessName});

  factory TenantChoiceEntity.fromJson(Map<String, dynamic> json) {
    return TenantChoiceEntity(
      tenantId: '${json['tenantId'] ?? json['TenantId'] ?? ''}',
      slug: (json['slug'] ?? json['Slug'] ?? '') as String,
      businessName: (json['businessName'] ?? json['BusinessName'] ?? '') as String,
    );
  }

  final String tenantId;
  final String slug;
  final String businessName;

  @override
  List<Object?> get props => [tenantId, slug, businessName];
}

/// Outcome of verifying an OTP or choosing a workspace: either a signed-in [session], or the phone
/// is known in several workspaces and the user must pick one of [tenantChoices] (answered with
/// [tenantChallengeId]).
class SignInResult extends Equatable {
  const SignInResult.session(AuthSessionEntity this.session) : tenantChallengeId = null, tenantChoices = const [];

  const SignInResult.chooseTenant({required String this.tenantChallengeId, required this.tenantChoices})
    : session = null;

  final AuthSessionEntity? session;
  final String? tenantChallengeId;
  final List<TenantChoiceEntity> tenantChoices;

  bool get requiresTenantSelection => session == null;

  @override
  List<Object?> get props => [session, tenantChallengeId, tenantChoices];
}
