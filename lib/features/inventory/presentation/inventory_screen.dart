import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/features/inventory/data/inventory_api.dart';
import 'package:mpos_mobile/features/inventory/presentation/barcode_scan_screen.dart';

/// Inventory on the phone: stock on hand per branch (search or scan), quick receiving and quick
/// stock counts. The full module (purchasing, transfers, reports) is on the web back office.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _api = InventoryApi(getIt<MposApiClient>());
  final _search = TextEditingController();

  String _orgId = '';
  String _branchId = '';
  bool _canManage = false;
  bool _canCount = false;
  bool _canApprove = false;
  bool _loading = true;
  bool _installed = true;
  String? _error;
  List<BranchInfo> _branches = const [];
  List<StockOnHand> _stock = const [];

  @override
  void initState() {
    super.initState();
    final session = sessionOf(context);
    _orgId = session?.organizationId ?? '';
    _branchId = session?.branchId ?? '';
    final admin = session?.isOrgAdmin ?? false;
    _canManage = admin || (session?.hasPermission('inventory:manage') ?? false);
    _canCount = _canManage || (session?.hasPermission('inventory:count') ?? false);
    _canApprove = admin || (session?.hasPermission('inventory:approve') ?? false);
    _start();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      _installed = await _api.isInstalled(_orgId);
      if (_installed) {
        _branches = await _api.branches(_orgId);
        if (_branchId.isEmpty || _branches.every((b) => b.id != _branchId)) {
          _branchId = _branches.isEmpty ? '' : _branches.first.id;
        }
      }
    } catch (e) {
      _error = '$e';
    }
    await _load();
  }

  Future<void> _load() async {
    if (!_installed || _branchId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stock = await _api.onHand(_branchId);
      if (!mounted) return;
      setState(() {
        _stock = stock;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<StockOnHand> get _visible {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _stock;
    return _stock.where((s) => s.name.toLowerCase().contains(q) || s.matches(q)).toList();
  }

  Future<void> _scanToFind() async {
    final code = await BarcodeScanScreen.scan(context, title: 'Find an item');
    if (code == null || !mounted) return;
    final match = _stock.where((s) => s.matches(code)).toList();
    if (match.isEmpty) {
      _snack('No item with barcode or SKU "$code".');
      return;
    }
    _search.text = match.first.name;
    setState(() {});
  }

  Future<void> _receive() async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _QuickReceiveSheet(api: _api, organizationId: _orgId, branchId: _branchId),
    );
    if (done == true) _load();
  }

  Future<void> _count() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _QuickCountScreen(api: _api, branchId: _branchId, canApprove: _canApprove),
      ),
    );
    _load();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: !_installed
          ? const _Message(
              icon: Icons.inventory_2_outlined,
              text:
                  "Inventory isn't installed for this business. The owner can install it on the web under Organization → Modules.",
            )
          : Column(
              children: [
                if (_branches.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding, AppSizes.padding, 0),
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('branch-$_branchId'),
                      initialValue: _branchId,
                      decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder()),
                      items: _branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                      onChanged: (id) {
                        _branchId = id ?? _branchId;
                        _load();
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search name, SKU or barcode',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Scan',
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _scanToFind,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_canManage || _canCount)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                    child: Row(
                      children: [
                        if (_canManage)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _branchId.isEmpty ? null : _receive,
                              icon: const Icon(Icons.move_to_inbox_outlined),
                              label: const Text('Receive'),
                            ),
                          ),
                        if (_canManage && _canCount) const SizedBox(width: 12),
                        if (_canCount)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _branchId.isEmpty ? null : _count,
                              icon: const Icon(Icons.fact_check_outlined),
                              label: const Text('Count'),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _Message(icon: Icons.error_outline, text: _error!)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: _visible.isEmpty
                              ? ListView(
                                  children: const [_Message(icon: Icons.inventory_2_outlined, text: 'No stock items.')],
                                )
                              : ListView.separated(
                                  itemCount: _visible.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final s = _visible[index];
                                    final warn = s.onHand <= 0 || s.isLow || s.expiredQuantity > 0;
                                    return ListTile(
                                      title: Text(s.name),
                                      subtitle: Text(
                                        [
                                          if (s.sku != null) s.sku!,
                                          if (s.expiredQuantity > 0) '${_fmt(s.expiredQuantity)} expired',
                                          if (s.expiredQuantity == 0 && s.expiringSoonQuantity > 0)
                                            '${_fmt(s.expiringSoonQuantity)} expiring soon',
                                          if (s.isLow && s.onHand > 0) 'Reorder',
                                        ].join(' · '),
                                      ),
                                      trailing: Text(
                                        '${_fmt(s.onHand)} ${s.stockUnit}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: warn ? scheme.error : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Receive one item: scan or pick it, then quantity, batch, expiry and cost.
class _QuickReceiveSheet extends StatefulWidget {
  const _QuickReceiveSheet({required this.api, required this.organizationId, required this.branchId});

  final InventoryApi api;
  final String organizationId;
  final String branchId;

  @override
  State<_QuickReceiveSheet> createState() => _QuickReceiveSheetState();
}

class _QuickReceiveSheetState extends State<_QuickReceiveSheet> {
  final _quantity = TextEditingController();
  final _batch = TextEditingController();
  final _cost = TextEditingController();
  List<StockItemInfo> _items = const [];
  List<StockLocationInfo> _locations = const [];
  StockItemInfo? _item;
  String? _locationId;
  DateTime? _expiry;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _batch.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final items = await widget.api.items(widget.organizationId);
      final locations = await widget.api.locations(widget.branchId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _locations = locations;
        // Deliveries usually go to the store room, else the sales location.
        _locationId = (locations.where((l) => !l.isDefault).firstOrNull ?? locations.firstOrNull)?.id;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _scan() async {
    final code = await BarcodeScanScreen.scan(context, title: 'Scan the item');
    if (code == null || !mounted) return;
    final match = _items.where((i) => i.matches(code)).firstOrNull;
    setState(() {
      _item = match ?? _item;
      _error = match == null ? 'No item with barcode or SKU "$code".' : null;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 365)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    final item = _item;
    final quantity = double.tryParse(_quantity.text.trim());
    if (item == null || _locationId == null || quantity == null || quantity <= 0) {
      setState(() => _error = 'Choose the item and the location, and enter a quantity.');
      return;
    }
    if (item.trackBatches && _batch.text.trim().isEmpty) {
      setState(() => _error = 'Enter the batch number for ${item.name}.');
      return;
    }
    if (item.trackExpiry && _expiry == null) {
      setState(() => _error = 'Choose the expiry date for ${item.name}.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.receive(
        branchId: widget.branchId,
        locationId: _locationId!,
        stockItemId: item.id,
        quantity: quantity,
        batchNumber: _batch.text.trim().isEmpty ? null : _batch.text.trim(),
        expiryDate: _expiry,
        unitCost: double.tryParse(_cost.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Received ${_fmt(quantity)} ${item.stockUnit} of ${item.name}.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.padding,
        AppSizes.padding,
        AppSizes.padding,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.padding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Receive stock', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('item-${item?.id}'),
                    initialValue: item?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item', border: OutlineInputBorder()),
                    items: _items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(i.name, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => setState(() => _item = _items.firstWhere((i) => i.id == id)),
                  ),
                ),
                IconButton.filledTonal(tooltip: 'Scan', icon: const Icon(Icons.qr_code_scanner), onPressed: _scan),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('location-$_locationId'),
              initialValue: _locationId,
              decoration: const InputDecoration(labelText: 'Into location', border: OutlineInputBorder()),
              items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
              onChanged: (id) => setState(() => _locationId = id),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity${item == null ? '' : ' (${item.stockUnit})'}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _batch,
              decoration: InputDecoration(
                labelText: 'Batch / lot${item?.trackBatches == true ? '' : ' (optional)'}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickExpiry,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _expiry == null
                    ? 'Expiry date${item?.trackExpiry == true ? '' : ' (optional)'}'
                    : 'Expires ${MaterialLocalizations.of(context).formatMediumDate(_expiry!)}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit cost (ETB, optional)', border: OutlineInputBorder()),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Receive into stock'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Count a location: start a count, scan items (each scan adds 1) or type quantities, submit.
class _QuickCountScreen extends StatefulWidget {
  const _QuickCountScreen({required this.api, required this.branchId, required this.canApprove});

  final InventoryApi api;
  final String branchId;
  final bool canApprove;

  @override
  State<_QuickCountScreen> createState() => _QuickCountScreenState();
}

class _QuickCountScreenState extends State<_QuickCountScreen> {
  List<StockLocationInfo> _locations = const [];
  String? _locationId;
  bool _blind = true;
  bool _busy = false;
  String? _error;
  StockCountInfo? _count;
  final Map<String, TextEditingController> _counted = {};

  @override
  void initState() {
    super.initState();
    widget.api
        .locations(widget.branchId)
        .then((locations) {
          if (!mounted) return;
          setState(() {
            _locations = locations;
            _locationId = (locations.where((l) => l.isDefault).firstOrNull ?? locations.firstOrNull)?.id;
          });
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = '$e');
        });
  }

  @override
  void dispose() {
    for (final c in _counted.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _show(StockCountInfo count) {
    for (final line in count.lines) {
      final text = line.counted == null ? '' : _fmt(line.counted!);
      (_counted[line.id] ??= TextEditingController()).text = text;
    }
    setState(() => _count = count);
  }

  Future<void> _run(Future<StockCountInfo> Function() action, {String? done}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final count = await action();
      if (!mounted) return;
      _show(count);
      if (done != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, double?> get _values => {for (final e in _counted.entries) e.key: double.tryParse(e.value.text.trim())};

  Future<void> _scan() async {
    final count = _count;
    if (count == null) return;
    final code = await BarcodeScanScreen.scan(context, title: 'Scan to count +1');
    if (code == null || !mounted) return;
    final line = count.lines.where((l) => l.matches(code)).firstOrNull;
    if (line == null) {
      setState(() => _error = 'No item with barcode or SKU "$code" in this count.');
      return;
    }
    final controller = _counted[line.id]!;
    controller.text = _fmt((double.tryParse(controller.text) ?? 0) + 1);
    setState(() => _error = null);
  }

  Future<void> _submit() => _run(() async {
    final saved = await widget.api.saveCount(widget.branchId, _count!.id, _values);
    return widget.api.countAction(widget.branchId, saved.id, 'submit');
  }, done: 'Count submitted.');

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return Scaffold(
      appBar: AppBar(title: Text(count == null ? 'Stock count' : '${count.number} · ${count.locationName}')),
      body: count == null ? _startForm(context) : _countList(context, count),
    );
  }

  Widget _startForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.padding),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('location-$_locationId'),
          initialValue: _locationId,
          decoration: const InputDecoration(labelText: 'Location to count', border: OutlineInputBorder()),
          items: _locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
          onChanged: (id) => setState(() => _locationId = id),
        ),
        SwitchListTile(
          value: _blind,
          onChanged: (v) => setState(() => _blind = v),
          title: const Text('Blind count'),
          subtitle: const Text("Counters don't see the expected quantities."),
        ),
        const Text('Expected quantities are taken now: count straight away, before more sales.'),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy || _locationId == null
              ? null
              : () => _run(
                  () => widget.api.startCount(branchId: widget.branchId, locationId: _locationId!, blind: _blind),
                ),
          child: const Text('Start count'),
        ),
      ],
    );
  }

  Widget _countList(BuildContext context, StockCountInfo count) {
    final open = count.status == 'Open';
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: count.lines.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final line = count.lines[index];
              return ListTile(
                title: Text(line.name),
                subtitle: Text(
                  line.expected == null
                      ? (line.barcode ?? line.sku ?? '')
                      : 'Expected ${_fmt(line.expected!)} ${line.stockUnit}',
                ),
                trailing: SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _counted[line.id],
                    enabled: open,
                    textAlign: TextAlign.end,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(isDense: true, suffixText: line.stockUnit, hintText: '—'),
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              children: [
                Expanded(child: Text(count.status, overflow: TextOverflow.ellipsis)),
                if (open) ...[
                  IconButton.filledTonal(
                    tooltip: 'Scan +1',
                    onPressed: _busy ? null : _scan,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _run(() => widget.api.saveCount(widget.branchId, count.id, _values), done: 'Saved.'),
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _busy ? null : _submit, child: const Text('Submit')),
                ],
                if (count.status == 'Submitted' && widget.canApprove)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => widget.api.countAction(widget.branchId, count.id, 'approve'),
                            done: 'Approved: differences posted to stock.',
                          ),
                    child: const Text('Approve'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
