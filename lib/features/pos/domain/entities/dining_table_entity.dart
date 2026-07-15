import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

class DiningTableEntity extends Equatable {
  const DiningTableEntity({required this.tableNumber, required this.tickets});

  final String tableNumber;
  final List<OrderEntity> tickets;

  int get openTicketCount => tickets.where((ticket) => !ticket.isClosed).length;

  double get unpaidTotal => tickets.fold<double>(0, (sum, ticket) => sum + ticket.remainingTotal);

  bool get isOccupied => openTicketCount > 0;

  @override
  List<Object?> get props => [tableNumber, tickets];
}
