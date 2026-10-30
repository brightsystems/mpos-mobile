import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';

/// One item's stock in a branch.
class StockOnHand {
  const StockOnHand({
    required this.stockItemId,
    required this.name,
    required this.stockUnit,
    required this.onHand,
    required this.value,
    required this.isLow,
    this.sku,
    this.barcode,
    this.nearestExpiry,
    this.expiredQuantity = 0,
    this.expiringSoonQuantity = 0,
  });

  factory StockOnHand.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StockOnHand(
      stockItemId: r.string('stockItemId'),
      name: r.string('name'),
      sku: _blank(r.string('sku')),
      barcode: _blank(r.string('barcode')),
      stockUnit: r.string('stockUnit', fallback: 'PCS'),
      onHand: r.number('onHand'),
      value: r.number('value'),
      isLow: r.boolean('isLow'),
      nearestExpiry: r.dateTime('nearestExpiry'),
      expiredQuantity: r.number('expiredQuantity'),
      expiringSoonQuantity: r.number('expiringSoonQuantity'),
    );
  }

  final String stockItemId;
  final String name;
  final String? sku;
  final String? barcode;
  final String stockUnit;
  final double onHand;
  final double value;
  final bool isLow;
  final DateTime? nearestExpiry;
  final double expiredQuantity;
  final double expiringSoonQuantity;

  bool matches(String code) {
    final c = code.trim().toLowerCase();
    return c.isNotEmpty && (barcode?.toLowerCase() == c || sku?.toLowerCase() == c);
  }
}

/// A stock item (for its batch / expiry rules).
class StockItemInfo {
  const StockItemInfo({
    required this.id,
    required this.name,
    required this.stockUnit,
    required this.trackBatches,
    required this.trackExpiry,
    this.sku,
    this.barcode,
  });

  factory StockItemInfo.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StockItemInfo(
      id: r.string('id'),
      name: r.string('name'),
      sku: _blank(r.string('sku')),
      barcode: _blank(r.string('barcode')),
      stockUnit: r.string('stockUnit', fallback: 'PCS'),
      trackBatches: r.boolean('trackBatches'),
      trackExpiry: r.boolean('trackExpiry'),
    );
  }

  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String stockUnit;
  final bool trackBatches;
  final bool trackExpiry;

  bool matches(String code) {
    final c = code.trim().toLowerCase();
    return c.isNotEmpty && (barcode?.toLowerCase() == c || sku?.toLowerCase() == c);
  }
}

class StockLocationInfo {
  const StockLocationInfo({required this.id, required this.name, required this.isDefault, required this.isActive});

  factory StockLocationInfo.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StockLocationInfo(
      id: r.string('id'),
      name: r.string('name'),
      isDefault: r.boolean('isDefault'),
      isActive: r.boolean('isActive', fallback: true),
    );
  }

  final String id;
  final String name;
  final bool isDefault;
  final bool isActive;
}

class StockCountLine {
  const StockCountLine({
    required this.id,
    required this.stockItemId,
    required this.name,
    required this.stockUnit,
    this.sku,
    this.barcode,
    this.expected,
    this.counted,
  });

  factory StockCountLine.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StockCountLine(
      id: r.string('id'),
      stockItemId: r.string('stockItemId'),
      name: r.string('stockItemName'),
      sku: _blank(r.string('sku')),
      barcode: _blank(r.string('barcode')),
      stockUnit: r.string('stockUnit', fallback: 'PCS'),
      expected: json['expectedQuantity'] == null ? null : r.number('expectedQuantity'),
      counted: json['countedQuantity'] == null ? null : r.number('countedQuantity'),
    );
  }

  final String id;
  final String stockItemId;
  final String name;
  final String? sku;
  final String? barcode;
  final String stockUnit;
  final double? expected;
  final double? counted;

  bool matches(String code) {
    final c = code.trim().toLowerCase();
    return c.isNotEmpty && (barcode?.toLowerCase() == c || sku?.toLowerCase() == c);
  }
}

class StockCountInfo {
  const StockCountInfo({
    required this.id,
    required this.number,
    required this.status,
    required this.locationName,
    required this.blind,
    required this.lines,
  });

