import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/pos/data/shift_api.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/shifts/my_shifts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real responses of the API (local, mock MoR) for shifts/mine/paged, orders/paged and documents.
final Map<String, dynamic> fixture = jsonDecode(File('test/features/pos/shifts/shift_fixture.json').readAsStringSync());

class FakeShiftApi extends ShiftApi {
  FakeShiftApi(SessionStorage storage)
    : super(
        MposApiClient(httpClient: MockClient((_) async => http.Response('{}', 404)), sessionStorage: storage),
        storage,
      );

  final shiftSearches = <String?>[];
  final orderSearches = <String?>[];
  final documentOrders = <String>[];

  @override
  Future<PageOf<ShiftInfo>> myShiftsPage({int page = 1, int pageSize = 20, String? search}) async {
    shiftSearches.add(search);
    return PageOf.fromJson(fixture['shifts'], ShiftInfo.fromJson);
  }

  @override
  Future<PageOf<ShiftOrderInfo>> shiftOrdersPage(
    String shiftId, {
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    orderSearches.add(search);
    return PageOf.fromJson(fixture['orders'], ShiftOrderInfo.fromJson);
  }

  @override
  Future<List<OrderDocumentInfo>> orderDocuments(String orderId) async {
    documentOrders.add(orderId);
    return (fixture['documents'] as List<dynamic>)
        .map((e) => OrderDocumentInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

void main() {
  test('reads a page of shifts from the API', () {
    final page = PageOf.fromJson(fixture['shifts'], ShiftInfo.fromJson);
    final shift = page.items.single;

    expect(shift.sessionNo, 'SES-33333333-0004');
    expect(shift.isOpen, isFalse);
    expect(shift.ordersCount, 39);
    expect(shift.salesTotal, 362123.5);
    expect(shift.cashDifference, -349091.5);
    expect(shift.closedAt, isNotNull);
    expect(page.totalCount, 1);
    expect(page.hasMore, isFalse);
  });

  test('reads shift orders and order documents from the API', () {
    final order = PageOf.fromJson(fixture['orders'], ShiftOrderInfo.fromJson).items.single;
    expect(order.orderNumber, 'ORD-33333333-0070');
    expect(order.invoiceNumber, '103');
    expect(order.invoiceVoided, isFalse);

    final documents = (fixture['documents'] as List<dynamic>)
        .map((e) => OrderDocumentInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    expect(documents.map((d) => d.label), ['Invoice', 'Receipt', 'Debit note', 'Credit note']);
    expect(documents.every((d) => d.downloadable), isTrue);
    expect(documents[1].paymentId, isNotNull);
    expect(documents[2].memoId, isNotNull);
  });

  test('a page knows when more rows are left', () {
    final page = PageOf.fromJson({'items': [], 'page': 1, 'pageSize': 20, 'totalCount': 45}, ShiftInfo.fromJson);
    expect(page.hasMore, isTrue);
  });

  group('screens', () {
    late FakeShiftApi api;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      api = FakeShiftApi(SessionStorage(await SharedPreferences.getInstance()));
      if (getIt.isRegistered<ShiftApi>()) getIt.unregister<ShiftApi>();
      getIt.registerSingleton<ShiftApi>(api);
    });

    tearDown(() => getIt.unregister<ShiftApi>());

    testWidgets('shifts -> search -> orders -> documents', (tester) async {
      // A tall phone, so the whole document list is built.
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: MyShiftsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SES-33333333-0004'), findsOneWidget);
      expect(find.textContaining('39 orders'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0004');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.shiftSearches.last, '0004');

      await tester.tap(find.text('SES-33333333-0004'));
      await tester.pumpAndSettle();
      expect(find.text('Orders · SES-33333333-0004'), findsOneWidget);
      expect(find.text('ORD-33333333-0070'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '0070');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(api.orderSearches.last, '0070');

      await tester.tap(find.text('ORD-33333333-0070'));
      await tester.pumpAndSettle();
      expect(find.text('Documents · ORD-33333333-0070'), findsOneWidget);
      for (final label in ['Invoice', 'Receipt', 'Debit note', 'Credit note']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNWidgets(4));
      expect(api.documentOrders.single, isNotEmpty);
    });
  });
}
