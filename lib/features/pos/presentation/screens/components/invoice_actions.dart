import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_memo_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/invoice_repository.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// MoR cancellation reason codes (same set the web POS offers).
const invoiceCancellationReasons = <({String value, String label})>[
  (value: '1', label: 'Duplicate'),
  (value: '2', label: 'Data entry mistake'),
  (value: '3', label: 'Order cancelled'),
  (value: '4', label: 'Others'),
];

Future<void> shareInvoicePdf(BuildContext context, String orderId) async {
  final result = await getIt<InvoiceRepository>().getInvoicePdf(orderId);

  if (!context.mounted) return;

  if (!result.isSuccess || result.data == null) {
    AppSnackBar.showError(result.error?.toString() ?? 'Failed to load invoice PDF.');
    return;
  }

  await Printing.sharePdf(bytes: result.data!.bytes, filename: result.data!.fileName);
}

Future<void> shareReceiptPdf(BuildContext context, String orderId) async {
  final result = await getIt<InvoiceRepository>().getReceiptPdf(orderId);

  if (!context.mounted) return;

  if (!result.isSuccess || result.data == null) {
    AppSnackBar.showError(result.error?.toString() ?? 'Failed to load receipt PDF.');
    return;
  }

  await Printing.sharePdf(bytes: result.data!.bytes, filename: result.data!.fileName);
}

Future<void> shareMemoPdf(BuildContext context, {required String orderId, required String memoId}) async {
  final result = await getIt<InvoiceRepository>().getMemoPdf(orderId: orderId, memoId: memoId);

  if (!context.mounted) return;

  if (!result.isSuccess || result.data == null) {
    AppSnackBar.showError(result.error?.toString() ?? 'Failed to load memo PDF.');
    return;
  }

  await Printing.sharePdf(bytes: result.data!.bytes, filename: result.data!.fileName);
}

/// Memo types accepted by MoR (same as web POS).
const memoTypes = <({String value, String label})>[
  (value: 'CRE', label: 'Credit note (refund)'),
  (value: 'DEB', label: 'Debit note (extra charge)'),
];

/// Shows the credit/debit memo registration dialog. Calls [onRegistered]
/// with the registered memo when MoR accepts it.
void showRegisterMemoDialog(
  BuildContext context, {
  required String orderId,
  required List<({String id, String name, double maxQuantity, double unitPrice})> lines,
  required ValueChanged<FiscalMemoEntity> onRegistered,
}) {
  var memoType = 'CRE';
  final reasonController = TextEditingController();
  // Per item: quantity and the pre-tax amount (empty = unit price × quantity), as on the web POS.
  final quantityControllers = {for (final line in lines) line.id: TextEditingController()};
  final amountControllers = {for (final line in lines) line.id: TextEditingController()};
  var busy = false;

  double quantityOf(String id) => double.tryParse(quantityControllers[id]!.text.trim()) ?? 0;
  double? amountOf(String id) => double.tryParse(amountControllers[id]!.text.trim());

  AppDialog.show(
    title: 'Issue credit/debit note',
    leftButtonText: 'Back',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        final reason = reasonController.text.trim();
        final hasLines = lines.any((line) => quantityOf(line.id) > 0);
        // Credit notes cannot exceed the invoiced quantity or amount.
        final withinLimits =
            memoType != 'CRE' ||
            lines.every((line) {
              final quantity = quantityOf(line.id);
              final amount = amountOf(line.id);
              return quantity <= line.maxQuantity && (amount == null || amount <= line.unitPrice * quantity + 0.004);
            });
        final valid = reason.length >= 3 && reason.length <= 100 && hasLines && withinLimits;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: memoType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [for (final type in memoTypes) DropdownMenuItem(value: type.value, child: Text(type.label))],
              onChanged: (value) {
                if (value != null) {
                  setState(() => memoType = value);
                }
              },
            ),
            const SizedBox(height: AppSizes.padding),
            AppTextField(
              controller: reasonController,
              labelText: 'Reason (3-100 chars)',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding),
            Text('Lines', style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.padding / 2),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${line.name} · ${CurrencyFormatter.format(line.unitPrice)} × max ${_qty(line.maxQuantity)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: quantityControllers[line.id],
                            labelText: 'Qty',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: amountControllers[line.id],
                            enabled: quantityOf(line.id) > 0,
                            labelText: 'Amount (pre-tax)',
                            hintText: (line.unitPrice * quantityOf(line.id)).toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (!withinLimits)
              Text(
                'A credit note cannot exceed the invoiced quantity or amount.',
                style: Theme.of(
                  dialogContext,
                ).textTheme.labelSmall?.copyWith(color: Theme.of(dialogContext).colorScheme.error),
              ),
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: busy ? 'Registering…' : 'Register memo',
              enabled: valid && !busy,
              onTap: () async {
                setState(() => busy = true);

                final result = await getIt<InvoiceRepository>().registerMemo(
                  orderId: orderId,
                  memoType: memoType,
                  reason: reason,
                  lines: [
                    for (final line in lines)
                      if (quantityOf(line.id) > 0)
                        (
                          orderLineId: line.id,
                          quantity: quantityOf(line.id),
                          // A changed amount is sent as the unit price it implies (amount ÷ quantity).
                          unitPrice: amountOf(line.id) == null
                              ? null
                              : (amountOf(line.id)! / quantityOf(line.id) * 10000).roundToDouble() / 10000,
                        ),
                  ],
                );

                if (!dialogContext.mounted) return;

                if (!result.isSuccess || result.data == null) {
                  setState(() => busy = false);
                  AppSnackBar.showError(result.error?.toString() ?? 'Memo registration failed.');
                  return;
                }

                Navigator.of(dialogContext).pop();
                onRegistered(result.data!);
              },
            ),
          ],
        );
      },
    ),
  );
}

String _qty(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

/// Shows the MoR cancellation dialog. Calls [onCancelled] with the updated
/// invoice when the cancellation succeeds.
void showCancelInvoiceDialog(
  BuildContext context, {
  required String orderId,
  required ValueChanged<FiscalInvoiceEntity> onCancelled,
}) {
  var reasonCode = '3';
  final remarkController = TextEditingController();
  var busy = false;

  AppDialog.show(
    title: 'Cancel e-invoice',
    leftButtonText: 'Back',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This voids the fiscal invoice with MoR. The order itself is not refunded.',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.padding),
            DropdownButtonFormField<String>(
              initialValue: reasonCode,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: [
                for (final reason in invoiceCancellationReasons)
                  DropdownMenuItem(value: reason.value, child: Text(reason.label)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => reasonCode = value);
                }
              },
            ),
            const SizedBox(height: AppSizes.padding),
            AppTextField(controller: remarkController, labelText: 'Remark (optional)'),
            const SizedBox(height: AppSizes.padding * 1.5),
            AppButton(
              text: busy ? 'Cancelling…' : 'Cancel invoice',
              enabled: !busy,
              onTap: () async {
                setState(() => busy = true);

                final result = await getIt<InvoiceRepository>().cancelInvoice(
                  orderId: orderId,
                  reasonCode: reasonCode,
                  remark: remarkController.text.trim().isEmpty ? null : remarkController.text.trim(),
                );

                if (!dialogContext.mounted) return;

                if (!result.isSuccess || result.data == null) {
                  setState(() => busy = false);
                  AppSnackBar.showError(result.error?.toString() ?? 'Failed to cancel invoice.');
                  return;
                }

                Navigator.of(dialogContext).pop();
                onCancelled(result.data!);
              },
            ),
          ],
        );
      },
    ),
  );
}
