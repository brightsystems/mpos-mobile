import 'package:intl/intl.dart';

import 'package:mpos_mobile/core/locale/app_locale.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const int defaultDecimalDigits = 2;

  static String format(num data, {int? decimalDigits}) {
    return NumberFormat.currency(
      locale: AppLocale.formattingLocale.toString(),
      name: AppLocale.defaultCurrencyCode,
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
    ).format(data);
  }

  static String compact(num data, {int? decimalDigits, bool withSymbol = true}) {
    return NumberFormat.compactCurrency(
      locale: AppLocale.formattingLocale.toString(),
      name: withSymbol ? AppLocale.defaultCurrencyCode : '',
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
    ).format(data);
  }

  static String withoutSymbol(num data, {int? decimalDigits}) {
    return NumberFormat.currency(
      locale: AppLocale.formattingLocale.toString(),
      decimalDigits: decimalDigits ?? defaultDecimalDigits,
      symbol: '',
    ).format(data);
  }

  static String currencySymbol() {
    return AppLocale.defaultCurrencyCode;
  }
}