  factory StockCountInfo.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StockCountInfo(
      id: r.string('id'),
      number: r.string('number'),
      status: r.string('status'),
      locationName: r.string('locationName'),
      blind: r.boolean('blind'),
      lines: r.listOfMaps('lines').map(StockCountLine.fromJson).toList(),
    );
  }

  final String id;
  final String number;
  final String status;
  final String locationName;
  final bool blind;
  final List<StockCountLine> lines;
}

class BranchInfo {
  const BranchInfo({required this.id, required this.name});

  final String id;
  final String name;
}

/// Inventory module calls used on the phone: stock on hand, receiving and counting.
class InventoryApi {
  InventoryApi(this._client);

  final MposApiClient _client;

  Future<bool> isInstalled(String organizationId) async {
    final modules = await _get(
      '/organizations/$organizationId/modules',
      (json) => (json as List).cast<Map<String, dynamic>>(),
    );
    return modules.any((m) => JsonReader(m).string('key') == 'inventory' && JsonReader(m).boolean('installed'));
  }

  Future<List<BranchInfo>> branches(String organizationId) => _get(
    '/organizations/$organizationId/branches',
    (json) => (json as List)
        .cast<Map<String, dynamic>>()
        .map((b) => BranchInfo(id: JsonReader(b).string('id'), name: JsonReader(b).string('name')))
        .toList(),
  );

  Future<List<StockOnHand>> onHand(String branchId) => _get(
    '/branches/$branchId/inventory/on-hand',
    (json) => (json as List).cast<Map<String, dynamic>>().map(StockOnHand.fromJson).toList(),
  );

  Future<List<StockItemInfo>> items(String organizationId) => _get(
    '/organizations/$organizationId/inventory/items',
    (json) => (json as List).cast<Map<String, dynamic>>().map(StockItemInfo.fromJson).toList(),
  );

  Future<List<StockLocationInfo>> locations(String branchId) => _get(
    '/branches/$branchId/inventory/locations',
    (json) =>
        (json as List).cast<Map<String, dynamic>>().map(StockLocationInfo.fromJson).where((l) => l.isActive).toList(),
  );

  /// Stock received into a location (a new batch with its number, expiry and unit cost).
  Future<void> receive({
    required String branchId,
    required String locationId,
    required String stockItemId,
    required double quantity,
    String? batchNumber,
    DateTime? expiryDate,
    double? unitCost,
  }) => _send('POST', '/branches/$branchId/inventory/adjustments', {
    'locationId': locationId,
    'stockItemId': stockItemId,
    'quantity': quantity,
    'type': 'Receipt',
    'reason': 'Received on mobile',
    'batchNumber': batchNumber,
    'expiryDate': expiryDate == null ? null : _date(expiryDate),
    'unitCost': unitCost,
  });

  Future<StockCountInfo> startCount({required String branchId, required String locationId, required bool blind}) =>
      _send('POST', '/branches/$branchId/inventory/counts', {
        'locationId': locationId,
        'blind': blind,
        'notes': 'Counted on mobile',
        'stockItemIds': null,
      }, StockCountInfo.fromJson);

  Future<StockCountInfo> saveCount(String branchId, String countId, Map<String, double?> counted) =>
      _send('PUT', '/branches/$branchId/inventory/counts/$countId', {
        'lines': counted.entries.map((e) => {'lineId': e.key, 'countedQuantity': e.value}).toList(),
      }, StockCountInfo.fromJson);

  Future<StockCountInfo> countAction(String branchId, String countId, String action) =>
      _send('POST', '/branches/$branchId/inventory/counts/$countId/$action', {}, StockCountInfo.fromJson);

  Future<T> _get<T>(String path, T Function(Object? json) map) async {
    final response = await _client.get(path, authenticated: true, fromJson: map);
    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data as T;
  }

  Future<T> _send<T>(
    String method,
    String path,
    Map<String, dynamic> body, [
    T Function(Map<String, dynamic> json)? map,
  ]) async {
    Object? parse(Object? json) => map == null || json == null ? null : map(json as Map<String, dynamic>);
    final response = method == 'PUT'
        ? await _client.put(path, body: body, authenticated: true, fromJson: parse)
        : await _client.post(path, body: body, authenticated: true, fromJson: parse);
    if (!response.success) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data as T;
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String? _blank(String value) => value.trim().isEmpty ? null : value;
