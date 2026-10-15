import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/pos/domain/entities/customer_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// POS checkout — the same steps and requests as the web POS:
/// 1. A draft order is submitted with its buyer (a saved customer, or phone/name/TIN) and the
///    sale type (cash or credit). This registers the MoR invoice; B2B/B2G withholding is
///    calculated by the API from the buyer.
/// 2. Payment collects the balance the API reports: cash by amount (partial payments allowed),
///    or an electronic method for the whole balance.
Future<void> startCheckout(BuildContext context, OrderEntity order) async {
  if (order.isDraft) {
    _showSubmitDialog(context, order);
  } else {
    showPaymentDialog(context, order);
  }
}

bool _isValidTin(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || RegExp(r'^\d{10}$').hasMatch(trimmed);
}

String? _blankToNull(String value) => value.trim().isEmpty ? null : value.trim();

/// Empty is fine (no email); otherwise it must look like an address.
bool _isValidEmail(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
}

void _showSubmitDialog(BuildContext context, OrderEntity order) {
  final bloc = context.read<PosBloc>();
  final phoneController = TextEditingController(text: order.customerPhone ?? '');
  final nameController = TextEditingController(text: order.customerName ?? '');
  final tinController = TextEditingController(text: order.customerTin ?? '');
  final emailController = TextEditingController(text: order.customerEmail ?? '');
  final searchController = TextEditingController();
  var paymentMode = order.isCreditSale ? 'CREDIT' : 'CASH';
  CustomerEntity? customer;
  var results = <CustomerEntity>[];
  var searching = false;
  var busy = false;

  AppDialog.show(
    title: 'Checkout',
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        final theme = Theme.of(dialogContext);

        Future<void> search() async {
          setState(() => searching = true);
          final result = await getIt<OrderRepository>().searchCustomers(searchController.text);
          if (!dialogContext.mounted) return;
          setState(() {
            searching = false;
            results = result.data ?? const [];
          });
          if (!result.isSuccess) {
            AppSnackBar.showError(result.error?.toString() ?? 'Could not load customers.');
          }
        }

        void pick(CustomerEntity picked) {
          setState(() {
            customer = picked;
            results = const [];
            nameController.text = picked.legalName;
            tinController.text = picked.tin ?? '';
            if ((picked.phone ?? '').isNotEmpty) {
              phoneController.text = picked.phone!;
            }
            if ((picked.email ?? '').isNotEmpty) {
              emailController.text = picked.email!;
            }
          });
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Customer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.padding / 2),
            if (customer != null)
              InputChip(
                label: Text('${customer!.legalName} · ${customer!.transactionType}'),
                avatar: const Icon(Icons.business_outlined, size: 18),
                onDeleted: () => setState(() => customer = null),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: searchController,
                      labelText: 'Saved customer (name or TIN)',
                      textInputAction: TextInputAction.search,
                      onEditingComplete: search,
                    ),
                  ),
                  IconButton(
                    onPressed: searching ? null : search,
                    icon: searching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                  ),
                ],
              ),
            for (final item in results.take(6))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.legalName),
                subtitle: Text(
                  [
                    item.transactionType,
                    if ((item.tin ?? '').isNotEmpty) 'TIN ${item.tin}',
                    if (item.isWithholdingAgent) 'Withholding agent',
                  ].join(' · '),
                ),
                onTap: () => pick(item),
              ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: phoneController,
              labelText: 'Customer phone',
              hintText: '0912345678',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: nameController, labelText: 'Customer name (optional)'),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: emailController,
              labelText: 'Email (optional, invoice & receipts are emailed)',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: tinController,
              labelText: 'Buyer TIN (optional, 10 digits)',
              hintText: '0012345678',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding),
            Text('Sale type', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.padding / 2),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'CASH', label: Text('Cash sale'), icon: Icon(Icons.payments_outlined)),
                ButtonSegment(value: 'CREDIT', label: Text('Credit sale'), icon: Icon(Icons.schedule)),
              ],
              selected: {paymentMode},
              onSelectionChanged: (value) => setState(() => paymentMode = value.first),
            ),
            const SizedBox(height: AppSizes.padding),
            _AmountRow(label: 'Total', amount: order.totalAmount, bold: true),
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: busy ? 'Submitting…' : 'Submit & register invoice',
              enabled: !busy && _isValidTin(tinController.text) && _isValidEmail(emailController.text),
              onTap: () async {
                setState(() => busy = true);

                final result = await getIt<OrderRepository>().submitOrder(
                  orderId: order.id,
                  customerPhone: _blankToNull(phoneController.text),
                  customerName: _blankToNull(nameController.text),
                  customerTin: _blankToNull(tinController.text),
                  customerId: customer?.id,
                  paymentMode: paymentMode,
                  customerEmail: _blankToNull(emailController.text),
                );

                if (!dialogContext.mounted) return;

                if (!result.isSuccess || result.data == null) {
                  setState(() => busy = false);
                  AppSnackBar.showError(result.error?.toString() ?? 'Submit failed.');
                  return;
                }

                final submitted = result.data!;
                bloc.add(PosOrderUpdated(submitted));
                Navigator.of(dialogContext).pop();

                final session = await getIt<SessionStorage>().loadSession();
                if (!(session?.canCollectPayment ?? false)) {
                  AppSnackBar.show('Order submitted for cashier approval.');
                  return;
                }

                AppSnackBar.show('Order submitted. MoR invoice registration started.');
                if (context.mounted) {
                  showPaymentDialog(context, submitted);
                }
              },
            ),
          ],
        );
      },
    ),
  );
}

