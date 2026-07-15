import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/usecase/usecase.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';

class LoadOpenOrdersUsecase extends Usecase<Result<List<OrderEntity>>, NoParam> {
  LoadOpenOrdersUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<List<OrderEntity>>> call(NoParam params) => _repository.getOpenOrders();
}

class CreateTicketParams {
  const CreateTicketParams(this.tableNumber);

  final String tableNumber;
}

class CreateTicketUsecase extends Usecase<Result<OrderEntity>, CreateTicketParams> {
  CreateTicketUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(CreateTicketParams params) =>
      _repository.createTicket(tableNumber: params.tableNumber);
}

class AddItemToTicketParams {
  const AddItemToTicketParams({required this.orderId, required this.menuItemId, required this.quantity});

  final String orderId;
  final String menuItemId;
  final int quantity;
}

class AddItemToTicketUsecase extends Usecase<Result<OrderEntity>, AddItemToTicketParams> {
  AddItemToTicketUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(AddItemToTicketParams params) =>
      _repository.addItemToTicket(orderId: params.orderId, menuItemId: params.menuItemId, quantity: params.quantity);
}

class UpdateTicketLineQuantityParams {
  const UpdateTicketLineQuantityParams({required this.orderId, required this.lineId, required this.quantity});

  final String orderId;
  final String lineId;
  final int quantity;
}

class UpdateTicketLineQuantityUsecase extends Usecase<Result<OrderEntity>, UpdateTicketLineQuantityParams> {
  UpdateTicketLineQuantityUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(UpdateTicketLineQuantityParams params) =>
      _repository.updateTicketLineQuantity(orderId: params.orderId, lineId: params.lineId, quantity: params.quantity);
}

class RemoveTicketLineParams {
  const RemoveTicketLineParams({required this.orderId, required this.lineId});

  final String orderId;
  final String lineId;
}

class RemoveTicketLineUsecase extends Usecase<Result<OrderEntity>, RemoveTicketLineParams> {
  RemoveTicketLineUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(RemoveTicketLineParams params) =>
      _repository.removeTicketLine(orderId: params.orderId, lineId: params.lineId);
}

class UpdateTicketTableNumberParams {
  const UpdateTicketTableNumberParams({required this.orderId, this.tableNumber});

  final String orderId;
  final String? tableNumber;
}

class UpdateTicketTableNumberUsecase extends Usecase<Result<OrderEntity>, UpdateTicketTableNumberParams> {
  UpdateTicketTableNumberUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(UpdateTicketTableNumberParams params) =>
      _repository.updateTicketTableNumber(orderId: params.orderId, tableNumber: params.tableNumber);
}

class SettleTicketParams {
  const SettleTicketParams({
    required this.orderId,
    required this.paymentMethod,
    required this.customerPhone,
    this.customerName,
    this.customerTin,
    this.receivedAmount,
    this.lineQuantities,
  });

  final String orderId;
  final String paymentMethod;
  final String customerPhone;
  final String? customerName;
  final String? customerTin;
  final double? receivedAmount;
  final Map<String, int>? lineQuantities;
}

class SettleTicketUsecase extends Usecase<Result<OrderEntity>, SettleTicketParams> {
  SettleTicketUsecase(this._repository);

  final OrderRepository _repository;

  @override
  Future<Result<OrderEntity>> call(SettleTicketParams params) => _repository.settleTicket(
    orderId: params.orderId,
    paymentMethod: params.paymentMethod,
    customerPhone: params.customerPhone,
    customerName: params.customerName,
    customerTin: params.customerTin,
    receivedAmount: params.receivedAmount,
    lineQuantities: params.lineQuantities,
  );
}
