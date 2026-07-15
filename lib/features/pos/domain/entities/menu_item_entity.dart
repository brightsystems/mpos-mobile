import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class MenuItemEntity extends Equatable {
  const MenuItemEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.price,
    this.description,
    this.sku,
    this.imageUrl,
    this.taxes = const [],
    this.trackInventory = false,
    this.stockOnHand,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final double price;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final List<TaxRateEntity> taxes;
  final bool trackInventory;
  final double? stockOnHand;
  final bool isAvailable;
  final int sortOrder;
  final DateTime? updatedAt;

  bool get isOutOfStock {
    if (!trackInventory) {
      return !isAvailable;
    }

    return (stockOnHand ?? 0) <= 0 || !isAvailable;
  }

  int get stockDisplay => trackInventory ? (stockOnHand ?? 0).floor() : 999;

  String get taxLabel => formatTaxLabel(taxes);

  @override
  List<Object?> get props => [id, name, price, stockOnHand, isAvailable, updatedAt, taxes];
}
