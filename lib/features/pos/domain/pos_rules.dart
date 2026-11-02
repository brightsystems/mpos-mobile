import 'package:mpos_mobile/features/pos/domain/entities/business_type_pos.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/pos_client.dart';

/// Selling rules that follow from the business type's POS block.
abstract final class PosRules {
  /// The product a scanned or typed code belongs to (barcode or SKU), or null.
  static MenuItemEntity? findByCode(List<MenuItemEntity> items, String code) {
    for (final item in items) {
      if (item.matchesCode(code)) {
        return item;
      }
    }
    return null;
  }

  /// Clinics and consultancies pick the patient/client before the first item.
  static bool needsClient(BusinessTypePos pos, PosClient? client) => pos.clientRequired && !(client?.hasName ?? false);

  /// A prescription-only product asks for the prescription number once per sale.
  static bool needsPrescription(BusinessTypePos pos, MenuItemEntity item, PosClient? client) =>
      pos.askPrescriptionForRx && item.isPrescriptionOnly && !(client?.hasReference ?? false);

  /// Hotel sales with a room go on the room's bill.
  static bool canChargeToRoom(BusinessTypePos pos, PosClient? client) =>
      pos.chargeToRoom && (client?.hasReference ?? false);

  /// Quick cash buttons: the exact amount, then the next round 50, 100, 500 and 1000 above it.
  static List<double> quickCashAmounts(double due) {
    if (due <= 0) {
      return const [];
    }

    final amounts = <double>[due];
    for (final step in const [50, 100, 500, 1000]) {
      final next = (due / step).ceil() * step.toDouble();
      final rounded = next <= due + 0.004 ? next + step : next;
      if (!amounts.any((a) => (a - rounded).abs() < 0.005)) {
        amounts.add(rounded);
      }
    }
    return amounts;
  }
}
