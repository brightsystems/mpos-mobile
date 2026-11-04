import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';

/// A cashier shift (POS session) on a register, as the web POS shows it.
class ShiftInfo {
  const ShiftInfo({
    required this.id,
    required this.sessionNo,
    required this.status,
    required this.openingCash,
    required this.openedAt,
    this.expectedCash,
    this.closingCash,
    this.sourceId,
    this.sourceName,
    this.openedByName,
    this.closedAt,
    this.ordersCount = 0,
    this.salesTotal = 0,
    this.cashDifference,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) => ShiftInfo(
    id: json['id'] as String,
    sessionNo: json['sessionNo'] as String? ?? '',
    status: json['status'] as String? ?? '',
    openingCash: (json['openingCash'] as num?)?.toDouble() ?? 0,
    expectedCash: (json['expectedCash'] as num?)?.toDouble(),
    closingCash: (json['closingCash'] as num?)?.toDouble(),
    openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    sourceId: json['sourceId'] as String?,
    sourceName: json['sourceName'] as String?,
    openedByName: json['openedByName'] as String?,
    closedAt: DateTime.tryParse(json['closedAt'] as String? ?? '')?.toLocal(),
    ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
    salesTotal: (json['salesTotal'] as num?)?.toDouble() ?? 0,
    cashDifference: (json['cashDifference'] as num?)?.toDouble(),
  );

  final String id;
  final String sessionNo;
  final String status;
  final double openingCash;
  final double? expectedCash;
  final double? closingCash;
  final DateTime openedAt;
  final String? sourceId;
  final String? sourceName;
  final String? openedByName;
  final DateTime? closedAt;
  final int ordersCount;

  /// What the shift collected (withholding included).
  final double salesTotal;

  /// Counted minus expected cash (closed shifts).
  final double? cashDifference;

  bool get isOpen => status == 'Open';
}

/// One page of a server-side list (page is 1-based).
class PageOf<T> {
  const PageOf({required this.items, required this.page, required this.pageSize, required this.totalCount});

  factory PageOf.fromJson(Object? json, T Function(Map<String, dynamic>) item) {
    final map = Map<String, dynamic>.from(json as Map);
    return PageOf(
      items: (map['items'] as List<dynamic>? ?? const [])
          .map((e) => item(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 10,
      totalCount: (map['totalCount'] as num?)?.toInt() ?? 0,
    );
  }

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  bool get hasMore => page * pageSize < totalCount;
}

/// An order taken or paid in a shift.
class ShiftOrderInfo {
  const ShiftOrderInfo({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.customerTin,
    this.paymentMethod,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.paymentMode = 'CASH',
    this.irn,
    this.salesReceiptRrn,
    this.invoiceNumber,
    this.invoiceVoided = false,
  });

  factory ShiftOrderInfo.fromJson(Map<String, dynamic> json) => ShiftOrderInfo(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String? ?? '',
    status: json['status'] as String? ?? '',
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    customerName: json['customerName'] as String?,
    customerPhone: json['customerPhone'] as String?,
    customerTin: json['customerTin'] as String?,
    paymentMethod: json['paymentMethod'] as String?,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
    paymentMode: json['paymentMode'] as String? ?? 'CASH',
    irn: json['irn'] as String?,
    salesReceiptRrn: json['salesReceiptRrn'] as String?,
    invoiceNumber: json['invoiceNumber'] as String?,
    invoiceVoided: json['invoiceVoided'] as bool? ?? false,
  );

  final String id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? customerTin;
  final String? paymentMethod;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMode;
  final String? irn;
  final String? salesReceiptRrn;
  final String? invoiceNumber;
  final bool invoiceVoided;
}

/// One fiscal document of an order: INVOICE, RECEIPT (one per payment), CREDIT_NOTE, DEBIT_NOTE or VOID.
class OrderDocumentInfo {
  const OrderDocumentInfo({
    required this.kind,
    required this.status,
    required this.downloadable,
    this.number,
    this.reference,
    this.issuedAt,
    this.amount,
    this.paymentId,
    this.memoId,
    this.note,
  });

  factory OrderDocumentInfo.fromJson(Map<String, dynamic> json) => OrderDocumentInfo(
    kind: json['kind'] as String? ?? '',
    status: json['status'] as String? ?? '',
    downloadable: json['downloadable'] as bool? ?? false,
    number: json['number'] as String?,
    reference: json['reference'] as String?,
    issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '')?.toLocal(),
    amount: (json['amount'] as num?)?.toDouble(),
    paymentId: json['paymentId'] as String?,
    memoId: json['memoId'] as String?,
    note: json['note'] as String?,
  );

  final String kind;
  final String status;
  final bool downloadable;
  final String? number;

  /// IRN (invoice, notes, void) or RRN (receipt).
  final String? reference;
  final DateTime? issuedAt;
  final double? amount;
  final String? paymentId;
  final String? memoId;
  final String? note;

  String get label => switch (kind) {
    'INVOICE' => 'Invoice',
    'RECEIPT' => 'Receipt',
    'CREDIT_NOTE' => 'Credit note',
    'DEBIT_NOTE' => 'Debit note',
    'VOID' => 'Void',
    _ => kind,
  };
}

/// A register (MoR source) the branch can sell on.
class RegisterInfo {
  const RegisterInfo({required this.id, required this.name});

