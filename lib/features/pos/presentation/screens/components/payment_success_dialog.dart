import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';

class PaymentSuccessDialog {
  PaymentSuccessDialog._();

  static void show({
    required BuildContext context,
    required OrderEntity order,
    FiscalInvoiceEntity? invoice,
    BusinessTypeReceipt? receipt,
    BusinessTypeVocabulary? vocabulary,
    required VoidCallback onDone,
  }) {
    final receiptProfile = receipt ?? BusinessTypeReceipt.cafeteria;
    final vocab = vocabulary ?? BusinessTypeVocabulary.cafeteria;
    final servicePoint = order.tableNumber == null || order.tableNumber == 'Walk-in'
        ? vocab.walkIn
        : order.tableNumber!;

    AppDialog.show(
      title: 'Payment successful',
      rightButtonText: 'Done',
      onTapRightButton: (dialogContext) {
        dialogContext.pop();
        onDone();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            receiptProfile.titleLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${vocab.ticket} ${order.orderNumber}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(order.totalAmount),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.padding / 2),
          if (receiptProfile.showClientName && (order.customerName?.isNotEmpty ?? false))
            Text(
              '${receiptProfile.clientNameLabel}: ${order.customerName}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (receiptProfile.showClientReference && (order.customerPhone?.isNotEmpty ?? false))
            Text(
              '${receiptProfile.clientReferenceLabel}: ${order.customerPhone}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (receiptProfile.showServicePoint)
            Text(
              '${receiptProfile.servicePointLabel}: $servicePoint',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSizes.padding / 2),
          Text(
            receiptProfile.footerNote,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          if (invoice != null) ...[
            _InvoiceSection(invoice: invoice),
          ] else ...[
            Text(
              MposConfig.mockMode
                  ? 'E-invoice is being generated…'
                  : 'Sale recorded. E-invoice appears when MOR is configured.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.invoice});

  final FiscalInvoiceEntity invoice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
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
              Icon(Icons.receipt_long, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  MposConfig.mockMode ? 'E-invoice (mock MOR)' : 'E-invoice',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: invoice.status),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          if (invoice.isSubmitted) ...[
            _InvoiceRow(label: 'IRN', value: invoice.irn ?? '—'),
            _InvoiceRow(label: 'Document #', value: invoice.documentNumber ?? '—'),
            _InvoiceRow(label: 'Type', value: invoice.transactionType ?? 'B2C'),
            _InvoiceRow(label: 'Seller', value: MockFixtures.sellerLegalName),
            if (invoice.signedQr != null) ...[
              const SizedBox(height: AppSizes.padding),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Icon(Icons.qr_code_2, size: 40, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      invoice.signedQr!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ],
            if (invoice.notifiedAt != null && invoice.notificationPhone != null) ...[
              const SizedBox(height: AppSizes.padding),
              Row(
                children: [
                  Icon(Icons.sms_outlined, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SMS sent to ${invoice.notificationPhone}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            Text(
              invoice.failureReason ?? 'E-invoice submission failed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSubmitted = status.toLowerCase() == 'submitted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSubmitted ? colorScheme.primaryContainer : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: isSubmitted ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
