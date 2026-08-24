import 'package:equatable/equatable.dart';

class OrderWorkflowSettingsEntity extends Equatable {
  const OrderWorkflowSettingsEntity({
    required this.organizationId,
    required this.branchId,
    required this.usesBranchOverride,
    required this.workflowTemplate,
    required this.selfOrderEnabled,
    required this.selfOrderMode,
    required this.requireCashierApproval,
    required this.allowWalkInQr,
    required this.requireTableForAssignment,
    required this.cashierCanAssumeOrder,
  });

  final String organizationId;
  final String branchId;
  final bool usesBranchOverride;
  final String workflowTemplate;
  final bool selfOrderEnabled;
  final String selfOrderMode;
  final bool requireCashierApproval;
  final bool allowWalkInQr;
  final bool requireTableForAssignment;
  final bool cashierCanAssumeOrder;

  bool get isDirectPos => workflowTemplate == 'DirectPos';

  @override
  List<Object?> get props => [
    organizationId,
    branchId,
    usesBranchOverride,
    workflowTemplate,
    selfOrderEnabled,
    selfOrderMode,
    requireCashierApproval,
    allowWalkInQr,
    requireTableForAssignment,
    cashierCanAssumeOrder,
  ];
}
