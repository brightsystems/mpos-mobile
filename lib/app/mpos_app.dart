import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/app/app_navigator.dart';
import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/app/shell/main_shell_screen.dart';
import 'package:mpos_mobile/core/locale/app_locale.dart';
import 'package:mpos_mobile/core/locale/locale_cubit.dart';
import 'package:mpos_mobile/core/theme/app_theme.dart';
import 'package:mpos_mobile/core/theme/theme_cubit.dart';
import 'package:mpos_mobile/core/theme/theme_state.dart';
import 'package:mpos_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:mpos_mobile/features/account/presentation/screens/dashboard_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/bank/bank_account_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/branches/branches_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/dashboard/admin_dashboard_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/menu/menu_management_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/mor/mor_settings_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/orders/orders_history_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/organization/organization_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/payments/payment_gateways_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/roles/roles_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/shell/admin_more_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/shell/admin_shell_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/staff/staff_screen.dart';
import 'package:mpos_mobile/features/admin/presentation/taxes/taxes_screen.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/auth/presentation/screens/business_selector_screen.dart';
import 'package:mpos_mobile/features/auth/presentation/screens/landing_screen.dart';
import 'package:mpos_mobile/features/auth/presentation/screens/phone_login_screen.dart';
import 'package:mpos_mobile/features/auth/presentation/screens/shift_qr_scan_screen.dart';
import 'package:mpos_mobile/features/menu/presentation/screens/menu_browse_screen.dart';
import 'package:mpos_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mpos_mobile/features/orders/presentation/screens/orders_screen.dart';
import 'package:mpos_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/pos_screen.dart';

class MposApp extends StatelessWidget {
  const MposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<LocaleCubit>()),
        BlocProvider(create: (_) => getIt<AuthBloc>()..add(const AuthStarted())),
        BlocProvider(create: (_) => getIt<PosBloc>()),
      ],
      child: const _MposAppShell(),
    );
  }
}

class _MposAppShell extends StatefulWidget {
  const _MposAppShell();

  @override
  State<_MposAppShell> createState() => _MposAppShellState();
}

class _MposAppShellState extends State<_MposAppShell> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      navigatorKey: AppNavigator.rootNavigatorKey,
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/landing', builder: (context, state) => const LandingScreen()),
        GoRoute(path: '/phone-login', builder: (context, state) => const PhoneLoginScreen()),
        GoRoute(path: '/shift-login', builder: (context, state) => const ShiftQrScanScreen()),
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/select-business', builder: (context, state) => const BusinessSelectorScreen()),

        // Admin settings detail screens (full-screen, pushed over the admin shell).
        GoRoute(path: '/admin/settings/branches', builder: (context, state) => const BranchesScreen()),
        GoRoute(path: '/admin/settings/organization', builder: (context, state) => const OrganizationScreen()),
        GoRoute(path: '/admin/settings/taxes', builder: (context, state) => const TaxesScreen()),
        GoRoute(path: '/admin/settings/roles', builder: (context, state) => const RolesScreen()),
        GoRoute(path: '/admin/settings/payment-gateways', builder: (context, state) => const PaymentGatewaysScreen()),
        GoRoute(path: '/admin/settings/mor-settings', builder: (context, state) => const MorSettingsScreen()),
        GoRoute(path: '/admin/settings/bank-account', builder: (context, state) => const BankAccountScreen()),

        // POS shell (waiters / cashiers).
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/home', builder: (context, state) => const PosScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/menu', builder: (context, state) => const MenuBrowseScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen())],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/account',
                  builder: (context, state) => const AccountScreen(),
                  routes: [GoRoute(path: 'dashboard', builder: (context, state) => const DashboardScreen())],
                ),
              ],
            ),
          ],
        ),

        // Admin shell (owners / org admins / branch managers).
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminShellScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/admin/menu', builder: (context, state) => const MenuManagementScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/admin/orders', builder: (context, state) => const OrdersHistoryScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/admin/staff', builder: (context, state) => const StaffScreen())],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/admin/more', builder: (context, state) => const AdminMoreScreen())],
            ),
          ],
        ),
      ],
    );
  }

  void _handleAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      _router.go(state.session.usesAdminShell ? '/admin/dashboard' : '/home');
      return;
    }

    if (state is AuthNeedsBusinessSelection) {
      _router.go('/select-business');
      return;
    }

    if (state is AuthNeedsOnboarding) {
      _router.go('/onboarding');
      return;
    }

    if (state is AuthUnauthenticated && state.message == null) {
      _router.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated ||
          current is AuthNeedsOnboarding ||
          current is AuthNeedsBusinessSelection ||
          current is AuthUnauthenticated,
      listener: (context, state) => _handleAuthState(state),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'MPOS',
                theme: AppTheme().init(brightness: Brightness.light),
                darkTheme: AppTheme().init(brightness: Brightness.dark),
                themeMode: themeState.isLight ? ThemeMode.light : ThemeMode.dark,
                debugShowCheckedModeBanner: false,
                routerConfig: _router,
                locale: locale,
                supportedLocales: AppLocale.supportedLocales,
                localizationsDelegates: AppLocale.localizationsDelegates,
              );
            },
          );
        },
      ),
    );
  }
}
