import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/pos/data/datasources/menu_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';

class FakeMenuDatasource implements MenuDatasource {
  @override
  Future<List<MenuItemEntity>> syncBranchMenu({required String branchId, DateTime? since}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (since == null) {
      return List<MenuItemEntity>.from(MockFixtures.menuItems);
    }

    return MockFixtures.menuItems.where((item) {
      final updatedAt = item.updatedAt;

      return updatedAt == null || !updatedAt.isBefore(since);
    }).toList();
  }
}
