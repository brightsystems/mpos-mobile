import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/pos/data/folio_api.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// Hotel: the open bill of every room (sales charged to the room), settled at check-out.
class RoomBillsView extends StatefulWidget {
  const RoomBillsView({super.key, required this.roomLabel});

  final String roomLabel;

  @override
  State<RoomBillsView> createState() => _RoomBillsViewState();
}

class _RoomBillsViewState extends State<RoomBillsView> {
  final _api = FolioApi(getIt<MposApiClient>());
  List<FolioInfo>? _folios;
  String? _error;
  String? _branchId;
  var _canSettle = false;

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
      _canSettle = session.canCollectPayment;
      final folios = await _api.list(session.branchId);
      if (!mounted) return;
      setState(() {
        _folios = folios;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final folios = _folios;

    return RefreshIndicator(
      onRefresh: _load,
      child: _error != null
          ? ListView(
              children: [Padding(padding: const EdgeInsets.all(AppSizes.padding), child: Text(_error!))],
            )
          : folios == null
          ? const Center(child: CircularProgressIndicator())
          : folios.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSizes.padding * 2),
                  child: Text(
                    'No open ${widget.roomLabel.toLowerCase()} bills. Charge a sale to a ${widget.roomLabel.toLowerCase()} at checkout.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.padding),
              itemCount: folios.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
              itemBuilder: (context, index) => _folioCard(context, folios[index]),
            ),
    );
  }

  Widget _folioCard(BuildContext context, FolioInfo folio) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey(folio.room),
      child: ExpansionTile(
        leading: const Icon(Icons.hotel_outlined),
        title: Text(
          '${widget.roomLabel} ${folio.room}${folio.guestName == null ? '' : ' · ${folio.guestName}'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${folio.orderCount} charges · ${CurrencyFormatter.format(folio.balance)} to pay'),
        childrenPadding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding),
        children: [
          for (final line in folio.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${line.name} x${line.quantity.round()}')),
                  Text(CurrencyFormatter.format(line.amount)),
                ],
              ),
            ),
          if (folio.paid > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Text('Paid so far ${CurrencyFormatter.format(folio.paid)}', style: theme.textTheme.labelSmall),
            ),
          const SizedBox(height: AppSizes.padding / 2),
          AppButton(
            width: double.infinity,
            height: 40,
            fontSize: 14,
            text: _canSettle
                ? 'Check out · ${CurrencyFormatter.format(folio.balance)}'
                : 'Cashier settles at check-out',
            enabled: _canSettle,
            onTap: () => _settle(folio),
          ),
        ],
      ),
    );
  }

  Future<void> _settle(FolioInfo folio) async {
    final phoneController = TextEditingController(text: folio.guestPhone ?? '');
    final receivedController = TextEditingController(text: folio.balance.toStringAsFixed(2));
    var busy = false;
    final bloc = context.read<PosBloc>();

    await AppDialog.show(
      title: 'Check out ${widget.roomLabel.toLowerCase()} ${folio.room}',
      leftButtonText: 'Cancel',
      child: StatefulBuilder(
        builder: (dialogContext, setState) {
          final received = double.tryParse(receivedController.text.trim()) ?? 0;
          final valid = !busy && received + 0.004 >= folio.balance && phoneController.text.trim().isNotEmpty;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Balance ${CurrencyFormatter.format(folio.balance)} (${folio.orderCount} charges), paid in cash.'),
              const SizedBox(height: AppSizes.padding),
              AppTextField(
                controller: phoneController,
                labelText: 'Guest phone (for the receipts)',
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              AppTextField(
                controller: receivedController,
                labelText: 'Cash received',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              if (received > folio.balance)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Change: ${CurrencyFormatter.format(received - folio.balance)}'),
                ),
              const SizedBox(height: AppSizes.padding),
              AppButton(
                text: busy ? 'Settling…' : 'Settle the bill',
                enabled: valid,
                onTap: () async {
                  setState(() => busy = true);
                  try {
                    final change = await _api.settle(
                      branchId: _branchId!,
                      room: folio.room,
                      receivedAmount: received,
                      customerPhone: phoneController.text.trim(),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    AppSnackBar.show(
                      '${widget.roomLabel} ${folio.room} settled.${change > 0 ? ' Change ${CurrencyFormatter.format(change)}.' : ''}',
                    );
                    bloc.add(const PosRefreshRequested());
                    await _load();
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    setState(() => busy = false);
                    AppSnackBar.showError(e.toString());
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
