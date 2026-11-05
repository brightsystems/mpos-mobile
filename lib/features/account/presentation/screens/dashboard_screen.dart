import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/account/data/today_api.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Today's cash and wallet collections and the orders still open, as the API counts them (the
/// Addis Ababa day, from the payments themselves): a fully paid sale counts too, not only the
/// orders still open on this device. Reloads after each sale and on pull-to-refresh.
class _DashboardScreenState extends State<DashboardScreen> {
  BranchToday _today = BranchToday.empty;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (MposConfig.mockMode) {
      setState(() {
        _today = _mockToday();
        _loading = false;
      });
      return;
    }
    setState(() => _error = null);
    try {
      final today = await getIt<TodayApi>().today();
      if (mounted) setState(() => _today = today);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static BranchToday _mockToday() {
    final payments = MockFixtures.recentOrders
        .map(
          (order) => TodayPayment(
            orderId: order.orderNumber,
            orderNumber: order.orderNumber,
            amount: order.totalAmount,
            method: order.paymentMethod,
            paidAt: DateTime.now(),
            customerPhone: order.customerPhone,
          ),
        )
        .toList();
    final cash = payments.where((p) => p.method.toLowerCase() == 'cash');
    final wallet = payments.where((p) => p.method.toLowerCase() != 'cash');
    return BranchToday(
      cashTotal: cash.fold(0, (sum, p) => sum + p.amount),
      cashCount: cash.length,
      walletTotal: wallet.fold(0, (sum, p) => sum + p.amount),
      walletCount: wallet.length,
      paidOrdersCount: payments.length,
      payments: payments,
      openOrders: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not signed in.')));
        }

        // A sale completed on this device: refresh the figures.
        return BlocListener<PosBloc, PosState>(
          listenWhen: (previous, current) => previous.lastOrder != current.lastOrder && current.lastOrder != null,
          listener: (_, _) => _load(),
          child: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final transactions = _today.payments
        .map(
          (p) => _DashboardTransaction(
            orderId: p.orderId,
            orderNumber: p.orderNumber,
            amount: p.amount,
            method: p.method,
            customerPhone: p.customerPhone,
            createdAt: p.paidAt,
            tableNumber: p.tableNumber,
          ),
        )
        .toList();
    final pendingOrders = _today.openOrders
        .map(
          (o) => _PendingOrder(
            orderId: o.orderId,
            orderNumber: o.orderNumber,
            status: o.status,
            createdAt: o.createdAt,
            tableNumber: o.tableNumber,
            customerPhone: o.customerPhone,
            totalAmount: o.totalAmount,
            collectedAmount: o.paidAmount,
            remainingAmount: o.remainingAmount,
          ),
        )
        .toList();
    final cashTransactions = transactions.where((transaction) => transaction.isCash).toList();
    final walletTransactions = transactions.where((transaction) => !transaction.isCash).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cash'),
              Tab(text: 'Wallet'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    MaterialBanner(
                      content: Text(_error!),
                      actions: [TextButton(onPressed: _load, child: const Text('Try again'))],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    child: Column(
                      children: [
                        _SummaryBanner(
                          orderCount: _today.paidOrdersCount + pendingOrders.length,
                          transactionCount: transactions.length,
                          openOrderCount: pendingOrders.length,
                        ),
                        const SizedBox(height: AppSizes.padding / 1.5),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Cash collected',
                                value: CurrencyFormatter.format(_today.cashTotal),
                                subtitle: '${_today.cashCount} transactions',
                                icon: Icons.payments_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSizes.padding / 2),
                            Expanded(
                              child: _MetricCard(
                                title: 'Wallet / Digital',
                                value: CurrencyFormatter.format(_today.walletTotal),
                                subtitle: '${_today.walletCount} transactions',
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
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _TransactionList(
                            pendingOrders: pendingOrders,
                            transactions: cashTransactions,
                            emptyMessage: 'No cash activity recorded today.',
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _TransactionList(
                            pendingOrders: const [],
                            transactions: walletTransactions,
                            emptyMessage: 'No wallet transactions recorded today.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
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
              _MiniInfoChip(label: order.status),
              _MiniInfoChip(label: 'Total ${CurrencyFormatter.format(order.totalAmount)}'),
              _MiniInfoChip(label: order.isPartiallyPaid ? 'Part paid' : 'Awaiting collection'),
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
    required this.status,
    required this.createdAt,
    required this.tableNumber,
    required this.totalAmount,
    required this.collectedAmount,
    required this.remainingAmount,
    this.customerPhone,
  });

  final String orderId;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final String? tableNumber;
  final String? customerPhone;
  final double totalAmount;
  final double collectedAmount;
  final double remainingAmount;

  bool get isPartiallyPaid => collectedAmount > 0;

  String get statusLabel => isPartiallyPaid ? 'Partially paid' : 'Not collected';

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
