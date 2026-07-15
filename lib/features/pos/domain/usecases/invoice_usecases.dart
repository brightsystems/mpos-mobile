import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/usecase/usecase.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/invoice_repository.dart';

class SubmitOrderInvoiceParams {
  const SubmitOrderInvoiceParams({required this.order});

  final OrderEntity order;
}

class SubmitOrderInvoiceUsecase extends Usecase<Result<FiscalInvoiceEntity>, SubmitOrderInvoiceParams> {
  SubmitOrderInvoiceUsecase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Result<FiscalInvoiceEntity>> call(SubmitOrderInvoiceParams params) {
    return _repository.submitForOrder(params.order);
  }
}

class PollOrderInvoiceParams {
  const PollOrderInvoiceParams(this.orderId);

  final String orderId;
}

class PollOrderInvoiceUsecase extends Usecase<Result<FiscalInvoiceEntity>, PollOrderInvoiceParams> {
  PollOrderInvoiceUsecase(this._repository);

  final InvoiceRepository _repository;

  @override
  Future<Result<FiscalInvoiceEntity>> call(PollOrderInvoiceParams params) {
    return _repository.pollForOrder(params.orderId);
  }
}
