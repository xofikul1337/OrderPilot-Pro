import 'dart:ui';

class CurrencyDisplay {
  const CurrencyDisplay._();

  static String get symbol =>
      symbolForCountry(PlatformDispatcher.instance.locale.countryCode);

  static String symbolForCountry(String? countryCode) =>
      countryCode?.toUpperCase() == 'BD' ? '৳' : r'$';

  static String format(String value) {
    final amount = value.trim();
    if (amount.isEmpty) return '-';
    return '$symbol$amount';
  }
}
