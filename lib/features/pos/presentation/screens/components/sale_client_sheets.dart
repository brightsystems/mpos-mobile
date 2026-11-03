import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/pos/data/rooms_api.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/pos/domain/entities/customer_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/pos_client.dart';
import 'package:mpos_mobile/features/pos/domain/pos_rules.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// Adds a product to the current sale the way the business type sells: a clinic or consultancy
/// asks for the patient/client first, a pharmacy asks for the prescription of an Rx product.
Future<void> addItemToSale(BuildContext context, MenuItemEntity item, {int quantity = 1, String? tableNumber}) async {
  final bloc = context.read<PosBloc>();
  final state = bloc.state;

  if (item.isOutOfStock) {
    AppSnackBar.show('${item.name} is out of stock.');
    return;
  }

  PosClient? client;
  if (PosRules.needsClient(state.pos, state.activeClient)) {
    client = await showClientSheet(context, requireName: true, apply: false);
    if (client == null) {
      return;
    }
  }

  if (!context.mounted) return;
  if (PosRules.needsPrescription(bloc.state.pos, item, client ?? bloc.state.activeClient)) {
    client = await showPrescriptionSheet(context, item, current: client, apply: false);
    if (client == null) {
      return;
    }
  }

  bloc.add(PosItemAdded(item, quantity, tableNumber: tableNumber ?? bloc.state.activeTableNumber, client: client));
}

