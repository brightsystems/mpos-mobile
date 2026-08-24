import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/dashboard/admin_dashboard_cubit.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }
    final session = authState.session;

    return BlocProvider(
      create: (_) => AdminDashboardCubit(getIt<AdminRepository>())
        ..load(orgId: session.organizationId, branchId: session.branchId, isOrgAdmin: session.isOrgAdmin),
      child: _DashboardView(session: session),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.session});

  final AuthSessionEntity session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: AppProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AdminDashboardCubit>().load(
              orgId: session.organizationId,
              branchId: session.branchId,
              isOrgAdmin: session.isOrgAdmin,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                _WelcomeBanner(session: session),
                const SizedBox(height: AppSizes.padding),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Open drafts',
                        value: '${state.summary.openDrafts}',
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSizes.padding / 2),
                    Expanded(
                      child: _MetricCard(
                        title: 'Paid today',
                        value: '${state.summary.paidTodayCount}',
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.padding / 2),
                _MetricCard(
                  title: 'Revenue today',
                  value: CurrencyFormatter.format(state.summary.paidTodayRevenue),
                  icon: Icons.payments_outlined,
                  wide: true,
                ),
                if (state.setupSteps.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.padding),
                  _SetupChecklist(steps: state.setupSteps, completed: state.completedSteps),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.session});

  final AuthSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.organizationName ?? 'Your business',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.branchName ?? 'All branches'} · ${session.roleLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon, this.wide = false});

  final String title;
  final String value;
  final IconData icon;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: AppSizes.padding / 2),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({required this.steps, required this.completed});

  final List<SetupStep> steps;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business setup ($completed/${steps.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    step.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: step.done ? colorScheme.primary : colorScheme.outlineVariant,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.padding / 1.5),
                  Expanded(child: Text(step.title, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
