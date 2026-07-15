import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/dining_table_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

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
                      '${ticket.unpaidLines.length} unpaid items · ${CurrencyFormatter.format(ticket.remainingTotal)}',
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
                text: 'Pay',
                buttonColor: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
                borderColor: colorScheme.primaryContainer,
                onTap: () => _showPaymentDialog(context, ticket: ticket, selectedOnly: false),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              AppButton(
                width: double.infinity,
                height: 40,
                fontSize: 14,
                text: 'Split',
                buttonColor: colorScheme.surface,
                textColor: colorScheme.primary,
                borderColor: colorScheme.primary,
                onTap: () => _showLinePickerDialog(context, ticket),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLinePickerDialog(BuildContext context, OrderEntity ticket) {
    final splitQuantities = <String, int>{};

    AppDialog.show(
      title: 'Split items',
      leftButtonText: 'Cancel',
      rightButtonText: 'Continue',
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: ticket.unpaidLines.map((line) {
              final selectedQuantity = splitQuantities[line.id] ?? 0;
              final subtotal = line.unitPrice * selectedQuantity;
              final tax = calculateTaxesAmount(subtotal, line.taxes);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            'Open ${line.remainingQuantity.round()} · ${CurrencyFormatter.format(line.unitPrice)} each',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: selectedQuantity <= 0
                          ? null
                          : () => setState(() {
                              final next = selectedQuantity - 1;

                              if (next <= 0) {
                                splitQuantities.remove(line.id);
                              } else {
                                splitQuantities[line.id] = next;
                              }
                            }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(width: 28, child: Center(child: Text('$selectedQuantity'))),
                    IconButton(
                      onPressed: selectedQuantity >= line.remainingQuantity.round()
                          ? null
                          : () => setState(() => splitQuantities[line.id] = selectedQuantity + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    SizedBox(
                      width: 88,
                      child: Text(CurrencyFormatter.format(subtotal + tax), textAlign: TextAlign.end),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      onTapRightButton: (dialogContext) {
        if (splitQuantities.isEmpty) {
          return;
        }

        dialogContext.pop();
        _showPaymentDialog(context, ticket: ticket, selectedOnly: true, splitQuantities: splitQuantities);
      },
    );
  }

  void _showPaymentDialog(
    BuildContext context, {
    required OrderEntity ticket,
    required bool selectedOnly,
    Map<String, int>? splitQuantities,
  }) {
    final methods = context.read<PosBloc>().state.enabledPaymentMethods;

    if (methods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payment methods are enabled for this business.')),
      );
      return;
    }

    final phoneController = TextEditingController(text: ticket.customerPhone ?? '');
    final nameController = TextEditingController(text: ticket.customerName ?? '');
    final total = selectedOnly
        ? ticket.unpaidLines.fold<double>(0, (sum, line) {
            final selectedQuantity = splitQuantities?[line.id] ?? 0;

            if (selectedQuantity <= 0) {
              return sum;
            }

            final subtotal = line.unitPrice * selectedQuantity;
            final tax = calculateTaxesAmount(subtotal, line.taxes);
            return sum + subtotal + tax;
          })
        : ticket.unpaidLines.fold<double>(0, (sum, line) => sum + line.remainingLineTotal + line.remainingTaxAmount);
    final amountController = TextEditingController(text: total.toStringAsFixed(2));
    var paymentMethod = methods.first.value;

    AppDialog.show(
      title: selectedOnly ? 'Split payment' : 'Pay ticket',
      leftButtonText: 'Cancel',
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: phoneController,
                labelText: 'Customer phone',
                hintText: '0912345678',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSizes.padding),
              AppTextField(controller: nameController, labelText: 'Customer name (optional)'),
              const SizedBox(height: AppSizes.padding),
              if (paymentMethod == 'cash')
                AppTextField(
                  controller: amountController,
                  labelText: 'Received amount',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: AppSizes.padding),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: [
                  for (final method in methods)
                    DropdownMenuItem(value: method.value, child: Text(method.label)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: AppSizes.padding),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total ${CurrencyFormatter.format(total)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
      rightButtonText: 'Confirm',
      onTapRightButton: (dialogContext) {
        if (phoneController.text.trim().isEmpty) {
          return;
        }

        context.read<PosBloc>().add(
          PosCheckoutRequested(
            orderId: ticket.id,
            paymentMethod: paymentMethod,
            customerPhone: phoneController.text.trim(),
            customerName: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
            receivedAmount: paymentMethod == 'cash' ? double.tryParse(amountController.text) : null,
            selectedOnly: selectedOnly,
            splitQuantities: splitQuantities,
          ),
        );
        dialogContext.pop();
      },
    );
  }
}
