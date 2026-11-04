import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/customer_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/checkout_dialogs.dart';

/// Records the events the checkout sends; nothing else of the POS bloc is used.
class _FakePosBloc extends Bloc<PosEvent, PosState> implements PosBloc {
  _FakePosBloc() : super(const PosState(enableCash: true, enableChapa: false, enableTelebirr: true)) {
    on<PosEvent>((event, emit) => events.add(event));
  }

  final events = <PosEvent>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrders implements OrderRepository {
  @override
  Future<Result<List<CustomerEntity>>> searchCustomers(String query) async => Result.success(
    data: const [
      CustomerEntity(
        id: 'c1',
        type: 'Business',
        transactionType: 'B2B',
        legalName: 'Taxpayer H',
        tin: '0004404844',
        phone: '+251911000099',
        email: 'buyer@example.com',
        isWithholdingAgent: true,
      ),
      CustomerEntity(
        id: 'c2',
        type: 'Business',
        transactionType: 'B2B',
        legalName: 'No Contact PLC',
        tin: '0011223344',
      ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OrderEntity _submitted({double withholding = 30}) => OrderEntity(
  id: 'o1',
  branchId: 'b1',
  orderNumber: 'ORD-1',
  status: 'Submitted',
  subtotal: 1000,
  taxAmount: 150,
  totalAmount: 1150,
  lines: const [],
  payments: const [],
  withholdingAmount: withholding,
  remainingAmount: 1150,
  customerPhone: '0911000001',
);

Future<_FakePosBloc> _open(WidgetTester tester, OrderEntity order) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);

  final bloc = _FakePosBloc();
  await tester.pumpWidget(
    BlocProvider<PosBloc>.value(
      value: bloc,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => startCheckout(context, order), child: const Text('open')),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  setUp(() {
    if (getIt.isRegistered<OrderRepository>()) getIt.unregister<OrderRepository>();
    getIt.registerSingleton<OrderRepository>(_FakeOrders());
  });

  tearDown(() => getIt.unregister<OrderRepository>());

  testWidgets('as on the web: the buyer withholds by default and pays the balance less the withholding', (
    tester,
  ) async {
    final bloc = await _open(tester, _submitted());

    expect(find.text('Walking customer'), findsOneWidget);
    expect(find.text('Buyer withholds tax (−${_money(30)})'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
    expect(find.text('Withholding (kept by buyer)'), findsOneWidget);
    expect(find.text('Customer pays'), findsOneWidget);
    expect(find.text('Validate payment · ${_money(1120)}'), findsOneWidget);

    await tester.tap(find.text('Validate payment · ${_money(1120)}'));
    await tester.pumpAndSettle();

    final pay = bloc.events.whereType<PosCheckoutRequested>().single;
    expect(pay.withholdTax, isTrue);
    expect(pay.amount, isNull);
    expect(pay.receivedAmount, 1120);
    expect(pay.paymentMethod, 'cash');
  });

  testWidgets('unchecking withholding: the buyer pays the full amount', (tester) async {
    final bloc = await _open(tester, _submitted());

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(find.text('Customer pays'), findsNothing);

    await tester.tap(find.text('Validate payment · ${_money(1150)}'));
    await tester.pumpAndSettle();
    final pay = bloc.events.whereType<PosCheckoutRequested>().single;
    expect(pay.withholdTax, isFalse);
    expect(pay.receivedAmount, 1150);
  });

  testWidgets('choosing customers fills every field from the chosen one; walking customer clears them', (tester) async {
    await _open(tester, _submitted(withholding: 0));

    Future<void> choose(String label) async {
      await tester.tap(find.byKey(const ValueKey('customer-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    String field(String hint) => tester.widget<TextField>(find.widgetWithText(TextField, hint)).controller!.text;

    await choose('Taxpayer H');
    expect(find.text('Taxpayer H · B2B'), findsOneWidget);
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).map((t) => t.controller!.text),
      containsAll(['+251911000099', 'buyer@example.com', 'Taxpayer H', '0004404844']),
    );

    // A customer without phone or email: nothing kept from the previous one.
    await choose('No Contact PLC');
    final texts = tester.widgetList<TextField>(find.byType(TextField)).map((t) => t.controller!.text).toList();
    expect(texts, isNot(contains('+251911000099')));
    expect(texts, isNot(contains('buyer@example.com')));
    expect(texts, contains('0011223344'));

    // Back to the walking customer: the fields are cleared.
    await tester.tap(find.byTooltip('Back to walking customer'));
    await tester.pumpAndSettle();
    expect(find.text('Walking customer'), findsOneWidget);
    expect(field('Phone (required to pay)'), isEmpty);
  });
}

String _money(double amount) => CurrencyFormatter.format(amount);
