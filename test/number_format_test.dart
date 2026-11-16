import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/core/number_format.dart';

void main() {
  group('GameNumberFormat specifications (AGENTS.md 5.3)', () {
    test('money below 10 shows 1 decimal', () {
      expect(GameNumberFormat.format(0.0), '0.0');
      expect(GameNumberFormat.format(0.5), '0.5');
      expect(GameNumberFormat.format(5.0), '5.0');
      expect(GameNumberFormat.format(9.9), '9.9');
    });

    test('money below 1000 (10 to 999) shows no decimals', () {
      expect(GameNumberFormat.format(10.0), '10');
      expect(GameNumberFormat.format(120.0), '120');
      expect(GameNumberFormat.format(999.0), '999');
    });

    test('AGENTS.md specific examples', () {
      expect(GameNumberFormat.format(999.0), '999');
      expect(GameNumberFormat.format(1234.0), '1.23K');
      expect(GameNumberFormat.format(1.5e6), '1.50M');
      expect(GameNumberFormat.format(12.3e9), '12.3B');
    });

    test('3 significant figures scaling', () {
      expect(GameNumberFormat.format(1000.0), '1.00K');
      expect(GameNumberFormat.format(12340.0), '12.3K');
      expect(GameNumberFormat.format(123400.0), '123K');
    });

    test('Suffix order K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc', () {
      expect(GameNumberFormat.format(1e3), '1.00K');
      expect(GameNumberFormat.format(1e6), '1.00M');
      expect(GameNumberFormat.format(1e9), '1.00B');
      expect(GameNumberFormat.format(1e12), '1.00T');
      expect(GameNumberFormat.format(1e15), '1.00Qa');
      expect(GameNumberFormat.format(1e18), '1.00Qi');
      expect(GameNumberFormat.format(1e21), '1.00Sx');
      expect(GameNumberFormat.format(1e24), '1.00Sp');
      expect(GameNumberFormat.format(1e27), '1.00Oc');
      expect(GameNumberFormat.format(1e30), '1.00No');
      expect(GameNumberFormat.format(1e33), '1.00Dc');
    });

    test('Above Dc uses scientific notation', () {
      final formatted = GameNumberFormat.format(1.23e36);
      expect(formatted, contains('e+36'));
    });

    test('Edge cases: NaN and Infinity', () {
      expect(GameNumberFormat.format(double.nan), '0.0');
      expect(GameNumberFormat.format(double.infinity), '0.0');
      expect(GameNumberFormat.format(-50.0), '0.0');
    });
  });
}
