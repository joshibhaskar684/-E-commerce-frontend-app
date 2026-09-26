import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'products/product_detail_screen.dart';
import 'products/product_list_screen.dart';
import 'search/search_screen.dart';

/// All navigation in one place, so screens don't need to know each other.
class AppRoutes {
  AppRoutes._();

  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

  static Future<void> openProduct(BuildContext context, String id, {ProductSummary? preview}) =>
      push(context, ProductDetailScreen(productId: id, preview: preview));

  static Future<void> openCategory(BuildContext context, {required String category, String? title}) =>
      push(context, ProductListScreen.category(category: category, title: title));

  static Future<void> openAllProducts(BuildContext context) => push(context, const ProductListScreen.all());

  static Future<void> openSearchResults(BuildContext context, String query) =>
      push(context, ProductListScreen.search(query: query));

  static Future<void> openSearch(BuildContext context) => push(context, const SearchScreen());

  /// Shows the login screen if needed. Returns true when the user is logged in.
  static Future<bool> ensureLoggedIn(BuildContext context, {String? reason}) async {
    if (context.read<AuthProvider>().isLoggedIn) return true;
    await push<bool>(context, LoginScreen(reason: reason));
    return context.mounted && context.read<AuthProvider>().isLoggedIn;
  }
}
