import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/pos/data/datasources/menu_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/menu_repository.dart';

class MenuRepositoryImpl implements MenuRepository {
  MenuRepositoryImpl({required MenuDatasource remoteDatasource, required SessionStorage sessionStorage})
    : _remoteDatasource = remoteDatasource,
      _sessionStorage = sessionStorage;

  final MenuDatasource _remoteDatasource;
  final SessionStorage _sessionStorage;

  @override
  Future<Result<List<MenuItemEntity>>> syncBranchMenu({DateTime? since}) async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final items = await _remoteDatasource.syncBranchMenu(branchId: session.branchId);

      return Result.success(data: items);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
