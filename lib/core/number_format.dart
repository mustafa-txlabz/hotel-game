/// Number formatting utilities for game currency and rates.
///
/// Formats large numbers with suffixes (K, M, B, etc.) and handles precision.
class GameNumberFormat {
  static const List<String> suffixes = [
    '',
    'K',
    'M',
    'B',
    'T',
    'Qa',
    'Qi',
    'Sx',
    'Sp',
    'Oc',
    'No',
    'Dc',
  ];

  /// Formats currency [value] into a compact readable string.
  static String format(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) return '0';
    if (value < 10) return value.toStringAsFixed(1);
    if (value < 1000) return value.floor().toString();

    // Suffix formatting
    int exp = 0;
    double n = value;
    while (n >= 1000.0 && exp < suffixes.length - 1) {
      n /= 1000.0;
      exp++;
    }

    if (exp < suffixes.length) {
      if (n >= 100) {
        return '${n.toStringAsFixed(0)}${suffixes[exp]}';
      } else if (n >= 10) {
        return '${n.toStringAsFixed(1)}${suffixes[exp]}';
      } else {
        return '${n.toStringAsFixed(2)}${suffixes[exp]}';
      }
    }

    return value.toStringAsExponential(2);
  }
}

