import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

/// Wishlist saved on the phone.
///
/// The backend has no wishlist API yet (the website page uses sample data),
/// so the app keeps it locally in SharedPreferences.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        for (final e in (jsonDecode(raw) as List).whereType<Map>()) {
          final p = ProductSummary.fromJson(Map<String, dynamic>.from(e));
          _items[p.id] = p;
        }
      } catch (_) {
        _prefs.remove(_key);
      }
    }
  }

  static const _key = 'wishlist';
  final SharedPreferences _prefs;
  final Map<String, ProductSummary> _items = {};

  List<ProductSummary> get items => _items.values.toList().reversed.toList();
  int get count => _items.length;
  bool contains(String id) => _items.containsKey(id);

  /// Returns true if the product is now in the wishlist.
  bool toggle(ProductSummary product) {
    final added = !_items.containsKey(product.id);
    if (added) {
      _items[product.id] = product;
    } else {
      _items.remove(product.id);
    }
    _save();
    return added;
  }

  void remove(String id) {
    if (_items.remove(id) != null) _save();
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(_items.values.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}
