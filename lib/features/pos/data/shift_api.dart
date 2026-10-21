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

  bool get isOpen => status == 'Open';
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
