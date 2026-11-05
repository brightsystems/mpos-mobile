import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

TextField _field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField));

void main() {
  testWidgets('a password field starts hidden and the eye shows and hides it', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppTextField(labelText: 'Password', obscureText: true)),
      ),
    );

    expect(_field(tester).obscureText, isTrue);
    expect(find.byTooltip('Show password'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(_field(tester).obscureText, isFalse);
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(_field(tester).obscureText, isTrue);
  });

  testWidgets('a normal field has no eye', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppTextField(labelText: 'Phone')),
      ),
    );

    expect(_field(tester).obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });
}