/// Collects a payment on a submitted order, like the web POS payment area.
void showPaymentDialog(BuildContext context, OrderEntity order) {
  final bloc = context.read<PosBloc>();
  final methods = bloc.state.enabledPaymentMethods;

  if (methods.isEmpty) {
    AppSnackBar.showError('No payment methods are enabled for this business.');
    return;
  }

  final remaining = order.remainingTotal;
  final phoneController = TextEditingController(text: order.customerPhone ?? '');
  final nameController = TextEditingController(text: order.customerName ?? '');
  final tinController = TextEditingController(text: order.customerTin ?? '');
  final emailController = TextEditingController(text: order.customerEmail ?? '');
  final payNowController = TextEditingController(text: remaining.toStringAsFixed(2));
  final receivedController = TextEditingController(text: remaining.toStringAsFixed(2));
  var paymentMethod = methods.first.value;

  AppDialog.show(
    title: 'Payment',
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        final theme = Theme.of(dialogContext);
        final planned = double.tryParse(payNowController.text.trim()) ?? 0;
        final received = double.tryParse(receivedController.text.trim()) ?? 0;
        // Same rule as the web POS: cash handed over below the amount to pay makes this a
        // partial payment of the cash received.
        final payNow = received > 0 && received < planned ? received : planned;
        final isCash = paymentMethod == 'cash';
        final isPartial = isCash && payNow > 0 && payNow < remaining - 0.004;
        final cashValid = payNow > 0 && planned <= remaining + 0.004;
        final valid =
            phoneController.text.trim().isNotEmpty &&
            _isValidTin(tinController.text) &&
            _isValidEmail(emailController.text) &&
            (!isCash || cashValid);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${order.isCreditSale ? 'Credit sale' : 'Cash sale'} · ${order.orderNumber}',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            _AmountRow(label: 'Total (incl. tax)', amount: order.totalAmount),
            if (order.withholdingAmount > 0) ...[
              _AmountRow(label: 'Withholding (kept by buyer)', amount: -order.withholdingAmount),
              _AmountRow(label: 'Net payable', amount: order.netPayable),
            ],
            if (order.paidAmount > 0) _AmountRow(label: 'Paid so far', amount: order.paidAmount),
            _AmountRow(label: 'Remaining', amount: remaining, bold: true),
            const SizedBox(height: AppSizes.padding),
            AppTextField(
              controller: phoneController,
              labelText: 'Customer phone',
              hintText: '0912345678',
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: nameController, labelText: 'Customer name (optional)'),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: emailController,
              labelText: 'Email (optional, receipt is emailed)',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: tinController,
              labelText: 'Buyer TIN (optional, 10 digits)',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: [for (final method in methods) DropdownMenuItem(value: method.value, child: Text(method.label))],
              onChanged: (value) {
                if (value != null) {
                  setState(() => paymentMethod = value);
                }
              },
            ),
            if (isCash) ...[
              const SizedBox(height: AppSizes.padding),
              AppTextField(
                controller: payNowController,
                labelText: 'Amount to pay now',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => setState(() {
                  // Keep "cash received" in step with the amount until the cashier changes it.
                  if ((double.tryParse(receivedController.text) ?? 0) < (double.tryParse(value) ?? 0)) {
                    receivedController.text = value;
                  }
                }),
              ),
              if (isPartial)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Partial payment — ${CurrencyFormatter.format(remaining - payNow)} left after this.',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              const SizedBox(height: AppSizes.padding / 2),
              AppTextField(
                controller: receivedController,
                labelText: 'Cash received',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              if (received >= payNow && payNow > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Change: ${CurrencyFormatter.format(received - payNow)}',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
            const SizedBox(height: AppSizes.padding * 1.5),
            AppButton(
              text: isCash
                  ? 'Validate payment · ${CurrencyFormatter.format(payNow)}'
                  : 'Send ${methods.firstWhere((m) => m.value == paymentMethod).label} request',
              enabled: valid,
              onTap: () {
                bloc.add(
                  PosCheckoutRequested(
                    orderId: order.id,
                    paymentMethod: paymentMethod,
                    customerPhone: phoneController.text.trim(),
                    customerName: _blankToNull(nameController.text),
                    customerTin: _blankToNull(tinController.text),
                    customerId: order.customerId,
                    customerEmail: _blankToNull(emailController.text),
                    receivedAmount: isCash ? received : null,
                    amount: isPartial ? payNow : null,
                  ),
                );
                bloc.add(const PosCartCleared());
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: bold ? FontWeight.w700 : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(CurrencyFormatter.format(amount), style: style),
        ],
      ),
    );
  }
}
