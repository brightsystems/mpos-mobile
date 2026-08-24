import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/locale/app_localizations.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/presentation/widgets/mpos_session_bar.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosBloc, PosState>(
      listenWhen: (previous, current) =>
          current.status == PosStatus.success &&
          previous.status != PosStatus.success &&
          current.lastOrder != null &&
          !current.lastOrder!.isClosed,
      listener: (context, state) {
        final order = state.lastOrder!;

        navigationShell.goBranch(2);
        context.go('/orders');
        AppSnackBar.show(
          'Partial payment applied. ${CurrencyFormatter.format(order.remainingTotal)} still open on ${state.displayServicePoint(order.tableNumber)}.',
        );
        context.read<PosBloc>().add(const PosCheckoutDismissed());
      },
      child: Scaffold(
        appBar: const MposSessionBar(),
        body: navigationShell,
        bottomNavigationBar: BlocBuilder<PosBloc, PosState>(
          buildWhen: (previous, current) => previous.businessProfile != current.businessProfile,
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            final openOrdersLabel = state.vocabulary.openOrdersNav;
            final menuLabel = state.vocabulary.menu;
            return BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(index),
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.point_of_sale_outlined), label: l10n.navSell),
                BottomNavigationBarItem(icon: const Icon(Icons.list_alt_outlined), label: menuLabel),
                BottomNavigationBarItem(
                  icon: Icon(
                    state.businessProfile?.showServicePoints ?? true
                        ? Icons.table_restaurant_outlined
                        : Icons.receipt_long_outlined,
                  ),
                  label: openOrdersLabel,
                ),
                BottomNavigationBarItem(icon: const Icon(Icons.account_circle_outlined), label: l10n.navAccount),
              ],
            );
          },
        ),
      ),
    );
  }
}
