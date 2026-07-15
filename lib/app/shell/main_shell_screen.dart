import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
          'Partial payment applied. ${CurrencyFormatter.format(order.remainingTotal)} still open on table ${order.tableNumber ?? 'Walk-in'}.',
        );
        context.read<PosBloc>().add(const PosCheckoutDismissed());
      },
      child: Scaffold(
        appBar: const MposSessionBar(),
        body: navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), label: 'Sell'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), label: 'Menu'),
            BottomNavigationBarItem(icon: Icon(Icons.table_restaurant_outlined), label: 'Tables'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Account'),
          ],
        ),
      ),
    );
  }
}
