import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/pos/data/rooms_api.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// Hotel (Rooms module): guests in house with their bills, check-in, and check-out with cash,
/// Telebirr or Chapa (each charge paid in turn, then the stay closes).
class RoomBillsView extends StatefulWidget {
  const RoomBillsView({super.key, required this.roomLabel});

  final String roomLabel;

  @override
  State<RoomBillsView> createState() => _RoomBillsViewState();
}

class _RoomBillsViewState extends State<RoomBillsView> {
  final _api = RoomsApi(getIt<MposApiClient>());
  List<RoomBoardItem>? _rooms;
  String? _error;
  String? _branchId;
  var _canManage = false;
  var _canCollect = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = await getIt<SessionStorage>().loadSession();
      if (session == null) return;
      _branchId = session.branchId;
      _canManage = session.isOrgAdmin || session.hasPermission('rooms:manage');
      _canCollect = session.canCollectPayment;
      final rooms = await _api.board(session.branchId);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  String get _label => widget.roomLabel;

  @override
  Widget build(BuildContext context) {
    final rooms = _rooms;
    final occupied = rooms?.where((r) => r.isOccupied).toList() ?? const [];
    final vacant = rooms?.where((r) => r.isVacant).toList() ?? const [];

    // A sale charged to a room (or paid) changes the open orders: refresh the bills.
    return BlocListener<PosBloc, PosState>(
      listenWhen: (previous, current) => previous.openOrders != current.openOrders,
      listener: (context, state) => _load(),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _error != null
            ? ListView(
                children: [Padding(padding: const EdgeInsets.all(AppSizes.padding), child: Text(_error!))],
              )
            : rooms == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSizes.padding),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${occupied.length} in house · ${vacant.length} vacant',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (_canManage)
                        AppButton(
                          height: 36,
                          fontSize: 13,
                          padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                          text: 'Check in',
                          enabled: vacant.isNotEmpty,
                          onTap: () => _checkIn(vacant),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  if (occupied.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.padding * 2),
                      child: Text(
                        'No guests in house.${rooms.isEmpty ? ' Set up ${_label.toLowerCase()}s on the web (Rooms).' : ''}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final room in occupied)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.hotel_outlined),
                        title: Text(
                          '$_label ${room.number} · ${room.guestName ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${room.chargeCount} charge${room.chargeCount == 1 ? '' : 's'} · '
                          '${CurrencyFormatter.format(room.balance)} to pay',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openBill(room),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _checkIn(List<RoomBoardItem> vacant) async {
    var roomId = vacant.first.roomId;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    var busy = false;

    await AppDialog.show(
      title: 'Check in',
      leftButtonText: 'Cancel',
      child: StatefulBuilder(
        builder: (dialogContext, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: roomId,
              decoration: InputDecoration(labelText: _label),
              items: [
                for (final r in vacant)
                  DropdownMenuItem(value: r.roomId, child: Text('${r.number}${r.name == null ? '' : ' · ${r.name}'}')),
              ],
              onChanged: (value) => roomId = value ?? roomId,
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: nameController, labelText: 'Guest name', onChanged: (_) => setState(() {})),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: phoneController,
              labelText: 'Phone (for receipts)',
              hintText: '0912345678',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: busy ? 'Checking in…' : 'Check in',
              enabled: !busy && nameController.text.trim().isNotEmpty,
              onTap: () async {
                setState(() => busy = true);
                try {
                  await _api.checkIn(
                    branchId: _branchId!,
                    roomId: roomId,
                    guestName: nameController.text.trim(),
                    guestPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  );
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  AppSnackBar.show('${nameController.text.trim()} checked in.');
                  await _load();
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setState(() => busy = false);
                  AppSnackBar.showError(e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBill(RoomBoardItem room) async {
    if (room.stayId == null) return;
    StayInfo stay;
    try {
      stay = await _api.stay(room.stayId!);
    } catch (e) {
      AppSnackBar.showError(e.toString());
      return;
    }
    if (!mounted) return;

    final phoneController = TextEditingController(text: stay.guestPhone ?? '');
    final receivedController = TextEditingController(text: stay.balance.toStringAsFixed(2));
    var method = 'cash';
    var busy = false;
    String? progress;
    final bloc = context.read<PosBloc>();

    await AppDialog.show(
      title: '$_label ${stay.roomNumber} · ${stay.guestName}',
      leftButtonText: 'Close',
      child: StatefulBuilder(
        builder: (dialogContext, setState) {
          final theme = Theme.of(dialogContext);
          final received = double.tryParse(receivedController.text.trim()) ?? 0;
          final hasBalance = stay.balance > 0.004;
          final valid =
              !busy &&
              (!hasBalance ||
                  (phoneController.text.trim().isNotEmpty && (method != 'cash' || received + 0.004 >= stay.balance)));

          Future<void> close({double? cash, bool leaveOnAccount = false}) async {
            final change = await _api.checkOut(
              stay.id,
              receivedCash: cash,
              customerPhone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              leaveOnAccount: leaveOnAccount,
            );
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            AppSnackBar.show(
              leaveOnAccount
                  ? '${stay.guestName} checked out, ${CurrencyFormatter.format(stay.balance)} left on account.'
                  : '${stay.guestName} checked out.${change > 0 ? ' Change ${CurrencyFormatter.format(change)}.' : ''}',
            );
          }

          /// Each open charge is paid with the chosen method in turn (one receipt each).
          Future<bool> payDigitally() async {
            final orders = getIt<OrderRepository>();
            final charges = stay.openCharges;
            for (var i = 0; i < charges.length; i++) {
              final charge = charges[i];
              setState(() => progress = 'Charge ${i + 1} of ${charges.length}: waiting for the guest…');
              final started = await orders.settleTicket(
                orderId: charge.orderId,
                paymentMethod: method,
                customerPhone: phoneController.text.trim(),
                customerName: charge.customerName ?? stay.guestName,
                customerId: charge.customerId,
              );
              final payment = started.data?.payments.where((p) => p.method.toLowerCase() == method).lastOrNull;
              if (!started.isSuccess || payment == null) {
                AppSnackBar.showError(started.error?.toString() ?? 'The payment could not start.');
                return false;
              }
              if (method == 'chapa' && payment.checkoutUrl != null) {
                final uri = Uri.tryParse(payment.checkoutUrl!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
              final done = await orders.pollPaymentStatus(paymentId: payment.id, maxAttempts: 90);
              if (done.data?.status != 'Completed') {
                AppSnackBar.showError('Charge ${charge.orderNumber} was not paid.');
                return false;
              }
            }
            return true;
          }

          Future<void> checkOut() async {
            setState(() => busy = true);
            try {
              if (!hasBalance) {
                await close();
              } else if (method == 'cash') {
                await close(cash: received);
              } else if (await payDigitally()) {
                await close();
              } else if (dialogContext.mounted) {
                setState(() {
                  busy = false;
                  progress = null;
                });
              }
            } catch (e) {
              if (!dialogContext.mounted) return;
              setState(() {
                busy = false;
                progress = null;
              });
              AppSnackBar.showError(e.toString());
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in stay.charges)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(c.orderNumber, style: theme.textTheme.bodySmall)),
                      Text(CurrencyFormatter.format(c.amount), style: theme.textTheme.bodySmall),
                      if (c.remaining <= 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                        ),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(CurrencyFormatter.format(stay.balance), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (hasBalance) ...[
                const SizedBox(height: AppSizes.padding),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'cash', label: Text('Cash')),
                    ButtonSegment(value: 'telebirr', label: Text('Telebirr')),
                    ButtonSegment(value: 'chapa', label: Text('Chapa')),
                  ],
                  selected: {method},
                  onSelectionChanged: busy ? null : (value) => setState(() => method = value.first),
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(
                  controller: phoneController,
                  labelText: 'Guest phone (for the receipts)',
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                if (method == 'cash') ...[
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(
                    controller: receivedController,
                    labelText: 'Cash received',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (received > stay.balance)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Change: ${CurrencyFormatter.format(received - stay.balance)}'),
                    ),
                ],
              ],
              if (progress != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.padding / 2),
                  child: Text(progress!, style: theme.textTheme.bodySmall),
                ),
              const SizedBox(height: AppSizes.padding),
              AppButton(
                text: busy
                    ? 'Working…'
                    : !hasBalance
                    ? 'Check out'
                    : method == 'cash'
                    ? 'Check out · ${CurrencyFormatter.format(stay.balance)}'
                    : 'Pay ${stay.openCharges.length} charge${stay.openCharges.length == 1 ? '' : 's'} & check out',
                enabled: valid && (_canCollect || !hasBalance),
                onTap: checkOut,
              ),
              if (_canManage && hasBalance) ...[
                const SizedBox(height: AppSizes.padding / 2),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            await close(leaveOnAccount: true);
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            setState(() => busy = false);
                            AppSnackBar.showError(e.toString());
                          }
                        },
                  child: const Text('Leave on account'),
                ),
              ],
            ],
          );
        },
      ),
    );

    bloc.add(const PosRefreshRequested());
    await _load();
  }
}
