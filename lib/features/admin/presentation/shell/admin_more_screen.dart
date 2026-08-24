import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/locale/app_locale.dart';
import 'package:mpos_mobile/core/locale/app_localizations.dart';
import 'package:mpos_mobile/core/locale/locale_cubit.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/theme/theme_cubit.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/language_selector.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return Scaffold(body: Center(child: Text(l10n.notSignedIn)));
    }
    final session = authState.session;
    final currentLanguage = AppLocale.languages
        .firstWhere((lang) => lang.code == context.watch<LocaleCubit>().state.languageCode)
        .nativeName;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          _ProfileHeader(session: session),
          const SizedBox(height: AppSizes.padding),
          _SectionLabel(label: l10n.sectionBusiness),
          _MoreTile(
            icon: Icons.swap_horiz_outlined,
            title: 'Switch business',
            onTap: () => context.push('/select-business'),
          ),
          if (session.isOrgAdmin)
            _MoreTile(
              icon: Icons.add_business_outlined,
              title: 'Create another business',
              onTap: () => context.push('/onboarding'),
            ),
          _MoreTile(
            icon: Icons.store_mall_directory_outlined,
            title: l10n.branches,
            onTap: () => context.push('/admin/settings/branches'),
          ),
          if (session.canManageSettings) ...[
            _MoreTile(
              icon: Icons.business_outlined,
              title: 'Business management',
              onTap: () => context.push('/admin/settings/organization'),
            ),
            _MoreTile(icon: Icons.percent_outlined, title: l10n.taxes, onTap: () => context.push('/admin/settings/taxes')),
            _MoreTile(
              icon: Icons.shield_outlined,
              title: 'Roles & permissions',
              onTap: () => context.push('/admin/settings/roles'),
            ),
            _MoreTile(
              icon: Icons.credit_card_outlined,
              title: l10n.paymentGateways,
              onTap: () => context.push('/admin/settings/payment-gateways'),
            ),
            _MoreTile(
              icon: Icons.receipt_outlined,
              title: l10n.morEInvoice,
              onTap: () => context.push('/admin/settings/mor-settings'),
            ),
            _MoreTile(
              icon: Icons.account_balance_outlined,
              title: l10n.bankSettlement,
              onTap: () => context.push('/admin/settings/bank-account'),
            ),
          ],
          const SizedBox(height: AppSizes.padding),
          _SectionLabel(label: l10n.sectionApp),
          _MoreTile(
            icon: Icons.translate_outlined,
            title: l10n.language,
            trailing: currentLanguage,
            onTap: () => showLanguagePicker(context),
          ),
          _MoreTile(icon: Icons.format_paint_outlined, title: l10n.theme, onTap: () => _showThemeDialog(context)),
          if (MposConfig.mockMode) _MoreTile(icon: Icons.science_outlined, title: l10n.mode, trailing: l10n.demoMock),
          const SizedBox(height: AppSizes.padding),
          AppButton(
            text: l10n.signOut,
            buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
            textColor: Theme.of(context).colorScheme.error,
            onTap: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    AppDialog.show(title: l10n.theme, leftButtonText: l10n.close, child: const _ThemeDialogBody());
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session});

  final AuthSessionEntity session;

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              (session.userName ?? session.userPhone).characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.userName ?? session.userPhone,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text('${session.userPhone} · ${session.roleLabel}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding / 2, left: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.icon, required this.title, this.trailing, this.onTap});

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
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.lightMode),
          value: isLight,
          onChanged: (value) => context.read<ThemeCubit>().setLightMode(value),
        ),
        SwitchListTile(
          title: Text(l10n.darkMode),
          value: !isLight,
          onChanged: (value) => context.read<ThemeCubit>().setLightMode(!value),
        ),
      ],
    );
  }
}
