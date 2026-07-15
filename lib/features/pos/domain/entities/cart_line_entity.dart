import 'package:equatable/equatable.dart';

class CartLineEntity extends Equatable {
  const CartLineEntity({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.stockOnHand,
    this.trackInventory = false,
  });

  final String menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final double? stockOnHand;
  final bool trackInventory;

  double get lineTotal => unitPrice * quantity;

  CartLineEntity copyWith({int? quantity}) {
    return CartLineEntity(
      menuItemId: menuItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      stockOnHand: stockOnHand,
      trackInventory: trackInventory,
    );
  }

  @override
  List<Object?> get props => [menuItemId, quantity, unitPrice];
}
