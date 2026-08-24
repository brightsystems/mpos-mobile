import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';

class SetupStep extends Equatable {
  const SetupStep({required this.title, required this.done});

  final String title;
  final bool done;

  @override
  List<Object?> get props => [title, done];
}

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.loading = true,
    this.summary = OrderSummaryModel.empty,
    this.setupSteps = const [],
    this.error,
  });

  final bool loading;
  final OrderSummaryModel summary;
  final List<SetupStep> setupSteps;
  final String? error;

  int get completedSteps => setupSteps.where((s) => s.done).length;

  AdminDashboardState copyWith({
    bool? loading,
    OrderSummaryModel? summary,
    List<SetupStep>? setupSteps,
    String? error,
  }) {
    return AdminDashboardState(
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      setupSteps: setupSteps ?? this.setupSteps,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, summary, setupSteps, error];
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardState());

  final AdminRepository _repository;

  Future<void> load({required String orgId, required String branchId, required bool isOrgAdmin}) async {
    emit(state.copyWith(loading: true, error: null));

    OrderSummaryModel summary = OrderSummaryModel.empty;
    if (branchId.isNotEmpty) {
      final summaryResult = await _repository.getOrderSummary(branchId);
      if (summaryResult.isSuccess && summaryResult.data != null) {
        summary = summaryResult.data!;
      }
    }

    final steps = isOrgAdmin && orgId.isNotEmpty ? await _buildSetupSteps(orgId) : <SetupStep>[];

    emit(state.copyWith(loading: false, summary: summary, setupSteps: steps));
  }

  Future<List<SetupStep>> _buildSetupSteps(String orgId) async {
    final org = await _repository.getOrganization(orgId);
    final taxes = await _repository.listTaxes(orgId);
    final payment = await _repository.getPaymentSettings(orgId);
    final mor = await _repository.getMorSettings(orgId);
    final bank = await _repository.getBankAccount(orgId);
    final branches = await _repository.listBranches(orgId);

    final orgData = org.data;
    final branchList = branches.data ?? const [];
    var menuHasItems = false;
    if (branchList.isNotEmpty) {
      final menu = await _repository.listBranchMenu(branchList.first.id);
      menuHasItems = (menu.data ?? const []).isNotEmpty;
    }

    return [
      SetupStep(title: 'Company profile & TIN', done: orgData != null && orgData.tin.isNotEmpty),
      SetupStep(title: 'Taxes configured', done: (taxes.data ?? const []).isNotEmpty),
      SetupStep(
        title: 'Payment methods enabled',
        done: payment.data != null &&
            (payment.data!.enableCash || payment.data!.enableChapa || payment.data!.enableTelebirr),
      ),
      SetupStep(title: 'MOR e-invoice set up', done: mor.data?.isConfigured == true),
      SetupStep(title: 'Bank & settlement', done: bank.data != null),
      SetupStep(title: 'At least one branch', done: branchList.isNotEmpty),
      SetupStep(title: 'Menu with items', done: menuHasItems),
    ];
  }
}
