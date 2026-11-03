import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';

/// A room on the board: vacant, occupied (guest and bill) or out of service.
class RoomBoardItem {
  const RoomBoardItem({
    required this.roomId,
    required this.number,
    required this.status,
    required this.chargeCount,
    required this.balance,
    this.name,
    this.stayId,
    this.guestName,
    this.guestPhone,
    this.checkedInAt,
  });

  factory RoomBoardItem.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    String? opt(String key) => r.string(key).isEmpty ? null : r.string(key);
    return RoomBoardItem(
      roomId: r.string('roomId'),
      number: r.string('number'),
      name: opt('name'),
      status: r.string('status'),
      stayId: opt('stayId'),
      guestName: opt('guestName'),
      guestPhone: opt('guestPhone'),
      checkedInAt: r.dateTime('checkedInAt'),
      chargeCount: r.integer('chargeCount'),
      balance: r.number('balance'),
    );
  }

  final String roomId;
  final String number;
  final String? name;
  final String status;
  final String? stayId;
  final String? guestName;
  final String? guestPhone;
  final DateTime? checkedInAt;
  final int chargeCount;
  final double balance;

  bool get isOccupied => status == 'Occupied';

  bool get isVacant => status == 'Vacant';
}

/// One sale on a guest's bill.
class StayCharge {
  const StayCharge({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.remaining,
    this.createdAt,
    this.customerName,
    this.customerId,
  });

  final String orderId;
  final String orderNumber;
  final double amount;
  final double remaining;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerId;
}

/// A guest's stay with its bill.
class StayInfo {
  const StayInfo({
    required this.id,
    required this.roomNumber,
    required this.guestName,
    required this.status,
    required this.total,
    required this.paid,
    required this.balance,
    required this.charges,
    this.guestPhone,
    this.leftOnAccount = false,
  });

  factory StayInfo.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    return StayInfo(
      id: r.string('id'),
      roomNumber: r.string('roomNumber'),
      guestName: r.string('guestName'),
      guestPhone: r.string('guestPhone').isEmpty ? null : r.string('guestPhone'),
      status: r.string('status'),
      leftOnAccount: r.boolean('leftOnAccount'),
      total: r.number('total'),
      paid: r.number('paid'),
      balance: r.number('balance'),
      charges: r.listOfMaps('charges').map((c) {
        final o = JsonReader(c);
        return StayCharge(
          orderId: o.string('id'),
          orderNumber: o.string('orderNumber'),
          amount: c.containsKey('netPayableAmount') ? o.number('netPayableAmount') : o.number('totalAmount'),
          remaining: o.number('remainingAmount'),
          createdAt: o.dateTime('createdAt'),
          customerName: o.string('customerName').isEmpty ? null : o.string('customerName'),
          customerId: o.string('customerId').isEmpty ? null : o.string('customerId'),
        );
      }).toList(),
    );
  }

  final String id;
  final String roomNumber;
  final String guestName;
  final String? guestPhone;
  final String status;
  final bool leftOnAccount;
  final double total;
  final double paid;
  final double balance;
  final List<StayCharge> charges;

  bool get isOpen => status == 'Open';

  List<StayCharge> get openCharges => charges.where((c) => c.remaining > 0).toList();
}

/// Hotel rooms (Rooms module): the room board, check-in and check-out.
class RoomsApi {
  RoomsApi(this._client);

  final MposApiClient _client;

  Future<List<RoomBoardItem>> board(String branchId) => _get(
    '/branches/$branchId/room-board',
    (json) => (json as List).cast<Map<String, dynamic>>().map(RoomBoardItem.fromJson).toList(),
  );

  Future<StayInfo> stay(String stayId) =>
      _get('/stays/$stayId', (json) => StayInfo.fromJson(json as Map<String, dynamic>));

  Future<StayInfo> checkIn({
    required String branchId,
    required String roomId,
    required String guestName,
    String? guestPhone,
  }) => _post('/branches/$branchId/stays', {
    'roomId': roomId,
    'guestName': guestName,
    'guestPhone': ?guestPhone,
  }, (json) => StayInfo.fromJson(json as Map<String, dynamic>));

  /// Check-out: with [receivedCash] every open charge is paid in cash; without it the stay closes
  /// when nothing is left to pay (charges paid by Telebirr/Chapa first), or [leaveOnAccount].
  /// Returns the change to give back.
  Future<double> checkOut(String stayId, {double? receivedCash, String? customerPhone, bool leaveOnAccount = false}) =>
      _post('/stays/$stayId/checkout', {
        'receivedCash': ?receivedCash,
        'customerPhone': ?customerPhone,
        'leaveOnAccount': leaveOnAccount,
      }, (json) => JsonReader(json as Map<String, dynamic>).number('change'));

  Future<T> _get<T>(String path, T Function(Object? json) map) async {
    final response = await _client.get(path, authenticated: true, fromJson: map);
    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data as T;
  }

  Future<T> _post<T>(String path, Map<String, dynamic> body, T Function(Object? json) map) async {
    final response = await _client.post(path, body: body, authenticated: true, fromJson: map);
    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data as T;
  }
}