  final String id;
  final String name;
}

/// The MoR token session of a register.
class MorSessionInfo {
  const MorSessionInfo({required this.connected, this.tin, this.sourceId, this.sourceName, this.error});

  factory MorSessionInfo.fromJson(Map<String, dynamic> json) => MorSessionInfo(
    connected: json['connected'] as bool? ?? false,
    tin: json['tin'] as String?,
    sourceId: json['sourceId'] as String?,
    sourceName: json['sourceName'] as String?,
    error: json['error'] as String?,
  );

  final bool connected;
  final String? tin;
  final String? sourceId;
  final String? sourceName;
  final String? error;
}

/// Shifts and the MoR session, the same API calls as the web POS: a cashier sells only inside an
/// open shift with a live MoR session on the shift's register.
class ShiftApi {
  ShiftApi(this._client, this._sessionStorage);

  final MposApiClient _client;
  final SessionStorage _sessionStorage;

  Future<String> _branchId() async => (await _sessionStorage.loadSession())?.branchId ?? '';

  /// The signed-in cashier's shifts on the branch, newest first.
  Future<List<ShiftInfo>> myShifts() async {
    final branchId = await _branchId();
    return _list(await _client.get('/branches/$branchId/pos-sessions/mine', authenticated: true, fromJson: _shifts));
  }

  /// The cashier's shifts on the branch, one page at a time (search: number, register, note, open/closed).
  Future<PageOf<ShiftInfo>> myShiftsPage({int page = 1, int pageSize = 20, String? search}) async {
    final branchId = await _branchId();
    return _one(
      await _client.get(
        '/branches/$branchId/pos-sessions/mine/paged?${_pageQuery(page, pageSize, search)}',
        authenticated: true,
        fromJson: (json) => PageOf.fromJson(json, ShiftInfo.fromJson),
      ),
    );
  }

