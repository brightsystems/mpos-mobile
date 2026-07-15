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

    return reader.listOfMaps('items').map(_mapMenuItem).where((item) => item.isAvailable).toList();
  }

  MenuItemEntity _mapMenuItem(Map<String, dynamic> json) {
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
      stockOnHand: reader.number('stockOnHand', fallback: -1) < 0 ? null : reader.number('stockOnHand'),
      isAvailable: reader.boolean('isAvailable', fallback: true),
      sortOrder: reader.integer('sortOrder'),
      updatedAt: reader.dateTime('updatedAt'),
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
