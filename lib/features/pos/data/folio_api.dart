import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';

/// A hotel room's open bill: the sales charged to the room, settled at check-out.
class FolioInfo {
  const FolioInfo({
    required this.room,
    required this.orderCount,
    required this.total,
    required this.paid,
    required this.balance,
    required this.lines,
    this.guestName,
    this.guestPhone,
    this.openedAt,
  });

  factory FolioInfo.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    final lines = <({String name, double quantity, double amount})>[];
    for (final order in r.listOfMaps('orders')) {
      for (final line in JsonReader(order).listOfMaps('lines')) {
        final l = JsonReader(line);
        final remaining = l.number('quantity') - l.number('paidQuantity');
        if (remaining > 0) {
          lines.add((name: l.string('name'), quantity: remaining, amount: l.number('lineTotal')));
        }
      }
    }

    return FolioInfo(
      room: r.string('room'),
      guestName: r.string('guestName').isEmpty ? null : r.string('guestName'),
      guestPhone: r.string('guestPhone').isEmpty ? null : r.string('guestPhone'),
      orderCount: r.integer('orderCount'),
      total: r.number('total'),
      paid: r.number('paid'),
      balance: r.number('balance'),
      openedAt: r.dateTime('openedAt'),
      lines: lines,
    );
  }

  final String room;
  final String? guestName;
  final String? guestPhone;
  final int orderCount;
  final double total;
  final double paid;
  final double balance;
  final DateTime? openedAt;
  final List<({String name, double quantity, double amount})> lines;
}

/// Room bills of a branch: list them, and settle one in cash at check-out.
class FolioApi {
  FolioApi(this._client);

  final MposApiClient _client;

  Future<List<FolioInfo>> list(String branchId) async {
    final response = await _client.get(
      '/branches/$branchId/folios',
      authenticated: true,
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>().map(FolioInfo.fromJson).toList(),
    );
    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data!;
  }

  /// Pays every open order of the room; returns the change to give back.
  Future<double> settle({
    required String branchId,
    required String room,
    required double receivedAmount,
    String? customerPhone,
  }) async {
    final response = await _client.post(
      '/branches/$branchId/folios/settle',
      authenticated: true,
      body: {'room': room, 'receivedAmount': receivedAmount, 'customerPhone': ?customerPhone},
      fromJson: (json) => JsonReader(json as Map<String, dynamic>).number('change'),
    );
    if (!response.success) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data ?? 0;
  }
}
