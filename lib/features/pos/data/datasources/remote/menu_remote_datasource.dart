import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/pos/data/datasources/menu_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class MenuRemoteDatasource implements MenuDatasource {
  MenuRemoteDatasource(this._client);

  final MposApiClient _client;

  Future<List<MenuItemEntity>> syncBranchMenu({required String branchId, DateTime? since}) async {
    final query = since == null ? '' : '?since=${Uri.encodeComponent(since.toUtc().toIso8601String())}';
    final response = await _client.get(
      '/branches/$branchId/menu$query',
      authenticated: true,
      fromJson: (json) => _mapMenuSync(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  List<MenuItemEntity> _mapMenuSync(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    // Inventory module rules for the whole business (absent when it isn't installed).
    final negativeStock = reader.string('negativeStock', fallback: 'Block');
    final nearExpiryDays = reader.integer('nearExpiryDays', fallback: 30);

    return reader
        .listOfMaps('items')
        .map((item) => _mapMenuItem(item, negativeStock: negativeStock, nearExpiryDays: nearExpiryDays))
        .where((item) => item.isAvailable)
        .toList();
  }

  MenuItemEntity _mapMenuItem(Map<String, dynamic> json, {String negativeStock = 'Block', int nearExpiryDays = 30}) {
    final reader = JsonReader(json);

    return MenuItemEntity(
      id: reader.string('id'),
      categoryId: reader.string('categoryId'),
      categoryName: reader.string('categoryName'),
      name: reader.string('name'),
      price: reader.number('price'),
      description: reader.string('description').isEmpty ? null : reader.string('description'),
      sku: reader.string('sku').isEmpty ? null : reader.string('sku'),
      imageUrl: reader.string('imageUrl').isEmpty ? null : reader.string('imageUrl'),
      taxes: reader.listOfMaps('taxes').map(_mapTax).toList(),
      trackInventory: reader.boolean('trackInventory'),
      // Kept when negative: a business may sell below zero.
      stockOnHand: json['stockOnHand'] == null ? null : reader.number('stockOnHand'),
      isAvailable: reader.boolean('isAvailable', fallback: true),
      sortOrder: reader.integer('sortOrder'),
      updatedAt: reader.dateTime('updatedAt'),
      nearestExpiry: reader.dateTime('nearestExpiry'),
      negativeStock: negativeStock.isEmpty ? 'Block' : negativeStock,
      nearExpiryDays: nearExpiryDays,
    );
  }

  TaxRateEntity _mapTax(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final mor = reader.string('morTaxCode');

    return TaxRateEntity(
      id: reader.string('id'),
      name: reader.string('name'),
      code: reader.string('code'),
      ratePercent: reader.number('ratePercent'),
      morTaxCode: mor.isEmpty ? null : mor,
    );
  }
}
