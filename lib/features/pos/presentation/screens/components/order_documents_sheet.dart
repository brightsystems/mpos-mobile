import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/data/shift_api.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/invoice_actions.dart';

/// Every fiscal document of an order (invoice, a receipt per payment, credit/debit notes, void),
/// each with its PDF, in a bottom sheet.
Future<void> showOrderDocumentsSheet(BuildContext context, {required String orderId, required String title}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (sheetContext, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding / 2),
              child: Text(
                'Documents · $title',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: OrderDocumentsList(orderId: orderId, controller: controller),
            ),
          ],
        ),
      ),
    );

class OrderDocumentsList extends StatefulWidget {
  const OrderDocumentsList({super.key, required this.orderId, this.controller});

  final String orderId;
  final ScrollController? controller;

  @override
  State<OrderDocumentsList> createState() => _OrderDocumentsListState();
}

class _OrderDocumentsListState extends State<OrderDocumentsList> {
  final _api = getIt<ShiftApi>();

  List<OrderDocumentInfo> _documents = const [];
  bool _loading = true;
  String? _error;
  int? _opening;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final documents = await _api.orderDocuments(widget.orderId);
      if (mounted) setState(() => _documents = documents);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(OrderDocumentInfo document, int index) async {
    setState(() => _opening = index);
    try {
      switch (document.kind) {
        case 'RECEIPT':
          await shareReceiptPdf(context, widget.orderId, paymentId: document.paymentId);
        case 'CREDIT_NOTE' || 'DEBIT_NOTE':
          await shareMemoPdf(context, orderId: widget.orderId, memoId: document.memoId ?? '');
        default:
          // The invoice, and the void (the cancelled invoice).
          await shareInvoicePdf(context, widget.orderId);
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: AppSizes.padding / 2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Try again')),
          ),
        ],
      );
    }
    if (_documents.isEmpty) {
      return ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(AppSizes.padding),
        children: const [Text('No fiscal documents yet (the invoice is created when the order is submitted).')],
      );
    }

    return ListView.separated(
      controller: widget.controller,
      padding: const EdgeInsets.only(bottom: AppSizes.padding),
      itemCount: _documents.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final d = _documents[index];
        final color = _kindColor(theme, d.kind);
        final lines = <String>[
          [
            if ((d.number ?? '').isNotEmpty) 'No. ${d.number}',
            if (d.issuedAt != null) DateFormat('d MMM y, HH:mm').format(d.issuedAt!),
            d.status,
          ].join(' · '),
          if ((d.reference ?? '').isNotEmpty) d.reference!,
          if ((d.note ?? '').isNotEmpty) d.note!,
        ];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            child: Icon(_kindIcon(d.kind), size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(d.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (d.amount != null) Text(CurrencyFormatter.format(d.amount!), style: theme.textTheme.labelLarge),
            ],
          ),
          subtitle: Text(lines.join('\n'), maxLines: 4, overflow: TextOverflow.ellipsis),
          isThreeLine: lines.length > 1,
          trailing: d.downloadable
              ? IconButton(
                  tooltip: 'Open ${d.label.toLowerCase()} PDF',
                  onPressed: _opening == null ? () => _open(d, index) : null,
                  icon: _opening == index
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined),
                )
              : null,
        );
      },
    );
  }

  static IconData _kindIcon(String kind) => switch (kind) {
    'RECEIPT' => Icons.receipt_long_outlined,
    'CREDIT_NOTE' => Icons.remove_circle_outline,
    'DEBIT_NOTE' => Icons.add_circle_outline,
    'VOID' => Icons.block,
    _ => Icons.description_outlined,
  };

  static Color _kindColor(ThemeData theme, String kind) => switch (kind) {
    'RECEIPT' => Colors.green.shade700,
    'CREDIT_NOTE' => Colors.orange.shade800,
    'DEBIT_NOTE' => Colors.blueGrey,
    'VOID' => theme.colorScheme.error,
    _ => theme.colorScheme.primary,
  };
}
