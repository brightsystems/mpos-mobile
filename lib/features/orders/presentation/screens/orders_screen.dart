import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/dining_table_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/checkout_dialogs.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final tables = state.tables;

        if (tables.isEmpty) {
          return const Center(child: Text('No open tables. Start from the Sell tab.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.padding),
          itemCount: tables.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
          itemBuilder: (context, index) =>
              _TableCard(table: tables[index], isFocused: state.focusedTableNumber == tables[index].tableNumber),
        );
      },
    );
  }
}

class _TableCard extends StatefulWidget {
  const _TableCard({required this.table, required this.isFocused});

  final DiningTableEntity table;
  final bool isFocused;

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  late var _expanded = widget.isFocused;

  @override
  void didUpdateWidget(covariant _TableCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFocused && !oldWidget.isFocused) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;

    return Card(
      child: ExpansionTile(
        key: ValueKey('${table.tableNumber}-${widget.isFocused}'),
        initiallyExpanded: widget.isFocused || _expanded,
        onExpansionChanged: (value) {
          setState(() => _expanded = value);

          if (!value && widget.isFocused) {
            context.read<PosBloc>().add(const PosTablesFocusCleared());
          }
        },
        title: Text('Table ${table.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${table.openTicketCount} tickets · ${CurrencyFormatter.format(table.unpaidTotal)} open'),
        childrenPadding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding),
        children: table.tickets.map((ticket) => _TicketCard(ticket: ticket)).toList(),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final OrderEntity ticket;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.padding / 2),
      padding: const EdgeInsets.all(AppSizes.padding / 1.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketNumber ?? ticket.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${ticket.unpaidLines.length} unpaid items · ${CurrencyFormatter.format(ticket.remainingTotal)}'
                      '${ticket.isDraft
                          ? ''
                          : ticket.isCreditSale
                          ? ' · credit sale'
                          : ' · cash sale'}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              AppButton(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 1.5),
                fontSize: 12,
                text: 'Open',
                onTap: () {
                  context.read<PosBloc>().add(PosTicketSelected(ticket.id));
                  context.go('/home');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),
          ...ticket.unpaidLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text('${line.name} x${line.remainingQuantity.round()}')),
                  Text(CurrencyFormatter.format(line.remainingLineTotal + line.remainingTaxAmount)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                width: double.infinity,
                height: 40,
                fontSize: 14,
                text: ticket.isDraft ? 'Checkout' : 'Pay',
                buttonColor: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
                borderColor: colorScheme.primaryContainer,
                onTap: () => startCheckout(context, ticket),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
