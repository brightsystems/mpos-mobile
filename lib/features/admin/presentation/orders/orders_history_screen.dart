import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_dropdown_field.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/invoice_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/invoice_actions.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';

const _statusFilters = ['all', 'Draft', 'Paid', 'Cancelled'];
const _pageSize = 25;

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final _repository = getIt<AdminRepository>();

  late String _orgId;
  late String _sessionBranchId;
  bool _isOrgAdmin = false;
  bool _canManageBranch = false;

  List<BranchModel> _branches = const [];
  String _selectedBranchId = '';

  List<MemberModel> _members = const [];
  String? _createdById;

  String _status = 'all';
  DateTime? _fromDate;
  DateTime? _toDate;

  int _page = 1;
  int _totalCount = 0;

  bool _loading = true;
  String? _error;
  PagedOrdersModel? _paged;

  @override
  void initState() {
    super.initState();
    final session = sessionOf(context);
    _orgId = session?.organizationId ?? '';
    _sessionBranchId = session?.branchId ?? '';
    _isOrgAdmin = session?.isOrgAdmin ?? false;
    _canManageBranch = session?.canManageBranch ?? false;
    _selectedBranchId = _sessionBranchId;

    if (_canManageBranch) {
      _init();
    } else {
      _loading = false;
    }
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_isOrgAdmin) {
      final branchesResult = await _repository.listBranches(_orgId);
      if (!mounted) return;
      _branches = branchesResult.data ?? const [];
      if (_branches.every((b) => b.id != _selectedBranchId)) {
        _selectedBranchId = _sessionBranchId.isNotEmpty && _branches.any((b) => b.id == _sessionBranchId)
            ? _sessionBranchId
            : (_branches.isNotEmpty ? _branches.first.id : '');
      }
    }

    await _loadMembers();
    await _loadOrders();
  }

  Future<void> _loadMembers() async {
    if (_selectedBranchId.isEmpty) {
      _members = const [];
      return;
    }
    final result = await _repository.listBranchMembers(_selectedBranchId);
    if (!mounted) return;
    _members = result.data ?? const [];
    if (_createdById != null && _members.every((m) => m.userId != _createdById)) {
      _createdById = null;
    }
  }

  Future<void> _loadOrders() async {
    if (_selectedBranchId.isEmpty) {
      setState(() {
        _loading = false;
        _paged = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final query = <String, String>{
      'status': _status,
      'page': '$_page',
      'pageSize': '$_pageSize',
      'includeSummary': 'true',
    };
    if ((_createdById ?? '').isNotEmpty) {
      query['createdById'] = _createdById!;
    }
    if (_fromDate != null) {
      query['from'] = _isoDate(_fromDate!);
    }
    if (_toDate != null) {
      query['to'] = _isoDate(_toDate!);
    }

    final result = await _repository.listOrders(_selectedBranchId, query);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _paged = result.data;
        _totalCount = result.data?.totalCount ?? 0;
      } else {
        _error = result.error?.toString();
      }
    });
  }

  String _isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _onBranchChanged(String branchId) async {
    if (branchId == _selectedBranchId) return;
    setState(() {
      _selectedBranchId = branchId;
      _createdById = null;
      _page = 1;
    });
    await _loadMembers();
    await _loadOrders();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _status = status;
      _page = 1;
    });
    _loadOrders();
  }

  void _onWaiterChanged(String? userId) {
    setState(() {
      _createdById = (userId ?? '').isEmpty ? null : userId;
      _page = 1;
    });
    _loadOrders();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = (isFrom ? _fromDate : _toDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
      _page = 1;
    });
    _loadOrders();
  }

  void _clearDate({required bool isFrom}) {
    setState(() {
      if (isFrom) {
        _fromDate = null;
      } else {
        _toDate = null;
      }
      _page = 1;
    });
    _loadOrders();
  }

  int get _totalPages => _totalCount == 0 ? 1 : ((_totalCount + _pageSize - 1) ~/ _pageSize);

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _page) return;
    setState(() => _page = page);
    _loadOrders();
  }

  Future<void> _openDetail(OrderListItemModel order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderDetailSheet(orderId: order.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageBranch) {
      return Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: const AppEmptyState(
          title: 'Orders unavailable',
          subtitle: 'Only organization admins and branch managers can view orders.',
        ),
      );
    }

    final items = _paged?.items ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            Text(
              'Open drafts and paid tickets for this branch.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: AppSizes.padding),
            if (_isOrgAdmin && _branches.isNotEmpty) ...[
              AdminDropdownField<String>(
                label: 'Branch',
                value: _branches.any((b) => b.id == _selectedBranchId) ? _selectedBranchId : _branches.first.id,
                items: _branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                onChanged: _onBranchChanged,
              ),
              const SizedBox(height: AppSizes.padding),
            ],
            _StatusFilterRow(status: _status, onChanged: _onStatusChanged),
            const SizedBox(height: AppSizes.padding),
            AdminDropdownField<String>(
              label: 'Waiter',
              value: _createdById ?? '',
              items: [
                const DropdownMenuItem(value: '', child: Text('All staff')),
                ..._members.map(
                  (m) => DropdownMenuItem(value: m.userId, child: Text('${m.displayName} (${m.role})')),
                ),
              ],
              onChanged: _onWaiterChanged,
            ),
            const SizedBox(height: AppSizes.padding),
            _DateRangeRow(
              fromDate: _fromDate,
              toDate: _toDate,
              onPickFrom: () => _pickDate(isFrom: true),
              onPickTo: () => _pickDate(isFrom: false),
              onClearFrom: _fromDate == null ? null : () => _clearDate(isFrom: true),
              onClearTo: _toDate == null ? null : () => _clearDate(isFrom: false),
            ),
            const SizedBox(height: AppSizes.padding),
            if (_paged != null) _SummaryTiles(summary: _paged!.summary),
            const SizedBox(height: AppSizes.padding),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.padding * 2),
                child: Center(child: AppProgressIndicator()),
              )
            else if (_error != null)
              AppEmptyState(title: 'Could not load orders', subtitle: _error, buttonText: 'Retry', onTapButton: _loadOrders)
            else if (items.isEmpty)
              const AppEmptyState(title: 'No orders', subtitle: 'No orders match these filters.')
            else ...[
              ...items.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                  child: _OrderCard(order: order, onView: () => _openDetail(order)),
                ),
              ),
              _Pager(page: _page, totalPages: _totalPages, totalCount: _totalCount, onGoTo: _goToPage),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.status, required this.onChanged});

  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _statusFilters.map((value) {
        return ChoiceChip(
          label: Text(value == 'all' ? 'All' : value),
          selected: status == value,
          onSelected: (_) => onChanged(value),
        );
      }).toList(),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.fromDate,
    required this.toDate,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onClearFrom,
    required this.onClearTo,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback? onClearFrom;
  final VoidCallback? onClearTo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateChip(label: 'From', date: fromDate, onTap: onPickFrom, onClear: onClearFrom),
        ),
        const SizedBox(width: AppSizes.padding / 2),
        Expanded(
          child: _DateChip(label: 'To', date: toDate, onTap: onPickTo, onClear: onClearTo),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.date, required this.onTap, required this.onClear});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = date == null ? label : DateFormat('yyyy-MM-dd').format(date!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.outline),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: date == null ? colorScheme.outline : colorScheme.onSurface),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: colorScheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.summary});

  final OrderSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryTile(label: 'Open drafts', value: '${summary.openDrafts}')),
        const SizedBox(width: AppSizes.padding / 2),
        Expanded(child: _SummaryTile(label: 'Paid today', value: '${summary.paidTodayCount}')),
        const SizedBox(width: AppSizes.padding / 2),
        Expanded(child: _SummaryTile(label: 'Revenue today', value: CurrencyFormatter.compact(summary.paidTodayRevenue))),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding * 0.75),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onView});

  final OrderListItemModel order;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final time = order.createdAt == null ? '' : DateFormat('MMM d, HH:mm').format(order.createdAt!.toLocal());
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: colorScheme.surfaceContainer),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.orderNumber.isNotEmpty ? order.orderNumber : 'Order',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusTag(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (time.isNotEmpty) time,
                      if (order.createdByName.isNotEmpty) order.createdByName,
                      if (order.customerPhone.isNotEmpty) order.customerPhone,
                    ].join(' · '),
                    style: textTheme.bodySmall,
                  ),
                  if (order.paymentMethods.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(order.paymentMethods.join(', '), style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(order.totalAmount),
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                _PaymentTag(status: order.paymentStatus),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.totalPages, required this.totalCount, required this.onGoTo});

  final int page;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.padding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: page > 1 ? () => onGoTo(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page $page of $totalPages · $totalCount total', style: Theme.of(context).textTheme.bodySmall),
          IconButton(
            onPressed: page < totalPages ? () => onGoTo(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'Paid':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade700;
      case 'Draft':
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
      case 'Cancelled':
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
      default:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PaymentTag extends StatelessWidget {
  const _PaymentTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color;
    switch (status) {
      case 'Paid':
        color = Colors.green.shade700;
      case 'Pending':
        color = Colors.blue.shade700;
      case 'Unpaid':
        color = Colors.orange.shade800;
      default:
        color = scheme.outline;
    }
    return Text(
      status,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  const _OrderDetailSheet({required this.orderId});

  final String orderId;

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final _repository = getIt<AdminRepository>();
  final _invoiceRepository = getIt<InvoiceRepository>();
  bool _loading = true;
  String? _error;
  OrderDetailModel? _detail;
  FiscalInvoiceEntity? _invoice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getOrder(widget.orderId);
    final invoiceResult = await _invoiceRepository.getForOrder(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invoice = invoiceResult.isSuccess ? invoiceResult.data : null;
      if (result.isSuccess) {
        _detail = result.data;
      } else {
        _error = result.error?.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.padding,
        right: AppSizes.padding,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.padding,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: _loading
            ? const Padding(padding: EdgeInsets.all(AppSizes.padding * 2), child: Center(child: AppProgressIndicator()))
            : _error != null
            ? AppEmptyState(title: 'Could not load order', subtitle: _error, buttonText: 'Retry', onTapButton: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              })
            : _detail == null
            ? const AppEmptyState(title: 'Order not found')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _detail!.orderNumber.isNotEmpty ? _detail!.orderNumber : 'Order',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusTag(status: _detail!.status),
                      ],
                    ),
                    const SizedBox(height: AppSizes.padding / 2),
                    _DetailRow(
                      label: 'Customer',
                      value: [
                        if (_detail!.customerName.isNotEmpty) _detail!.customerName,
                        if (_detail!.customerPhone.isNotEmpty) _detail!.customerPhone,
                      ].join(' · ').ifEmpty('—'),
                    ),
                    if (_detail!.createdByName.isNotEmpty) _DetailRow(label: 'Served by', value: _detail!.createdByName),
                    _DetailRow(label: 'Subtotal', value: CurrencyFormatter.format(_detail!.subtotal)),
                    _DetailRow(label: 'Tax', value: CurrencyFormatter.format(_detail!.taxAmount)),
                    _DetailRow(label: 'Total', value: CurrencyFormatter.format(_detail!.totalAmount), emphasize: true),
                    const SizedBox(height: AppSizes.padding),
                    Text('Lines', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSizes.padding / 2),
                    if (_detail!.lines.isEmpty)
                      Text('No lines.', style: textTheme.bodySmall?.copyWith(color: colorScheme.outline))
                    else
                      ..._detail!.lines.map(
                        (line) => _LineRow(
                          left: '${line.name} × ${_qty(line.quantity)}',
                          right: CurrencyFormatter.format(line.lineTotal),
                        ),
                      ),
                    const SizedBox(height: AppSizes.padding),
                    Text('Payments', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSizes.padding / 2),
                    if (_detail!.payments.isEmpty)
                      Text('No payments yet.', style: textTheme.bodySmall?.copyWith(color: colorScheme.outline))
                    else
                      ..._detail!.payments.map(
                        (payment) => _LineRow(
                          left: '${payment.method} · ${payment.status}',
                          right: CurrencyFormatter.format(payment.amount),
                        ),
                      ),
                    const SizedBox(height: AppSizes.padding),
                    if (_invoice != null) _buildInvoiceSection(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInvoiceSection(BuildContext context) {
    final invoice = _invoice!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('E-invoice', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            _StatusTag(status: invoice.status),
          ],
        ),
        const SizedBox(height: AppSizes.padding / 2),
        if (invoice.irn != null) _DetailRow(label: 'IRN', value: invoice.irn!),
        if (invoice.documentNumber != null) _DetailRow(label: 'Document #', value: invoice.documentNumber!),
        if (invoice.isCancelled) ...[
          if (invoice.cancelledAt != null)
            _DetailRow(label: 'Cancelled', value: DateFormat('d MMM y, HH:mm').format(invoice.cancelledAt!.toLocal())),
          if (invoice.cancellationRemark != null) _DetailRow(label: 'Remark', value: invoice.cancellationRemark!),
        ],
        const SizedBox(height: AppSizes.padding / 2),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => shareInvoicePdf(context, widget.orderId),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Invoice PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => shareReceiptPdf(context, widget.orderId),
                icon: const Icon(Icons.receipt_outlined, size: 18),
                label: const Text('Receipt PDF'),
              ),
            ),
          ],
        ),
        if (invoice.isSubmitted)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showCancelInvoiceDialog(
                context,
                orderId: widget.orderId,
                onCancelled: (cancelled) {
                  if (mounted) {
                    setState(() => _invoice = cancelled);
                  }
                },
              ),
              icon: Icon(Icons.cancel_outlined, size: 18, color: colorScheme.error),
              label: Text('Cancel e-invoice', style: TextStyle(color: colorScheme.error)),
            ),
          ),
        const SizedBox(height: AppSizes.padding),
      ],
    );
  }

  String _qty(double quantity) => quantity == quantity.roundToDouble() ? '${quantity.round()}' : '$quantity';
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(
            child: Text(
              value,
              style: emphasize
                  ? textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
                  : textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Row(
        children: [
          Expanded(child: Text(left, style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(width: 12),
          Text(right, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
