import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  static String currency(double amount) => _currencyFormat.format(amount);

  static String distance(double km) {
    if (km < 1.0) {
      final meters = (km * 1000).round();
      return '${meters}m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes mins';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  static String date(DateTime dateTime) => DateFormat('MMM dd, yyyy').format(dateTime);

  static String dateTime(DateTime dateTime) => DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
}
