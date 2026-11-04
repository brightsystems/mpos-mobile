import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/data/shift_api.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/order_documents_sheet.dart';

const _pageSize = 20;
final _dateTime = DateFormat('d MMM, HH:mm');

/// Loads a server-side list one page at a time as the user scrolls, filtered by a search box.
class _PagedList<T> {
  _PagedList(this.fetch);

  final Future<PageOf<T>> Function(int page, String search) fetch;

  List<T> items = const [];
  int total = 0;
  int page = 0;
  bool loading = false;
  bool hasMore = true;
  String? error;
  String search = '';
  int _generation = 0;

  Future<void> reset(VoidCallback changed) async {
    _generation++;
    items = const [];
    total = 0;
    page = 0;
    hasMore = true;
    error = null;
    loading = false;
    await more(changed);
  }

  Future<void> more(VoidCallback changed) async {
    if (loading || !hasMore) return;
    final generation = _generation;
    loading = true;
    error = null;
    changed();
    try {
      final result = await fetch(page + 1, search);
      if (generation != _generation) return;
      items = [...items, ...result.items];
      total = result.totalCount;
      page = result.page;
      hasMore = result.hasMore;
    } catch (e) {
      if (generation == _generation) error = e.toString();
    } finally {
      if (generation == _generation) {
        loading = false;
        changed();
      }
    }
  }
}

/// A search box that waits for the user to stop typing.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.hint, required this.onSearch});

  final String hint;
  final ValueChanged<String> onSearch;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), () => widget.onSearch(value.trim()));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding / 2, AppSizes.padding, AppSizes.padding / 2),
    child: TextField(
      controller: _controller,
      onChanged: _changed,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _changed('');
                },
              ),
      ),
    ),
  );
}

/// Footer of a paged list: spinner while loading, the error with a retry, or the end.
Widget _footer(BuildContext context, _PagedList<dynamic> list, VoidCallback retry, String noun) {
  final theme = Theme.of(context);
  if (list.loading) {
    return const Padding(
      padding: EdgeInsets.all(AppSizes.padding),
      child: Center(child: CircularProgressIndicator()),
    );
  }
  if (list.error != null) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        children: [
          Text(
            list.error!,
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ],
      ),
    );
  }
  if (list.items.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding * 2),
      child: Text(
        list.search.isEmpty ? 'No $noun yet.' : 'No $noun match "${list.search}".',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.all(AppSizes.padding),
    child: Column(
      children: [
        Text(
          '${list.items.length} of ${list.total} $noun',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        if (list.hasMore) TextButton(onPressed: retry, child: const Text('Load more')),
      ],
    ),
  );
}

/// The cashier's shifts on this branch, newest first, searchable; tap one for its orders.
class MyShiftsScreen extends StatefulWidget {
  const MyShiftsScreen({super.key});

  @override
  State<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends State<MyShiftsScreen> {
  final _api = getIt<ShiftApi>();
  late final _list = _PagedList<ShiftInfo>(
    (page, search) => _api.myShiftsPage(page: page, pageSize: _pageSize, search: search),
  );

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _list.reset(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My shifts')),
      body: Column(
        children: [
          _SearchField(
            hint: 'Search: shift number, register, note, open or closed',
            onSearch: (value) {
              _list.search = value;
              _list.reset(_changed);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _list.reset(_changed),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) _list.more(_changed);
                  return false;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _list.items.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _list.items.length) {
                      return _footer(context, _list, () => _list.more(_changed), 'shifts');
                    }
                    final s = _list.items[index];
                    final difference = s.cashDifference;
                    return ListTile(
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => ShiftOrdersScreen(shift: s))),
                      leading: Icon(
                        s.isOpen ? Icons.play_circle_outline : Icons.check_circle_outline,
                        color: s.isOpen ? Colors.green.shade700 : theme.hintColor,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(s.sessionNo, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(CurrencyFormatter.format(s.salesTotal), style: theme.textTheme.labelLarge),
                        ],
                      ),
                      subtitle: Text(
                        [
                          [
                            s.status,
                            '${s.ordersCount} orders',
                            if ((s.sourceName ?? '').isNotEmpty) s.sourceName!,
                          ].join(' · '),
                          '${_dateTime.format(s.openedAt)} → ${s.closedAt == null ? 'open' : _dateTime.format(s.closedAt!)}',
                          if (difference != null && difference.abs() >= 0.005)
                            'Cash ${difference > 0 ? 'over' : 'short'} ${CurrencyFormatter.format(difference.abs())}',
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A shift's orders, newest first, searchable; tap an order for its documents.
class ShiftOrdersScreen extends StatefulWidget {
  const ShiftOrdersScreen({super.key, required this.shift});

  final ShiftInfo shift;

  @override
  State<ShiftOrdersScreen> createState() => _ShiftOrdersScreenState();
}

class _ShiftOrdersScreenState extends State<ShiftOrdersScreen> {
  final _api = getIt<ShiftApi>();
  late final _list = _PagedList<ShiftOrderInfo>(
    (page, search) => _api.shiftOrdersPage(widget.shift.id, page: page, pageSize: _pageSize, search: search),
  );

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _list.reset(_changed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Orders · ${widget.shift.sessionNo}')),
      body: Column(
        children: [
          _SearchField(
            hint: 'Search: order, buyer, phone, TIN, invoice no.',
            onSearch: (value) {
              _list.search = value;
              _list.reset(_changed);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _list.reset(_changed),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) _list.more(_changed);
                  return false;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _list.items.length + 1,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _list.items.length) {
                      return _footer(context, _list, () => _list.more(_changed), 'orders');
                    }
                    final o = _list.items[index];
                    final buyer = [
                      o.customerName?.isNotEmpty == true ? o.customerName! : 'Walk-in',
                      if ((o.customerPhone ?? '').isNotEmpty) o.customerPhone!,
                      if ((o.customerTin ?? '').isNotEmpty) 'TIN ${o.customerTin}',
                    ].join(' · ');
                    final fiscal = o.invoiceVoided
                        ? 'Void'
                        : (o.salesReceiptRrn ?? '').isNotEmpty
                        ? 'Receipt'
                        : (o.irn ?? '').isNotEmpty
                        ? 'Invoice'
                        : null;
                    return ListTile(
                      onTap: () => showOrderDocumentsSheet(context, orderId: o.id, title: o.orderNumber),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(CurrencyFormatter.format(o.totalAmount), style: theme.textTheme.labelLarge),
                        ],
                      ),
                      subtitle: Text(
                        [
                          buyer,
                          [
                            o.status,
                            if ((o.paymentMethod ?? '').isNotEmpty) o.paymentMethod!,
                            if (o.remainingAmount > 0) 'owes ${CurrencyFormatter.format(o.remainingAmount)}',
                            ?fiscal,
                            _dateTime.format(o.createdAt),
                          ].join(' · '),
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: Tooltip(
                        message: 'Documents',
                        child: Icon(
                          o.invoiceVoided ? Icons.block : Icons.folder_open_outlined,
                          color: o.invoiceVoided ? theme.colorScheme.error : theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
