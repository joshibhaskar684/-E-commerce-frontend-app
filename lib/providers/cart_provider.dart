import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

/// Cart state backed by CartService (the website's CartReducer).
/// Reloads automatically when the user logs in and clears on logout.
class CartProvider extends ChangeNotifier {
  CartProvider({CartService? service}) : _service = service ?? CartService();

  final CartService _service;

  Cart? _cart;
  bool _loading = false;
  String? _error;
  bool _loggedIn = false;
  final Set<String> _busy = {};

  Cart? get cart => _cart;
  bool get loading => _loading;
  String? get error => _error;
  int get count => _cart?.itemCount ?? 0;
  bool isBusy(String productId) => _busy.contains(productId);
  bool contains(String productId) => _cart?.contains(productId) ?? false;

  /// Wired to AuthProvider through ChangeNotifierProxyProvider in app.dart.
  void onAuthChanged(bool loggedIn) {
    if (loggedIn == _loggedIn) return;
    _loggedIn = loggedIn;
    if (loggedIn) {
      scheduleMicrotask(fetch);
    } else {
      _cart = null;
      _error = null;
      scheduleMicrotask(notifyListeners);
    }
  }

  /// GetCartRequest → GET /cart
  Future<void> fetch() async {
    if (!_loggedIn) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// POST /cart/item/add — throws [ApiException] so the screen can show it.
  Future<void> add(ProductDetail product, {int quantity = 1}) async {
    await _run(product.id, () => _service.addItem(
          productId: product.id,
          quantity: quantity,
          productName: product.name,
          productImage: product.primaryImage,
          price: product.price,
        ));
  }

  /// PUT /cart/item — quantity 0 removes the item.
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) return remove(productId);
    await _run(productId, () => _service.updateQuantity(productId: productId, quantity: quantity));
  }

  /// DELETE /cart/item/{productId}
  Future<void> remove(String productId) => _run(productId, () => _service.removeItem(productId));

  /// DELETE /cart/clear
  Future<void> clear() => _run('*', _service.clearCart);

  Future<void> _run(String key, Future<Cart> Function() action) async {
    _busy.add(key);
    notifyListeners();
    try {
      _cart = await action();
      _error = null;
    } finally {
      _busy.remove(key);
      notifyListeners();
    }
  }
}
