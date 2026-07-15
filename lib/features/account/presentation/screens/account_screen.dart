import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/theme/theme_cubit.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Center(child: Text('Not signed in.'));
        }

        final session = state.session;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  (session.userName ?? session.userPhone).characters.first.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.padding),
              Text(
                session.userName ?? session.userPhone,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(session.userPhone, style: Theme.of(context).textTheme.bodySmall),
              if (session.branchName != null) ...[
                const SizedBox(height: 4),
                Text(session.branchName!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSizes.padding * 1.5),
              _AccountTile(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                trailing: 'Today',
                onTap: () => context.push('/account/dashboard'),
              ),
              _AccountTile(icon: Icons.badge_outlined, title: 'Role', trailing: session.role ?? 'Waiter'),
              _AccountTile(
                icon: Icons.store_outlined,
                title: 'Organization',
                trailing: session.organizationName ?? '—',
              ),
              _AccountTile(icon: Icons.format_paint_outlined, title: 'Theme', onTap: () => _showThemeDialog(context)),
              if (MposConfig.mockMode)
                _AccountTile(icon: Icons.science_outlined, title: 'Mode', trailing: 'Demo / Mock'),
              const SizedBox(height: AppSizes.padding),
              AppButton(
                text: 'End shift',
                buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                textColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context) {
    AppDialog.show(title: 'Theme', leftButtonText: 'Close', child: const _ThemeDialogBody());
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.icon, required this.title, this.trailing, this.onTap});

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: AppSizes.padding / 1.5),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (trailing != null)
              Text(trailing!, style: Theme.of(context).textTheme.bodySmall)
            else
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ThemeDialogBody extends StatelessWidget {
  const _ThemeDialogBody();

  @override
  Widget build(BuildContext context) {
    final isLight = context.watch<ThemeCubit>().state.isLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: const Text('Light mode'),
          value: isLight,
          onChanged: (value) => context.read<ThemeCubit>().setLightMode(value),
        ),
        SwitchListTile(
          title: const Text('Dark mode'),
          value: !isLight,
          onChanged: (value) => context.read<ThemeCubit>().setLightMode(!value),
        ),
      ],
    );
  }
}
