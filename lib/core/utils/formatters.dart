import 'package:intl/intl.dart';

final NumberFormat _whole = NumberFormat('#,##,##0', 'en_IN');
final NumberFormat _decimal = NumberFormat('#,##,##0.00', 'en_IN');

/// ₹1,09,999 style prices (Indian digit grouping, like the website).
String formatPrice(num? value, {bool forceDecimals = false}) {
  if (value == null) return '₹ --';
  final isWhole = value == value.roundToDouble();
  return '₹${(isWhole && !forceDecimals) ? _whole.format(value) : _decimal.format(value)}';
}

/// Same formula as the website ProductCard: (original - price) / original.
int discountPercent(num? price, num? originalPrice) {
  if (price == null || originalPrice == null || originalPrice <= 0) return 0;
  if (originalPrice <= price) return 0;
  return (((originalPrice - price) / originalPrice) * 100).round();
}

/// Backend BigDecimal/Double values can arrive as numbers or strings.
double? toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String initialsOf(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "home-and-living" → "Home And Living"
String prettyCategory(String s) =>
    s.split(RegExp(r'[-_\s]+')).where((p) => p.isNotEmpty).map(capitalize).join(' ');
