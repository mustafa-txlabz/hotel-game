/// Number formatting utilities for game currency and income rates.
///
/// Follows AGENTS.md 5.3 rules:
/// - Below 10: 1 decimal place (e.g. 0.0, 5.5, 9.9)
/// - 10 to 999: no decimals (e.g. 10, 999)
/// - 1,000+: at most 3 significant digits plus suffix:
///   1234 -> 1.23K, 12340 -> 12.3K, 123400 -> 123K, 1.5e6 -> 1.50M, 12.3e9 -> 12.3B
/// - Suffix order: K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc.
/// - Above Dc (10^36): scientific style like 1.23e36.
class GameNumberFormat {
  static const List<String> suffixes = [
    '',
    'K', // 10^3
    'M', // 10^6
    'B', // 10^9
    'T', // 10^12
    'Qa', // 10^15
    'Qi', // 10^18
    'Sx', // 10^21
    'Sp', // 10^24
    'Oc', // 10^27
    'No', // 10^30
    'Dc', // 10^33
  ];

  static String format(double value) {
    if (value.isNaN || value.isInfinite) return '0.0';
    if (value <= 0) return '0.0';

    if (value < 10.0) {
      return value.toStringAsFixed(1);
    }

    if (value < 1000.0) {
      return value.floor().toString();
    }

    int tier = 0;
    double scaled = value;
    while (scaled >= 999.999999 && tier < suffixes.length - 1) {
      scaled /= 1000.0;
      tier++;
    }

    // If still >= 1000 after last suffix (Dc), fallback to scientific
    if (scaled >= 1000.0) {
      return value.toStringAsExponential(2);
    }

    final suffix = suffixes[tier];
    if (scaled >= 99.95) {
      return '${scaled.round()}$suffix';
    } else if (scaled >= 9.995) {
      return '${scaled.toStringAsFixed(1)}$suffix';
    } else {
      return '${scaled.toStringAsFixed(2)}$suffix';
    }
  }

  /// Formats rate of income per second, with "/s" suffix
  static String formatRate(double rate) {
    return '${format(rate)}/s';
  }
}
