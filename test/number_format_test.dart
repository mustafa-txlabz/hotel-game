import 'package:flutter_test/flutter_test.dart';
import 'package:chai_dhaba_empire/core/number_format.dart';

void main() {
  group('GameNumberFormat Basic Tests', () {
    test('formats values under 10 with 1 decimal', () {
      expect(GameNumberFormat.format(5.0), '5.0');
    });

    test('formats values between 10 and 999 with no decimal', () {
      expect(GameNumberFormat.format(999.0), '999');
    });

    test('formats 1234 to 1.23K', () {
      expect(GameNumberFormat.format(1234.0), '1.23K');
    });
  });
}

