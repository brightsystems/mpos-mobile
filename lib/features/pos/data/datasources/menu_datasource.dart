import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';

abstract class MenuDatasource {
  Future<List<MenuItemEntity>> syncBranchMenu({required String branchId, DateTime? since});
}
