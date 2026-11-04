import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/pos/domain/entities/customer_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/pos_client.dart';
import 'package:mpos_mobile/features/pos/domain/pos_rules.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// POS checkout, laid out like the web POS order panel: the totals, the customer (walking customer
/// by default, or a saved one), then
/// - a draft order: cash or credit sale and "Payment", which submits it and registers the MoR
///   invoice (B2B/B2G withholding is calculated by the API from the buyer);
/// - a submitted order: the payment method, "Buyer withholds tax" (on by default when there is
///   withholding), the amount to pay now, cash received, quick cash and "Validate payment".
Future<void> startCheckout(BuildContext context, OrderEntity order) => _showCheckoutSheet(context, order);

/// Collects a payment on a submitted order (the same sheet, payment part).
Future<void> showPaymentDialog(BuildContext context, OrderEntity order) => _showCheckoutSheet(context, order);

Future<void> _showCheckoutSheet(BuildContext context, OrderEntity order) {
  final bloc = context.read<PosBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _CheckoutSheet(order: order),
      ),
    ),
  );
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

double _round2(double value) => (value * 100).roundToDouble() / 100;

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({required this.order});

  final OrderEntity order;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late OrderEntity order = widget.order;

  // Customer, as on the web POS: walking customer unless a saved one is chosen.
  CustomerEntity? customer;
  String? customerId;
  late final phone = TextEditingController(text: order.customerPhone ?? _client?.phone ?? '');
  late final name = TextEditingController(text: order.customerName ?? _client?.name ?? '');
  late final tin = TextEditingController(text: order.customerTin ?? '');
  late final email = TextEditingController(text: order.customerEmail ?? '');

  // Draft: cash or credit sale.
  late String saleMode = order.isCreditSale ? 'CREDIT' : 'CASH';

  // Payment.
  late String paymentMethod;
  bool buyerWithholds = true;
  final payNow = TextEditingController();
  final received = TextEditingController();

  bool busy = false;

  PosBloc get _bloc => context.read<PosBloc>();

  PosClient? get _client => context.read<PosBloc>().state.ticketClients[widget.order.id];

  @override
  void initState() {
    super.initState();
    customerId = order.customerId ?? _client?.customerId;
    final methods = _bloc.state.enabledPaymentMethods;
    paymentMethod = methods.isEmpty ? 'cash' : methods.first.value;
    _resetPaymentAmounts();
  }

  @override
  void dispose() {
    for (final c in [phone, name, tin, email, payNow, received]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isWalkingCustomer => customerId == null;

  /// Withholding the buyer may still keep on this order (none once kept).
  double get _withholdingAvailable {
    final alreadyKept = (order.totalAmount - order.netPayable).clamp(0, double.infinity);
    return (order.withholdingAmount - alreadyKept).clamp(0, double.infinity).toDouble();
  }

  double get _remaining => order.remainingTotal;

  /// What the buyer pays now in all: the balance, less the withholding when the buyer withholds.
  double get _amountPayable {
    final withheld = buyerWithholds ? _withholdingAvailable.clamp(0, _remaining).toDouble() : 0.0;
    return _round2(_remaining - withheld);
  }

  double get _amountIfBuyerWithholds => _round2(_remaining - _withholdingAvailable.clamp(0, _remaining));

  /// The amount entered to pay now (at most what is payable; empty = all of it).
  double get _payingNow {
    final entered = double.tryParse(payNow.text.trim());
    return entered != null && entered > 0 ? _round2(entered.clamp(0, _amountPayable).toDouble()) : _amountPayable;
  }

  bool get _isPartialPayment => _payingNow < _amountPayable - 0.005;

  double? get _receivedAmount => double.tryParse(received.text.trim());

  double? get _changeDue {
    final cash = _receivedAmount;
    return cash == null || cash < _payingNow ? null : cash - _payingNow;
  }

  /// "Amount to pay now" and the cash received start at the whole payable amount.
  void _resetPaymentAmounts() {
    final amount = _amountPayable.toStringAsFixed(2);
    payNow.text = amount;
    received.text = amount;
  }

  // ── Customer ───────────────────────────────────────────────────────────────────────────────

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<_CustomerChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CustomerPicker(word: _bloc.state.clientWord),
    );
    if (picked == null || !mounted) return;
    if (picked.customer == null) {
      _clearCustomer();
    } else {
      _selectCustomer(picked.customer!);
    }
  }

  /// Every buyer field follows the chosen customer; nothing is kept from the previous one.
  void _selectCustomer(CustomerEntity picked) => setState(() {
    customer = picked;
    customerId = picked.id;
    name.text = picked.legalName;
    tin.text = picked.tin ?? '';
    phone.text = picked.phone ?? '';
    email.text = picked.email ?? '';
  });

  /// Back to the walking customer: the saved customer's details are cleared.
  void _clearCustomer() => setState(() {
    customer = null;
    customerId = null;
    name.clear();
    tin.clear();
    phone.clear();
    email.clear();
  });

  bool _buyerValid({bool requirePhone = false}) {
    if (!_isValidTin(tin.text)) {
      AppSnackBar.showError('Check the TIN: enter the 10 digits or leave it empty.');
      return false;
    }
    if (!_isValidEmail(email.text)) {
      AppSnackBar.showError('Enter a valid email address or leave it empty.');
      return false;
    }
    if (requirePhone && phone.text.trim().isEmpty) {
      AppSnackBar.showError('A phone number is required for the payment and the fiscal receipt.');
      return false;
    }
    return true;
  }

  // ── Draft: submit ──────────────────────────────────────────────────────────────────────────

  Future<void> _submit({bool chargeToRoom = false}) async {
    final state = _bloc.state;
    if (!_buyerValid()) return;
    if (state.pos.clientRequired && customerId == null && name.text.trim().isEmpty) {
      AppSnackBar.showError('Choose the ${state.clientWord.toLowerCase()} first: pick a saved one or enter a name.');
      return;
    }

    final room = _client?.reference ?? order.clientReference;
    setState(() => busy = true);
    final result = await getIt<OrderRepository>().submitOrder(
      orderId: order.id,
      customerPhone: _blankToNull(phone.text),
      customerName: _blankToNull(name.text),
      customerTin: _blankToNull(tin.text),
      customerId: customerId,
      paymentMode: chargeToRoom ? 'CREDIT' : saleMode,
      customerEmail: _blankToNull(email.text),
      clientReference: room,
    );
    if (!mounted) return;

    if (!result.isSuccess || result.data == null) {
      setState(() => busy = false);
      AppSnackBar.showError(result.error?.toString() ?? 'Submit failed.');
      return;
    }

    final submitted = result.data!;
    _bloc.add(PosOrderUpdated(submitted));

    if (chargeToRoom) {
      // On the room's bill until check-out: the next sale starts fresh.
      _bloc.add(const PosNewSaleStarted());
      Navigator.of(context).pop();
      AppSnackBar.show('Charged to ${state.clientReferenceLabel.toLowerCase()} $room.');
      return;
    }

    final session = await getIt<SessionStorage>().loadSession();
    if (!mounted) return;
    if (!(session?.canCollectPayment ?? false)) {
      Navigator.of(context).pop();
      AppSnackBar.show('Order submitted for ${state.vocabulary.cashier.toLowerCase()} approval.');
      return;
    }

    // As on the web POS: the order stays open here with the payment area.
    setState(() {
      order = submitted;
      busy = false;
      buyerWithholds = true;
      _resetPaymentAmounts();
    });
    AppSnackBar.show('Order submitted. MoR invoice registration started.');
  }

  // ── Submitted: pay ─────────────────────────────────────────────────────────────────────────

  void _pay() {
    if (!_buyerValid(requirePhone: true)) return;
    final isCash = paymentMethod == 'cash';
    final withhold = buyerWithholds && _withholdingAvailable > 0;

    _bloc.add(
      PosCheckoutRequested(
        orderId: order.id,
        paymentMethod: paymentMethod,
        customerPhone: phone.text.trim(),
        customerName: _blankToNull(name.text),
        customerTin: _blankToNull(tin.text),
        customerId: customerId,
        customerEmail: _blankToNull(email.text),
        receivedAmount: isCash ? (_receivedAmount ?? _payingNow) : null,
        amount: isCash && _isPartialPayment ? _payingNow : null,
        withholdTax: withhold,
      ),
    );
    _bloc.add(const PosCartCleared());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _bloc.state;
    final word = state.clientWord;
    final room = _client?.reference ?? order.clientReference;
    final canChargeToRoom = order.isDraft && PosRules.canChargeToRoom(state.pos, _client ?? PosClient.fromOrder(order));
    final methods = state.enabledPaymentMethods;
    final withholding = _withholdingAvailable;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding * 2),
        children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Text(
                  order.isDraft ? 'New order' : 'Order ${order.orderNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Chip(
                label: Text(order.status),
                visualDensity: VisualDensity.compact,
                backgroundColor: order.status == 'Paid' ? Colors.green.shade50 : theme.colorScheme.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),

          // ── Totals ──
          _SumRow(label: 'Subtotal', amount: order.subtotal),
          if (order.discountAmount > 0) _SumRow(label: 'Discount', amount: -order.discountAmount),
          _SumRow(label: 'Taxes', amount: order.taxAmount),
          _SumRow(label: 'Total', amount: order.totalAmount, bold: true, suffix: ' ETB'),
          if (!order.isDraft && buyerWithholds && withholding > 0) ...[
            _SumRow(label: 'Withholding (kept by buyer)', amount: -withholding),
            _SumRow(label: 'Customer pays', amount: _amountPayable, bold: true, suffix: ' ETB'),
          ],
          const SizedBox(height: AppSizes.padding),

          // ── Customer (walking customer by default) ──
          InkWell(
            key: const ValueKey('customer-picker'),
            onTap: busy ? null : _pickCustomer,
            borderRadius: BorderRadius.circular(AppSizes.radius),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Saved ${word.toLowerCase()} (name, TIN, phone)',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(_isWalkingCustomer ? Icons.person_outline : Icons.business_outlined),
                suffixIcon: _isWalkingCustomer
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        tooltip: 'Back to walking customer',
                        icon: const Icon(Icons.clear),
                        onPressed: busy ? null : _clearCustomer,
                      ),
              ),
              child: Text(
                _isWalkingCustomer
                    ? 'Walking customer'
                    : [customer?.legalName ?? name.text, if (customer != null) customer!.transactionType].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(
            controller: phone,
            hintText: 'Phone (required to pay)',
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(
            controller: email,
            hintText: 'Email (invoice & receipts are emailed)',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          if (room != null && room.isNotEmpty) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Text('${state.clientReferenceLabel}: $room', style: theme.textTheme.labelLarge),
          ],
          const SizedBox(height: AppSizes.padding / 2),
          if (_isWalkingCustomer)
            AppTextField(
              controller: name,
              hintText: '$word name${state.pos.clientRequired ? ' (required)' : ' (optional)'}',
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppTextField(controller: name, hintText: 'Name'),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Expanded(
                  child: AppTextField(
                    controller: tin,
                    hintText: 'TIN (10 digits)',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSizes.padding),

          if (order.isDraft) ..._draftArea(theme, canChargeToRoom, room, state.clientReferenceLabel),
          if (!order.isDraft && order.status != 'Paid') ..._paymentArea(theme, methods, withholding),
        ],
      ),
    );
  }

  List<Widget> _draftArea(ThemeData theme, bool canChargeToRoom, String? room, String referenceLabel) => [
    SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'CASH', label: Text('Cash sale'), icon: Icon(Icons.payments_outlined)),
        ButtonSegment(value: 'CREDIT', label: Text('Credit sale'), icon: Icon(Icons.schedule)),
      ],
      selected: {saleMode},
      onSelectionChanged: busy ? null : (value) => setState(() => saleMode = value.first),
    ),
    const SizedBox(height: AppSizes.padding),
    if (canChargeToRoom) ...[
      AppButton(
        text: busy
            ? 'Submitting…'
            : 'Charge to ${referenceLabel.toLowerCase()} $room · ${CurrencyFormatter.format(order.totalAmount)}',
        enabled: !busy,
        onTap: () => _submit(chargeToRoom: true),
      ),
      const SizedBox(height: AppSizes.padding / 2),
    ],
    AppButton(
      text: busy ? 'Submitting…' : 'Payment · ${CurrencyFormatter.format(order.totalAmount)}',
      enabled: !busy,
      onTap: _submit,
    ),
  ];

  List<Widget> _paymentArea(ThemeData theme, List<({String value, String label})> methods, double withholding) {
    final isCash = paymentMethod == 'cash';
    final methodLabel = methods.where((m) => m.value == paymentMethod).firstOrNull?.label ?? paymentMethod;
    final change = _changeDue;

    return [
      if (methods.isEmpty)
        Text('No payment methods are enabled for this business.', style: TextStyle(color: theme.colorScheme.error))
      else
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in methods)
              ChoiceChip(
                avatar: Icon(method.value == 'cash' ? Icons.account_balance_wallet_outlined : Icons.phone_android),
                label: Text(method.label),
                selected: paymentMethod == method.value,
                onSelected: (_) => setState(() => paymentMethod = method.value),
              ),
          ],
        ),
      if (withholding > 0) ...[
        const SizedBox(height: AppSizes.padding / 2),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          value: buyerWithholds,
          onChanged: (value) => setState(() {
            buyerWithholds = value ?? false;
            _resetPaymentAmounts();
          }),
          title: Text('Buyer withholds tax (−${CurrencyFormatter.format(withholding)})'),
          subtitle: Text(
            'Off: the buyer pays the full amount (FULL receipt). On: the buyer pays '
            '${CurrencyFormatter.format(_amountIfBuyerWithholds)} and the receipt is PARTIAL.',
          ),
        ),
      ],
      if (isCash) ...[
        if (order.paidAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.padding / 2),
            child: Text(
              'Paid so far ${CurrencyFormatter.format(order.paidAmount)} · Remaining ${CurrencyFormatter.format(_amountPayable)}',
              style: theme.textTheme.labelMedium,
            ),
          ),
        const SizedBox(height: AppSizes.padding / 2),
        AppTextField(
          controller: payNow,
          labelText: 'Amount to pay now',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => setState(() {}),
        ),
        if (_isPartialPayment)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Partial — ${CurrencyFormatter.format(_amountPayable - _payingNow)} left after this',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        const SizedBox(height: AppSizes.padding / 2),
        AppTextField(
          controller: received,
          hintText: 'Cash received',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
        if (change != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Change: ${CurrencyFormatter.format(change)}',
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (_bloc.state.pos.quickCash && _payingNow > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final amount in PosRules.quickCashAmounts(_payingNow))
                  ActionChip(
                    label: Text((amount - _payingNow).abs() < 0.005 ? 'Exact' : CurrencyFormatter.format(amount)),
                    onPressed: () => setState(() => received.text = amount.toStringAsFixed(2)),
                  ),
              ],
            ),
          ),
      ],
      const SizedBox(height: AppSizes.padding * 1.5),
      AppButton(
        text: isCash
            ? 'Validate payment · ${CurrencyFormatter.format(_payingNow)}'
            : 'Send $methodLabel ${paymentMethod == 'telebirr' ? 'prompt' : 'request'} · ${CurrencyFormatter.format(_amountPayable)}',
        enabled: methods.isNotEmpty && _payingNow > 0,
        onTap: _pay,
      ),
    ];
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow({required this.label, required this.amount, this.bold = false, this.suffix = ''});

  final String label;
  final double amount;
  final bool bold;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.bodySmall)?.copyWith(
      fontWeight: bold ? FontWeight.w700 : null,
    );
    final text = amount < 0 ? '−${CurrencyFormatter.format(-amount)}' : CurrencyFormatter.format(amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$text$suffix', style: style),
        ],
      ),
    );
  }
}

