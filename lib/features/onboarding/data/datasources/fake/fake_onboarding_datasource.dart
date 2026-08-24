import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';

class FakeOnboardingDatasource implements OnboardingDatasource {
  @override
  Future<AuthSessionEntity> createBusiness(Map<String, dynamic> body, {required String deviceId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final orgName = (body['organizationName'] as String?) ?? MockFixtures.organizationName;
    final branchName = (body['branchName'] as String?) ?? MockFixtures.branchName;

    return AuthSessionEntity(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresInSeconds: 1800,
      userId: 'mock-new-owner',
      userPhone: (body['branchPhone'] as String?) ?? '0911000009',
      userName: 'New Owner',
      organizationId: MockFixtures.organizationId,
      branchId: MockFixtures.branchId,
      organizationName: orgName,
      branchName: branchName,
      organizationRole: MposRoles.owner,
      role: MposRoles.branchManager,
      loginMethod: LoginMethod.otp,
      deviceId: deviceId,
      memberships: [
        MembershipEntity(
          organizationId: MockFixtures.organizationId,
          organizationName: orgName,
          organizationRole: MposRoles.owner,
          branchId: MockFixtures.branchId,
          branchName: branchName,
          branchRole: MposRoles.branchManager,
        ),
      ],
    );
  }

  @override
  Future<List<BusinessProfileEntity>> listBusinessTypes() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      BusinessProfileEntity.cafeteria,
      BusinessProfileEntity(
        code: 'ConsultancyService',
        displayName: 'Consultancy Service',
        description: 'Professional services billed as packages, sessions, or hours.',
        floorMode: 'None',
        defaultWorkflowTemplate: 'DirectPos',
        vocabulary: BusinessTypeVocabulary(
          menu: 'Services',
          product: 'Engagement',
          servicePoint: 'Location',
          ticket: 'Invoice draft',
          staffAssociate: 'Consultant',
          cashier: 'Billing',
          walkIn: 'Ad-hoc client',
          openOrdersNav: 'Invoices',
          clientReference: 'Project ref',
          newOrderAction: 'New invoice',
        ),
        features: BusinessTypeFeatures(
          showServicePoints: false,
          requireClientReference: true,
          requireServicePoint: false,
          selfOrderQrSuggested: false,
          unitLabelsEnabled: true,
          showAssignedStaffOnReceipt: true,
        ),
        receipt: BusinessTypeReceipt(
          titleLabel: 'Invoice',
          showClientName: true,
          showClientReference: true,
          showServicePoint: false,
          showAssignedStaff: true,
          clientNameLabel: 'Client',
          clientReferenceLabel: 'Ref',
          servicePointLabel: 'Location',
          assignedStaffLabel: 'Consultant',
          footerNote: 'Thank you for your business.',
        ),
      ),
      BusinessProfileEntity(
        code: 'MedicalService',
        displayName: 'Medical Service',
        description: 'Clinic visits with rooms/bays, clinician capture, and reception billing.',
        floorMode: 'Stations',
        defaultWorkflowTemplate: 'WaiterToCashierApproval',
        vocabulary: BusinessTypeVocabulary(
          menu: 'Services & treatments',
          product: 'Service',
          servicePoint: 'Room',
          ticket: 'Visit',
          staffAssociate: 'Clinician',
          cashier: 'Reception',
          walkIn: 'Walk-in patient',
          openOrdersNav: 'Rooms',
          clientReference: 'Patient code',
          newOrderAction: 'New visit',
        ),
        features: BusinessTypeFeatures(
          showServicePoints: true,
          requireClientReference: true,
          requireServicePoint: false,
          selfOrderQrSuggested: false,
          unitLabelsEnabled: false,
          showAssignedStaffOnReceipt: true,
        ),
        receipt: BusinessTypeReceipt(
          titleLabel: 'Visit bill',
          showClientName: false,
          showClientReference: true,
          showServicePoint: true,
          showAssignedStaff: true,
          clientNameLabel: 'Patient',
          clientReferenceLabel: 'Patient',
          servicePointLabel: 'Room',
          assignedStaffLabel: 'Provider',
          footerNote: 'Keep this receipt for your records. No clinical notes printed.',
        ),
      ),
    ];
  }
}
