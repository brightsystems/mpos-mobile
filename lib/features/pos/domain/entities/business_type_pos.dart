import 'package:equatable/equatable.dart';

/// How a business type sells on the POS (the profile's `pos` block).
class BusinessTypePos extends Equatable {
  const BusinessTypePos({
    this.layout = 'Grid',
    this.startWith = 'Menu',
    this.clientKind = 'Customer',
    this.clientRequired = false,
    this.scanFirst = false,
    this.chargeToRoom = false,
    this.askPrescriptionForRx = false,
    this.allowCreditSale = false,
    this.showAssignedStaff = false,
    this.quickCash = false,
  });

  /// Grid (pictures + add dialog) or List (compact rows, a tap adds one).
  final String layout;

  /// Menu, ServicePoint (tables/rooms) or Client (pick the client first).
  final String startWith;

  /// Customer, Guest, Patient or Client.
  final String clientKind;
  final bool clientRequired;
  final bool scanFirst;
  final bool chargeToRoom;
  final bool askPrescriptionForRx;
  final bool allowCreditSale;
  final bool showAssignedStaff;
  final bool quickCash;

  bool get isList => layout == 'List';

  bool get startsWithClient => startWith == 'Client';

  /// The POS block an older API (without one) would have sent for this business type.
  factory BusinessTypePos.defaultsFor(String code) {
    switch (code) {
      case 'Hotel':
        return const BusinessTypePos(startWith: 'ServicePoint', clientKind: 'Guest', chargeToRoom: true);
      case 'Cafeteria':
        return const BusinessTypePos(startWith: 'ServicePoint');
      case 'Shop':
      case 'Store':
        return const BusinessTypePos(layout: 'List', scanFirst: true, quickCash: true);
      case 'Manufacturer':
        // Cash and walk-in by default; credit and business buyers are offered, not forced.
        return const BusinessTypePos(layout: 'List', scanFirst: true, quickCash: true, allowCreditSale: true);
      case 'Pharmacy':
        return const BusinessTypePos(
          layout: 'List',
          clientKind: 'Patient',
          scanFirst: true,
          askPrescriptionForRx: true,
          quickCash: true,
        );
      case 'MedicalService':
        return const BusinessTypePos(
          layout: 'List',
          startWith: 'Client',
          clientKind: 'Patient',
          clientRequired: true,
          showAssignedStaff: true,
        );
      case 'ConsultancyService':
        return const BusinessTypePos(
          layout: 'List',
          startWith: 'Client',
          clientKind: 'Client',
          clientRequired: true,
          allowCreditSale: true,
        );
      default:
        return const BusinessTypePos();
    }
  }

  /// Reads the API's block; missing fields fall back to the type's defaults.
  factory BusinessTypePos.fromJson(Map<String, dynamic>? json, String code) {
    final defaults = BusinessTypePos.defaultsFor(code);
    if (json == null) {
      return defaults;
    }

    String text(String key, String fallback) {
      final value = json[key];
      return value is String && value.isNotEmpty ? value : fallback;
    }

    bool flag(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return BusinessTypePos(
      layout: text('layout', defaults.layout),
      startWith: text('startWith', defaults.startWith),
      clientKind: text('clientKind', defaults.clientKind),
      clientRequired: flag('clientRequired', defaults.clientRequired),
      scanFirst: flag('scanFirst', defaults.scanFirst),
      chargeToRoom: flag('chargeToRoom', defaults.chargeToRoom),
      askPrescriptionForRx: flag('askPrescriptionForRx', defaults.askPrescriptionForRx),
      allowCreditSale: flag('allowCreditSale', defaults.allowCreditSale),
      showAssignedStaff: flag('showAssignedStaff', defaults.showAssignedStaff),
      quickCash: flag('quickCash', defaults.quickCash),
    );
  }

  @override
  List<Object?> get props => [
    layout,
    startWith,
    clientKind,
    clientRequired,
    scanFirst,
    chargeToRoom,
    askPrescriptionForRx,
    allowCreditSale,
    showAssignedStaff,
    quickCash,
  ];
}