/// The choice from the saved-customer list: a customer, or the walking customer (null).
class _CustomerChoice {
  const _CustomerChoice(this.customer);

  final CustomerEntity? customer;
}

/// Saved customers by name, TIN or phone, with "Walking customer" first (as on the web POS).
class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker({required this.word});

  final String word;

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final _search = TextEditingController();
  Timer? _timer;
  List<CustomerEntity> _results = const [];
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    final generation = ++_generation;
    setState(() => _loading = true);
    final result = await getIt<OrderRepository>().searchCustomers(query.trim());
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      _results = result.data ?? const [];
    });
    if (!result.isSuccess) {
      AppSnackBar.showError(result.error?.toString() ?? 'Could not load customers.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding / 2),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _timer?.cancel();
                _timer = Timer(const Duration(milliseconds: 250), () => _load(value));
              },
              decoration: InputDecoration(
                hintText: 'Saved ${widget.word.toLowerCase()} (name, TIN, phone)',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Walking customer'),
                  subtitle: const Text('B2C · —'),
                  onTap: () => Navigator.of(context).pop(const _CustomerChoice(null)),
                ),
                const Divider(height: 1),
                for (final c in _results)
                  ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(c.legalName),
                    subtitle: Text(
                      [
                        c.transactionType,
                        (c.tin ?? '').isNotEmpty ? c.tin! : ((c.phone ?? '').isNotEmpty ? c.phone! : '—'),
                        if (c.isWithholdingAgent) 'Withholding agent',
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.of(context).pop(_CustomerChoice(c)),
                  ),
                if (!_loading && _results.isEmpty && _search.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    child: Text(
                      'No saved ${widget.word.toLowerCase()} matches "${_search.text.trim()}".',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
