import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/app/workspace_block_overlay.dart';
import 'package:mpos_mobile/core/network/workspace_block.dart';

void main() {
  final notifier = WorkspaceBlockNotifier.instance;

  setUp(notifier.clear);

  test('a 402 payment_required answer sets the block; a later success on a business call clears it', () {
    notifier.inspect(402, {'code': 'payment_required', 'message': 'Awaiting payment.'}, '/branches/b1/menu');
    expect(notifier.value?.code, 'payment_required');
    expect(notifier.value?.title, 'Subscription payment pending');

    // Sign-in calls succeed while blocked: they don't clear it.
    notifier.inspect(200, {'success': true}, '/auth/refresh');
    expect(notifier.value, isNotNull);

    notifier.inspect(200, {'success': true}, '/branches/b1/menu/categories');
    expect(notifier.value, isNull);
  });

  test('suspension is a block; other 403s are not', () {
    notifier.inspect(403, {'message': 'Your role is read-only.'}, '/orders');
    expect(notifier.value, isNull);

    notifier.inspect(403, {'code': 'workspace_suspended', 'message': 'Suspended.'}, '/orders');
    expect(notifier.value?.title, 'Business suspended');
  });

  testWidgets('the overlay covers the app while blocked and "Check again" asks the API', (tester) async {
    var checks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WorkspaceBlockOverlay(
          onCheckAgain: () async {
            checks++;
            notifier.inspect(200, {'success': true}, '/branches/b1/menu/categories');
          },
          child: const Scaffold(body: Text('POS')),
        ),
      ),
    );
    expect(find.text('Subscription payment pending'), findsNothing);

    notifier.inspect(402, {'code': 'payment_required', 'message': 'Awaiting payment.'}, '/orders');
    await tester.pump();
    expect(find.text('Subscription payment pending'), findsOneWidget);
    expect(find.text('Awaiting payment.'), findsOneWidget);

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(checks, 1);
    expect(find.text('Subscription payment pending'), findsNothing);
  });
}
