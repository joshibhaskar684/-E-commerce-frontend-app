import '../config/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/utils/formatters.dart';
import '../models/cart.dart';

/// CartService endpoints (backend CartController, @RequestMapping("/cart")).
///
/// Website counterpart: `src/redux-store/cart/action.js` (GetCartRequest uses
/// GET /cart with the Bearer token). Every call here needs the user to be
/// logged in; the token is attached automatically by [ApiClient].
class CartService {
  CartService({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// GET /cart
  Future<Cart> getCart() async => Cart.fromJson(await _api.get(ApiEndpoints.cart));

  /// POST /cart/item/add  {productId, quantity, productName, productImage, price}
  Future<Cart> addItem({
    required String productId,
    required int quantity,
    required String productName,
    String? productImage,
    double? price,
  }) async {
    final data = await _api.post(ApiEndpoints.cartAddItem, data: {
      'productId': productId,
      'quantity': quantity,
      'productName': productName,
      'productImage': productImage,
      'price': price,
    });
    return Cart.fromJson(data);
  }

  /// PUT /cart/item  {productId, quantity}
  Future<Cart> updateQuantity({required String productId, required int quantity}) async {
    final data = await _api.put(ApiEndpoints.cartItem, data: {'productId': productId, 'quantity': quantity});
    return Cart.fromJson(data);
  }

  /// DELETE /cart/item/{productId}
  Future<Cart> removeItem(String productId) async =>
      Cart.fromJson(await _api.delete(ApiEndpoints.cartRemoveItem(productId)));

  /// DELETE /cart/clear
  Future<Cart> clearCart() async => Cart.fromJson(await _api.delete(ApiEndpoints.cartClear));

  /// GET /cart/count
  Future<int> getCount() async => toInt(await _api.get(ApiEndpoints.cartCount)) ?? 0;
}
