import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/usecase/usecase.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/menu_repository.dart';

class SyncBranchMenuUsecase extends Usecase<Result<List<MenuItemEntity>>, NoParam> {
  SyncBranchMenuUsecase(this._repository);

  final MenuRepository _repository;

  @override
  Future<Result<List<MenuItemEntity>>> call(NoParam params) {
    return _repository.syncBranchMenu();
  }
}