/// Picks who the sale is for: a saved customer, or a name, phone and the business's reference
/// (room, patient code, engagement). Returns the client set on the sale, or null when cancelled.
/// With [apply] the client is set on the sale; otherwise the caller passes it on (with an item).
/// [fresh] starts empty (a new patient/client) instead of editing the current one.
Future<PosClient?> showClientSheet(
  BuildContext context, {
  bool requireName = false,
  bool apply = true,
  bool fresh = false,
}) async {
  final bloc = context.read<PosBloc>();
  final state = bloc.state;
  final current = fresh ? null : state.activeClient;
  final word = state.clientWord;
  final referenceLabel = state.clientReferenceLabel;
  final isGuest = state.pos.chargeToRoom;
  if (isGuest) {
    // Hotels charge a guest checked in to a room (Rooms module), never a typed room number.
    final picked = await showRoomPicker(context);
    if (!_roomsUnavailable) {
      if (picked != null && apply) {
        bloc.add(PosClientChanged(picked));
      }
      return picked;
    }
    // No Rooms module: the room is typed below.
    if (!context.mounted) return null;
  }
  final nameController = TextEditingController(text: current?.name ?? '');
  final phoneController = TextEditingController(text: current?.phone ?? '');
  final referenceController = TextEditingController(text: current?.reference ?? '');
  final searchController = TextEditingController();
  var customerId = current?.customerId;
  var results = <CustomerEntity>[];
  var searching = false;

  final result = await AppDialog.show(
    title: isGuest ? 'Guest / $referenceLabel' : (current == null ? 'New ${word.toLowerCase()}' : word),
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> search() async {
          setState(() => searching = true);
          final found = await getIt<OrderRepository>().searchCustomers(searchController.text);
          if (!dialogContext.mounted) return;
          setState(() {
            searching = false;
            results = found.data ?? const [];
          });
          if (!found.isSuccess) {
            AppSnackBar.showError(found.error?.toString() ?? 'Could not load customers.');
          }
        }

        final valid = !requireName || nameController.text.trim().isNotEmpty || customerId != null;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isGuest) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: searchController,
                      labelText: 'Saved ${word.toLowerCase()} (name or TIN)',
                      textInputAction: TextInputAction.search,
                      onEditingComplete: search,
                    ),
                  ),
                  IconButton(
                    onPressed: searching ? null : search,
                    icon: searching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              for (final item in results.take(5))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.legalName),
                  subtitle: Text(
                    [item.transactionType, if ((item.tin ?? '').isNotEmpty) 'TIN ${item.tin}'].join(' · '),
                  ),
                  onTap: () => setState(() {
                    customerId = item.id;
                    nameController.text = item.legalName;
                    if ((item.phone ?? '').isNotEmpty) {
                      phoneController.text = item.phone!;
                    }
                    results = const [];
                  }),
                ),
              const SizedBox(height: AppSizes.padding / 2),
            ],
            if (isGuest) ...[
              AppTextField(
                controller: referenceController,
                labelText: referenceLabel,
                hintText: 'Leave empty for a walk-in',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSizes.padding / 2),
            ],
            AppTextField(
              controller: nameController,
              labelText: requireName ? '$word name' : '$word name (optional)',
              onChanged: (_) => setState(() => customerId = null),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: phoneController,
              labelText: 'Phone (optional)',
              hintText: '0912345678',
              keyboardType: TextInputType.phone,
            ),
            if (!isGuest) ...[
              const SizedBox(height: AppSizes.padding / 2),
              AppTextField(controller: referenceController, labelText: '$referenceLabel (optional)'),
            ],
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: 'Save',
              enabled: valid,
              onTap: () => Navigator.of(dialogContext).pop(
                PosClient(
                  name: _blankToNull(nameController.text),
                  phone: _blankToNull(phoneController.text),
                  reference: _blankToNull(referenceController.text),
                  customerId: customerId,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  if (result is! PosClient) {
    return null;
  }

  if (apply) {
    bloc.add(PosClientChanged(result));
  }
  return result;
}

/// Asks once per sale for the prescription number (and the patient) of a prescription-only product.
Future<PosClient?> showPrescriptionSheet(
  BuildContext context,
  MenuItemEntity item, {
  PosClient? current,
  bool apply = true,
}) async {
  final bloc = context.read<PosBloc>();
  current ??= bloc.state.activeClient;
  final rxController = TextEditingController(text: current?.reference ?? '');
  final nameController = TextEditingController(text: current?.name ?? '');

  final result = await AppDialog.show(
    title: 'Prescription required',
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${item.name} is sold only against a prescription.'),
            const SizedBox(height: AppSizes.padding),
            AppTextField(
              controller: rxController,
              labelText: 'Prescription number',
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: nameController, labelText: 'Patient name (optional)'),
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: 'Add to sale',
              enabled: rxController.text.trim().isNotEmpty,
              onTap: () => Navigator.of(dialogContext).pop(
                PosClient(
                  name: _blankToNull(nameController.text),
                  phone: current?.phone,
                  reference: rxController.text.trim(),
                  customerId: current?.customerId,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  if (result is! PosClient) {
    return null;
  }

  if (apply) {
    bloc.add(PosClientChanged(result));
  }
  return result;
}

String? _blankToNull(String value) => value.trim().isEmpty ? null : value.trim();

/// Set when the room board can't be loaded (no Rooms module): the sheet falls back to typing.
bool _roomsUnavailable = false;

/// Picks the guest of an occupied room (or walk-in: an empty client). Null when cancelled or when
/// the business has no Rooms module.
Future<PosClient?> showRoomPicker(BuildContext context) async {
  _roomsUnavailable = false;
  final session = await getIt<SessionStorage>().loadSession();
  List<RoomBoardItem> rooms;
  try {
    rooms = (await RoomsApi(getIt<MposApiClient>()).board(session?.branchId ?? '')).where((r) => r.isOccupied).toList();
  } catch (_) {
    _roomsUnavailable = true;
    return null;
  }

  if (!context.mounted) return null;
  final label = context.read<PosBloc>().state.clientReferenceLabel;
  final searchController = TextEditingController();

  final result = await AppDialog.show(
    title: 'Guest / $label',
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (dialogContext, setState) {
        final query = searchController.text.trim().toLowerCase();
        final shown = rooms
            .where(
              (r) =>
                  query.isEmpty ||
                  r.number.toLowerCase().contains(query) ||
                  (r.guestName ?? '').toLowerCase().contains(query),
            )
            .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: searchController,
              labelText: 'Search $label or guest',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.directions_walk),
              title: const Text('Walk-in (no room)'),
              onTap: () => Navigator.of(dialogContext).pop(const PosClient()),
            ),
            if (rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.padding),
                child: Text('No guests checked in. Check guests in from the Rooms tab.'),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final room in shown)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.hotel_outlined),
                      title: Text('$label ${room.number}'),
                      subtitle: Text(room.guestName ?? ''),
                      onTap: () => Navigator.of(
                        dialogContext,
                      ).pop(PosClient(name: room.guestName, phone: room.guestPhone, reference: room.number)),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return result is PosClient ? result : null;
}
