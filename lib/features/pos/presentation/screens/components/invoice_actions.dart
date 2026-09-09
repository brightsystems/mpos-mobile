import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
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
