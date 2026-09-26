import '../core/utils/formatters.dart';

/// Matches backend CartService `CartItem`.
class CartItem {
  const CartItem({
    required this.productId,
    required this.quantity,
    this.id,
    this.productName,
    this.productImage,
    this.price,
    this.priceAtAddTime,
  });

  final String? id;
  final String productId;
  final int quantity;
  final String? productName;
  final String? productImage;
  final double? price;
  final double? priceAtAddTime;

  double get unitPrice => price ?? priceAtAddTime ?? 0;
  double get lineTotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id']?.toString(),
        productId: '${j['productId'] ?? ''}',
        quantity: toInt(j['quantity']) ?? 1,
        productName: j['productName'] as String?,
        productImage: j['productImage'] as String?,
        price: toDouble(j['price']),
        priceAtAddTime: toDouble(j['priceAtAddTime']),
      );
}

/// Matches backend `CartSummary`. For a brand-new cart every field except
/// currency is null, so [Cart.effectiveSummary] recomputes it locally with the
/// same formula as CartService.calculateSummary (GST 18%).
class CartSummary {
  const CartSummary({
    this.subTotal,
    this.discount,
    this.deliveryFee,
    this.tax,
    this.totalAmount,
    this.currency = 'INR',
  });

  final double? subTotal;
  final double? discount;
  final double? deliveryFee;
  final double? tax;
  final double? totalAmount;
  final String currency;

  bool get isEmpty => subTotal == null && totalAmount == null;

  factory CartSummary.fromJson(Map<String, dynamic>? j) => j == null
      ? const CartSummary()
      : CartSummary(
          subTotal: toDouble(j['subTotal']),
          discount: toDouble(j['discount']),
          deliveryFee: toDouble(j['deliveryFee']),
          tax: toDouble(j['tax']),
          totalAmount: toDouble(j['totalAmount']),
          currency: (j['currency'] as String?) ?? 'INR',
        );
}

/// Matches backend `Cart {id, userId, items, summary, updatedAt}`.
class Cart {
  const Cart({this.id, this.userId, this.items = const [], this.summary = const CartSummary()});

  final String? id;
  final int? userId;
  final List<CartItem> items;
  final CartSummary summary;

  bool get isEmpty => items.isEmpty;

  /// Total number of units (backend GET /cart/count does the same sum).
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  bool contains(String productId) => items.any((i) => i.productId == productId);

  CartSummary get effectiveSummary {
    if (!summary.isEmpty) return summary;
    final sub = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final tax = sub * 0.18;
    return CartSummary(subTotal: sub, discount: 0, deliveryFee: 0, tax: tax, totalAmount: sub + tax);
  }

  factory Cart.fromJson(dynamic json) {
    final j = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    return Cart(
      id: j['id']?.toString(),
      userId: toInt(j['userId']),
      items: (j['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      summary: CartSummary.fromJson(j['summary'] is Map ? Map<String, dynamic>.from(j['summary']) : null),
    );
  }
}
