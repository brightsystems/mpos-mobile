import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/app/app_navigator.dart';

import 'package:mpos_mobile/app/di/injection.dart';

import 'package:mpos_mobile/app/shell/main_shell_screen.dart';

import 'package:mpos_mobile/core/locale/app_locale.dart';

import 'package:mpos_mobile/core/theme/app_theme.dart';

import 'package:mpos_mobile/core/theme/theme_cubit.dart';
import 'package:mpos_mobile/core/theme/theme_state.dart';

import 'package:mpos_mobile/features/account/presentation/screens/account_screen.dart';
import 'package:mpos_mobile/features/account/presentation/screens/dashboard_screen.dart';

import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';

import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

import 'package:mpos_mobile/features/auth/presentation/screens/shift_qr_scan_screen.dart';

import 'package:mpos_mobile/features/menu/presentation/screens/menu_browse_screen.dart';

import 'package:mpos_mobile/features/orders/presentation/screens/orders_screen.dart';

import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';

import 'package:mpos_mobile/features/pos/presentation/screens/pos_screen.dart';

class MposApp extends StatelessWidget {
  const MposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()),

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

      initialLocation: '/shift-login',

      routes: [
        GoRoute(path: '/shift-login', builder: (context, state) => const ShiftQrScanScreen()),

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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _router.go('/home');
        }

        if (state is AuthUnauthenticated && state.message == null) {
          _router.go('/shift-login');
        }
      },

      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'MPOS',

            theme: AppTheme().init(brightness: Brightness.light),

            darkTheme: AppTheme().init(brightness: Brightness.dark),

            themeMode: themeState.isLight ? ThemeMode.light : ThemeMode.dark,

            debugShowCheckedModeBanner: false,

            routerConfig: _router,

            locale: AppLocale.defaultLocale,

            supportedLocales: AppLocale.supportedLocales,

            localizationsDelegates: AppLocale.localizationsDelegates,
          );
        },
      ),
    );
  }
}
