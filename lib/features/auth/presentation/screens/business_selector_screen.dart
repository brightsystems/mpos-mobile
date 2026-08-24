import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';

class BusinessSelectorScreen extends StatelessWidget {
  const BusinessSelectorScreen({super.key, this.allowCreate = true});

  final bool allowCreate;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final session = switch (state) {
          AuthNeedsBusinessSelection(:final session) => session,
          AuthAuthenticated(:final session) => session,
          AuthNeedsOnboarding(:final session) => session,
          _ => null,
        };

        if (session == null) {
          return const Scaffold(body: Center(child: Text('Sign in to continue.')));
        }

        final businesses = session.selectableBusinesses;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Your businesses'),
            actions: [
              TextButton(
                onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
                child: const Text('Sign out'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSizes.padding),
            children: [
              Text(
                businesses.isEmpty ? 'No businesses yet' : 'Select a business to continue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Signed in as ${session.userPhone}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSizes.padding),
              ...businesses.map((membership) {
                final selected = membership.organizationId == session.organizationId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                  child: _BusinessTile(
                    membership: membership,
                    selected: selected,
                    onTap: () => context.read<AuthBloc>().add(AuthBusinessSelected(membership)),
                  ),
                );
              }),
              if (allowCreate) ...[
                const SizedBox(height: AppSizes.padding),
                AppButton(
                  text: 'Create another business',
                  onTap: () => context.push('/onboarding'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({
    required this.membership,
    required this.selected,
    required this.onTap,
  });

  final MembershipEntity membership;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = membership.organizationRole ?? membership.branchRole ?? 'Member';
    final subtitle = [
      if ((membership.branchName ?? '').isNotEmpty) membership.branchName!,
      role,
    ].join(' · ');

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: BorderSide(
          color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  MposRoles.isOrgAdminRole(membership.organizationRole)
                      ? Icons.storefront_outlined
                      : Icons.store_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSizes.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membership.organizationName ?? 'Business',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
