import 'package:intl/intl.dart';

final _gbpFormat = NumberFormat.currency(locale: 'en_GB', symbol: '\u00A3');

String formatGBP(double amount) => _gbpFormat.format(amount);

String formatGBPCompact(double amount) {
  if (amount == 0) return '';
  return _gbpFormat.format(amount);
}
