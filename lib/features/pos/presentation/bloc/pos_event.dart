import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';

sealed class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class PosStarted extends PosEvent {
  const PosStarted();
}

class PosRefreshRequested extends PosEvent {
  const PosRefreshRequested();
}

class PosSearchChanged extends PosEvent {
  const PosSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class PosTableTicketCreated extends PosEvent {
  const PosTableTicketCreated(this.tableNumber);

  final String tableNumber;

  @override
  List<Object?> get props => [tableNumber];
}

class PosTicketSelected extends PosEvent {
  const PosTicketSelected(this.ticketId);

  final String ticketId;

  @override
  List<Object?> get props => [ticketId];
}

class PosActiveTicketTableChanged extends PosEvent {
  const PosActiveTicketTableChanged(this.tableNumber);

  final String tableNumber;

  @override
  List<Object?> get props => [tableNumber];
}

class PosItemAdded extends PosEvent {
  const PosItemAdded(this.item, this.quantity, {this.tableNumber});

  final MenuItemEntity item;
  final int quantity;
  final String? tableNumber;

  @override
  List<Object?> get props => [item, quantity, tableNumber];
}

class PosLineQuantityChanged extends PosEvent {
  const PosLineQuantityChanged(this.lineId, this.quantity);

  final String lineId;
  final int quantity;

  @override
  List<Object?> get props => [lineId, quantity];
}

class PosLineRemoved extends PosEvent {
  const PosLineRemoved(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}

class PosSplitQuantityChanged extends PosEvent {
  const PosSplitQuantityChanged(this.lineId, this.quantity);

  final String lineId;
  final int quantity;

  @override
  List<Object?> get props => [lineId, quantity];
}

class PosCartCleared extends PosEvent {
  const PosCartCleared();
}

class PosPanelExpandedChanged extends PosEvent {
  const PosPanelExpandedChanged(this.isExpanded);

  final bool isExpanded;

  @override
  List<Object?> get props => [isExpanded];
}

class PosCheckoutRequested extends PosEvent {
  const PosCheckoutRequested({
    required this.orderId,
    required this.paymentMethod,
    required this.customerPhone,
    this.customerName,
    this.receivedAmount,
    this.selectedOnly = false,
    this.splitQuantities,
  });

  final String orderId;
  final String paymentMethod;
  final String customerPhone;
  final String? customerName;
  final double? receivedAmount;
  final bool selectedOnly;
  final Map<String, int>? splitQuantities;

  @override
  List<Object?> get props => [
    orderId,
    paymentMethod,
    customerPhone,
    customerName,
    receivedAmount,
    selectedOnly,
    splitQuantities,
  ];
}

class PosCheckoutDismissed extends PosEvent {
  const PosCheckoutDismissed();
}

class PosTablesFocusCleared extends PosEvent {
  const PosTablesFocusCleared();
}
