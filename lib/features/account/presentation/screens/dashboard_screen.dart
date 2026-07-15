import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not signed in.')));
        }

        return BlocBuilder<PosBloc, PosState>(
          builder: (context, posState) {
            final transactions = _buildTodayTransactions(posState);
            final pendingOrders = _buildPendingOrders(posState);
            final cashTransactions = transactions.where((transaction) => transaction.isCash).toList();
            final walletTransactions = transactions.where((transaction) => !transaction.isCash).toList();
            final orderCount = transactions.map((transaction) => transaction.orderId).toSet().length;
            final cashTotal = cashTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
            final walletTotal = walletTransactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Dashboard'),
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Cash'),
                      Tab(text: 'Wallet'),
                    ],
                  ),
                ),
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.padding),
                      child: Column(
                        children: [
                          _SummaryBanner(
                            orderCount: orderCount + pendingOrders.length,
                            transactionCount: transactions.length,
                            openOrderCount: pendingOrders.length,
                          ),
                          const SizedBox(height: AppSizes.padding / 1.5),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  title: 'Cash collected',
                                  value: CurrencyFormatter.format(cashTotal),
                                  subtitle: '${cashTransactions.length} transactions',
                                  icon: Icons.payments_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSizes.padding / 2),
                              Expanded(
                                child: _MetricCard(
                                  title: 'Wallet / Digital',
                                  value: CurrencyFormatter.format(walletTotal),
                                  subtitle: '${walletTransactions.length} transactions',
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TransactionList(
                            pendingOrders: pendingOrders,
                            transactions: cashTransactions,
                            emptyMessage: 'No cash activity recorded today.',
                          ),
                          _TransactionList(
                            pendingOrders: const [],
                            transactions: walletTransactions,
                            emptyMessage: 'No wallet transactions recorded today.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_DashboardTransaction> _buildTodayTransactions(PosState state) {
    final today = DateTime.now();
    final transactions = <_DashboardTransaction>[];

    if (MposConfig.mockMode) {
      transactions.addAll(
        MockFixtures.recentOrders.map(
          (order) => _DashboardTransaction(
            orderId: order.orderNumber,
            orderNumber: order.orderNumber,
            amount: order.totalAmount,
            method: order.paymentMethod,
            customerPhone: order.customerPhone,
            createdAt: today,
            tableNumber: null,
          ),
        ),
      );
    }

    for (final order in state.openOrders) {
      if (!_isSameDay(order.createdAt, today)) {
        continue;
      }

      for (final payment in order.payments) {
        if (payment.status.toLowerCase() != 'completed') {
          continue;
        }

        transactions.add(
          _DashboardTransaction(
            orderId: order.id,
            orderNumber: order.ticketNumber ?? order.orderNumber,
            amount: payment.amount,
            method: payment.method,
            customerPhone: order.customerPhone,
            createdAt: order.createdAt ?? today,
            tableNumber: order.tableNumber,
          ),
        );
      }
    }

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
  }

  List<_PendingOrder> _buildPendingOrders(PosState state) {
    final today = DateTime.now();
    final orders = <_PendingOrder>[];

    for (final order in state.openOrders) {
      if (!_isSameDay(order.createdAt, today)) {
        continue;
      }

      final collectedAmount = order.payments
          .where((payment) => payment.status.toLowerCase() == 'completed')
          .fold<double>(0, (sum, payment) => sum + payment.amount);

      final lastCompletedMethod = order.payments
          .where((payment) => payment.status.toLowerCase() == 'completed')
          .fold<String?>(null, (_, payment) => payment.method);

      orders.add(
        _PendingOrder(
          orderId: order.id,
          orderNumber: order.ticketNumber ?? order.orderNumber,
          createdAt: order.createdAt ?? today,
          tableNumber: order.tableNumber,
          customerPhone: order.customerPhone,
          totalAmount: order.totalAmount,
          collectedAmount: collectedAmount,
          remainingAmount: order.remainingTotal,
          unpaidItemCount: order.unpaidLines.fold<int>(0, (sum, line) => sum + line.remainingQuantity.round()),
          lastPaymentMethod: lastCompletedMethod,
        ),
      );
    }

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return orders;
  }

  bool _isSameDay(DateTime? value, DateTime other) {
    if (value == null) {
      return false;
    }

    return value.year == other.year && value.month == other.month && value.day == other.day;
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.orderCount, required this.transactionCount, required this.openOrderCount});

  final int orderCount;
  final int transactionCount;
  final int openOrderCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final openLabel = openOrderCount == 0
        ? 'All orders collected.'
        : '$openOrderCount order${openOrderCount == 1 ? '' : 's'} still open.';

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
            'Today\'s summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$orderCount orders placed · $transactionCount completed payments · $openLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.subtitle, required this.icon});

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

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
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: AppSizes.padding / 2),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.pendingOrders, required this.transactions, required this.emptyMessage});

  final List<_PendingOrder> pendingOrders;
  final List<_DashboardTransaction> transactions;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (pendingOrders.isEmpty && transactions.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final itemCount = pendingOrders.length + transactions.length;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
      itemBuilder: (context, index) {
        if (index < pendingOrders.length) {
          return _PendingOrderCard(order: pendingOrders[index]);
        }

        return _TransactionCard(transaction: transactions[index - pendingOrders.length]);
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});

  final _DashboardTransaction transaction;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: transaction.isCash ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              transaction.isCash ? Icons.payments_outlined : Icons.account_balance_wallet_outlined,
              size: 20,
              color: transaction.isCash ? colorScheme.onPrimaryContainer : colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSizes.padding / 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.orderNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(transaction.tableLabel, style: Theme.of(context).textTheme.bodySmall),
                if (transaction.customerPhone != null) ...[
                  const SizedBox(height: 2),
                  Text(transaction.customerPhone!, style: Theme.of(context).textTheme.labelSmall),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.padding / 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(transaction.amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.methodLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  const _PendingOrderCard({required this.order});

  final _PendingOrder order;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _StatusBadge(
                label: order.statusLabel,
                backgroundColor: order.isPartiallyPaid ? colorScheme.tertiaryContainer : colorScheme.errorContainer,
                textColor: order.isPartiallyPaid ? colorScheme.onTertiaryContainer : colorScheme.onErrorContainer,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.tableLabel, style: Theme.of(context).textTheme.bodySmall),
          if (order.customerPhone != null) ...[
            const SizedBox(height: 2),
            Text(order.customerPhone!, style: Theme.of(context).textTheme.labelSmall),
          ],
          const SizedBox(height: AppSizes.padding / 1.5),
          Row(
            children: [
              Expanded(
                child: _PendingOrderMetric(label: 'Collected', value: CurrencyFormatter.format(order.collectedAmount)),
              ),
              const SizedBox(width: AppSizes.padding / 2),
              Expanded(
                child: _PendingOrderMetric(label: 'Remaining', value: CurrencyFormatter.format(order.remainingAmount)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniInfoChip(label: '${order.unpaidItemCount} items open'),
              _MiniInfoChip(label: 'Total ${CurrencyFormatter.format(order.totalAmount)}'),
              _MiniInfoChip(label: order.collectionMethodLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingOrderMetric extends StatelessWidget {
  const _PendingOrderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding / 1.5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.backgroundColor, required this.textColor});

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: textColor),
      ),
    );
  }
}

class _DashboardTransaction {
  const _DashboardTransaction({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.method,
    required this.createdAt,
    required this.tableNumber,
    this.customerPhone,
  });

  final String orderId;
  final String orderNumber;
  final double amount;
  final String method;
  final String? customerPhone;
  final DateTime createdAt;
  final String? tableNumber;

  bool get isCash => method.toLowerCase() == 'cash';

  String get methodLabel => isCash ? 'Cash' : 'Wallet / Digital';

  String get tableLabel {
    final table = (tableNumber == null || tableNumber!.isEmpty) ? 'Walk-in' : 'Table $tableNumber';
    return '$table · ${_timeLabel(createdAt)}';
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _PendingOrder {
  const _PendingOrder({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.tableNumber,
    required this.totalAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.unpaidItemCount,
    this.customerPhone,
    this.lastPaymentMethod,
  });

  final String orderId;
  final String orderNumber;
  final DateTime createdAt;
  final String? tableNumber;
  final String? customerPhone;
  final double totalAmount;
  final double collectedAmount;
  final double remainingAmount;
  final int unpaidItemCount;
  final String? lastPaymentMethod;

  bool get isPartiallyPaid => collectedAmount > 0;

  String get statusLabel => isPartiallyPaid ? 'Partially paid' : 'Not collected';

  String get collectionMethodLabel {
    if (lastPaymentMethod == null || lastPaymentMethod!.trim().isEmpty) {
      return 'Awaiting collection';
    }

    final isCash = lastPaymentMethod!.toLowerCase() == 'cash';
    return isCash ? 'Cash collected so far' : 'Wallet collected so far';
  }

  String get tableLabel {
    final table = (tableNumber == null || tableNumber!.isEmpty) ? 'Walk-in' : 'Table $tableNumber';
    return '$table · ${_timeLabel(createdAt)}';
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
