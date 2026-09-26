import '../core/utils/formatters.dart';

/// A product in a list. Matches backend `ProductsDto`
/// (id, brand, name, image, price, originalPrice, storeId, categoryPath).
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    this.brand,
    this.image,
    this.price,
    this.originalPrice,
    this.categoryPath = const [],
  });

  final String id;
  final String name;
  final String? brand;
  final String? image;
  final double? price;
  final double? originalPrice;
  final List<String> categoryPath;

  int get discount => discountPercent(price, originalPrice);

  factory ProductSummary.fromJson(Map<String, dynamic> j) {
    final images = j['images'];
    return ProductSummary(
      id: '${j['id'] ?? ''}',
      name: (j['name'] as String?)?.trim().isNotEmpty == true ? j['name'] as String : 'Unnamed product',
      brand: j['brand'] as String?,
      image: (j['image'] as String?) ??
          (images is List && images.isNotEmpty ? images.first?.toString() : null),
      price: toDouble(j['price']),
      originalPrice: toDouble(j['originalPrice']),
      categoryPath: (j['categoryPath'] as List?)?.map((e) => '$e').toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'image': image,
        'price': price,
        'originalPrice': originalPrice,
        'categoryPath': categoryPath,
      };
}

/// Full product. Matches the backend `Product` document returned by
/// `GET /products/{productId}`.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    this.images = const [],
    this.color,
    this.price,
    this.originalPrice,
    this.quantity,
    this.returnDay,
    this.averageRating,
    this.totalReviews,
    this.freeShipping,
    this.deliveryDays,
    this.categoryPath = const [],
    this.sellerId,
    this.shopId,
    this.specifications = const {},
  });

  final String id;
  final String name;
  final String? brand;
  final String? description;
  final List<String> images;
  final String? color;
  final double? price;
  final double? originalPrice;
  final int? quantity;
  final int? returnDay;
  final double? averageRating;
  final int? totalReviews;
  final bool? freeShipping;
  final int? deliveryDays;
  final List<String> categoryPath;
  final int? sellerId;
  final int? shopId;
  final Map<String, dynamic> specifications;

  int get discount => discountPercent(price, originalPrice);

  /// Website rule: buttons are disabled unless quantity > 0.
  bool get inStock => (quantity ?? 0) > 0;

  String? get primaryImage => images.isNotEmpty ? images.first : null;

  factory ProductDetail.fromJson(Map<String, dynamic> j) {
    final specs = j['specifications'];
    return ProductDetail(
      id: '${j['id'] ?? ''}',
      name: (j['name'] as String?) ?? 'Unnamed product',
      brand: j['brand'] as String?,
      description: j['description'] as String?,
      images: (j['images'] as List?)?.where((e) => e != null).map((e) => '$e').toList() ?? const [],
      color: j['color'] as String?,
      price: toDouble(j['price']),
      originalPrice: toDouble(j['originalPrice']),
      quantity: toInt(j['quantity']),
      returnDay: toInt(j['returnDay']),
      averageRating: toDouble(j['averageRating']),
      totalReviews: toInt(j['totalReviews']),
      freeShipping: j['freeShipping'] as bool?,
      deliveryDays: toInt(j['deliveryDays']),
      categoryPath: (j['categoryPath'] as List?)?.map((e) => '$e').toList() ?? const [],
      sellerId: toInt(j['sellerId']),
      shopId: toInt(j['shopId']),
      specifications: specs is Map ? Map<String, dynamic>.from(specs) : const {},
    );
  }

  ProductSummary toSummary() => ProductSummary(
        id: id,
        name: name,
        brand: brand,
        image: primaryImage,
        price: price,
        originalPrice: originalPrice,
        categoryPath: categoryPath,
      );
}
