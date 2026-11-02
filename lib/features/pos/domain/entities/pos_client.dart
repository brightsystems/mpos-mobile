import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

/// Who a sale is for: a hotel guest and room, a patient and patient code, a client, or the
/// patient and prescription number of a pharmacy sale.
class PosClient extends Equatable {
  const PosClient({this.name, this.phone, this.reference, this.customerId});

  factory PosClient.fromOrder(OrderEntity order) => PosClient(
    name: order.customerName,
    phone: order.customerPhone,
    reference: order.clientReference,
    customerId: order.customerId,
  );

  final String? name;
  final String? phone;

  /// Room number, patient code, prescription number or engagement reference.
  final String? reference;

  /// A saved customer picked for the sale.
  final String? customerId;

  bool get hasName => (name ?? '').trim().isNotEmpty || customerId != null;

  bool get hasReference => (reference ?? '').trim().isNotEmpty;

  bool get isEmpty => !hasName && !hasReference && (phone ?? '').trim().isEmpty;

  /// A short label for chips: "Sara · 101".
  String label() => [if ((name ?? '').trim().isNotEmpty) name!.trim(), if (hasReference) reference!.trim()].join(' · ');

  /// This client with details from [other] filling the blanks.
  PosClient mergedWith(PosClient? other) => other == null
      ? this
      : PosClient(
          name: (name ?? '').trim().isNotEmpty ? name : other.name,
          phone: (phone ?? '').trim().isNotEmpty ? phone : other.phone,
          reference: hasReference ? reference : other.reference,
          customerId: customerId ?? other.customerId,
        );

  @override
  List<Object?> get props => [name, phone, reference, customerId];
}
