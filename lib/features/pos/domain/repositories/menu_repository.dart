import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';

abstract class MenuRepository {
  Future<Result<List<MenuItemEntity>>> syncBranchMenu({DateTime? since});
}
