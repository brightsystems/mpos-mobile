import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/pos_screen.dart';

void main() {
  group('Line discount input', () {
    test('a percentage is taken of the line value', () {
      expect(discountAmount('2%', 500), 10);
      expect(discountAmount(' 12.5 % ', 200), 25);
      expect(discountAmount('100%', 80), 80);
    });

    test('a plain number is the amount itself', () {
      expect(discountAmount('100', 500), 100);
      expect(discountAmount('7,5', 500), 7.5);
    });

    test('empty is no discount; too much or unreadable is refused', () {
      expect(discountAmount('', 500), 0);
      expect(discountAmount('600', 500), isNull);
      expect(discountAmount('150%', 500), isNull);
      expect(discountAmount('abc', 500), isNull);
      expect(discountAmount('-5', 500), isNull);
    });
  });
}