  /// A shift's orders, one page at a time (search: order, buyer, phone, TIN, invoice number).
  Future<PageOf<ShiftOrderInfo>> shiftOrdersPage(
    String shiftId, {
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async => _one(
    await _client.get(
      '/pos-sessions/$shiftId/orders/paged?${_pageQuery(page, pageSize, search)}',
      authenticated: true,
      fromJson: (json) => PageOf.fromJson(json, ShiftOrderInfo.fromJson),
    ),
  );

  /// The order's fiscal documents: invoice, a receipt per payment, credit/debit notes and the void.
  Future<List<OrderDocumentInfo>> orderDocuments(String orderId) async => _list(
    await _client.get(
      '/orders/$orderId/documents',
      authenticated: true,
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => OrderDocumentInfo.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    ),
  );

  static String _pageQuery(int page, int pageSize, String? search) => Uri(
    queryParameters: {
      'page': '$page',
      'pageSize': '$pageSize',
      if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
    },
  ).query;

  /// Every open shift at the branch (owners, admins, branch managers).
  Future<List<ShiftInfo>> branchOpenShifts() async {
    final branchId = await _branchId();
    return _list(await _client.get('/branches/$branchId/pos-sessions/open', authenticated: true, fromJson: _shifts));
  }

  Future<ShiftInfo> openShift({required double openingCash, String? sourceId}) async {
    final branchId = await _branchId();
    return _one(
      await _client.post(
        '/branches/$branchId/pos-sessions',
        authenticated: true,
        body: {'openingCash': openingCash, if (sourceId != null) 'sourceId': sourceId},
        fromJson: (json) => ShiftInfo.fromJson(Map<String, dynamic>.from(json as Map)),
      ),
    );
  }

  Future<ShiftInfo> closeShift(String shiftId, {required double closingCash}) async => _one(
    await _client.post(
      '/pos-sessions/$shiftId/close',
      authenticated: true,
      body: {'closingCash': closingCash},
      fromJson: (json) => ShiftInfo.fromJson(Map<String, dynamic>.from(json as Map)),
    ),
  );

  /// Closes a shift without a cash count; the reason is recorded (managers).
  Future<ShiftInfo> forceCloseShift(String shiftId, {required String reason}) async => _one(
    await _client.post(
      '/pos-sessions/$shiftId/force-close',
      authenticated: true,
      body: {'reason': reason},
      fromJson: (json) => ShiftInfo.fromJson(Map<String, dynamic>.from(json as Map)),
    ),
  );

  /// The branch's registers (its assigned ones, else the business's active ones).
  Future<List<RegisterInfo>> registers() async {
    final branchId = await _branchId();
    return _list(
      await _client.get(
        '/branches/$branchId/sources',
        authenticated: true,
        fromJson: (json) => (json as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((item) => item['isActive'] != false)
            .map((item) => RegisterInfo(id: item['id'] as String, name: item['name'] as String? ?? 'Register'))
            .toList(),
      ),
    );
  }

  /// MoR session of a register (without one: the shift's register, else the branch default).
  Future<MorSessionInfo> morSession({String? sourceId}) async {
    final branchId = await _branchId();
    return _one(
      await _client.get('/branches/$branchId/mor-session${_source(sourceId)}', authenticated: true, fromJson: _mor),
    );
  }

  Future<MorSessionInfo> connectMor({String? sourceId}) async {
    final branchId = await _branchId();
    return _one(
      await _client.post(
        '/branches/$branchId/mor-session/login${_source(sourceId)}',
        authenticated: true,
        fromJson: _mor,
      ),
    );
  }

  static String _source(String? sourceId) => sourceId == null ? '' : '?sourceId=${Uri.encodeComponent(sourceId)}';

  static List<ShiftInfo> _shifts(Object? json) =>
      (json as List<dynamic>).map((item) => ShiftInfo.fromJson(Map<String, dynamic>.from(item as Map))).toList();

  static MorSessionInfo _mor(Object? json) => MorSessionInfo.fromJson(Map<String, dynamic>.from(json as Map));

  static T _one<T>(ApiResponse<T> response) {
    if (!response.success || response.data == null) {
      throw response.errors.isNotEmpty ? response.errors.first : (response.message ?? 'Request failed.');
    }
    return response.data as T;
  }

  static List<T> _list<T>(ApiResponse<List<T>> response) {
    if (!response.success) {
      throw response.errors.isNotEmpty ? response.errors.first : (response.message ?? 'Request failed.');
    }
    return response.data ?? <T>[];
  }
}
