import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/category_node.dart';
import '../models/page_response.dart';
import '../models/product.dart';

/// Mirrors website `src/redux-store/products/action.js` and
/// `src/redux-store/Categories/action.js`.
///
/// Page numbers are 1-based in the app (like the website URL `?pageno=1`)
/// and sent as `pageno - 1` because Spring pages start at 0.
class ProductService {
  ProductService({ApiClient? client}) : _api = client ?? ApiClient.instance;
  final ApiClient _api;

  /// getProducts → GET /products/page?pageno&pagesize
  Future<PageResponse<ProductSummary>> getProducts({
    required int pageNo,
    int pageSize = AppConfig.pageSize,
  }) async {
    final data = await _api.get(
      ApiEndpoints.productsPage,
      query: {'pageno': pageNo - 1, 'pagesize': pageSize},
      auth: false,
    );
    return PageResponse.fromJson(data, ProductSummary.fromJson);
  }

  /// getProductswithCategory → GET /products/page/category/main?category&pageno&pagesize
  Future<PageResponse<ProductSummary>> getProductsByCategory({
    required String category,
    required int pageNo,
    int pageSize = AppConfig.pageSize,
  }) async {
    final data = await _api.get(
      ApiEndpoints.productsByCategory,
      query: {'category': category, 'pageno': pageNo - 1, 'pagesize': pageSize},
      auth: false,
    );
    return PageResponse.fromJson(data, ProductSummary.fromJson);
  }

  /// getProductswithQuery → GET /products/page/query/main?query&pageno&pagesize
  Future<PageResponse<ProductSummary>> searchProducts({
    required String query,
    required int pageNo,
    int pageSize = AppConfig.pageSize,
  }) async {
    final data = await _api.get(
      ApiEndpoints.productsByQuery,
      query: {'query': query, 'pageno': pageNo - 1, 'pagesize': pageSize},
      auth: false,
    );
    return PageResponse.fromJson(data, ProductSummary.fromJson);
  }

  /// getProductDetailsById → GET /products/{id}
  Future<ProductDetail> getProductDetails(String id) async {
    final data = await _api.get(ApiEndpoints.productById(id), auth: false);
    return ProductDetail.fromJson(data is Map ? Map<String, dynamic>.from(data) : {});
  }

  /// getSuggestions → GET /products/suggestions?q=
  /// Like the website, failures are ignored (the list just stays empty).
  Future<List<String>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      final data = await _api.get(ApiEndpoints.suggestions, query: {'q': query.trim()}, auth: false);
      final list = data is List ? data : (data is Map ? (data['content'] ?? data['suggestions']) : null);
      if (list is! List) return const [];
      return list
          .map((item) {
            if (item is String) return item;
            if (item is Map) {
              return (item['title'] ?? item['name'] ?? item['productName'] ?? '').toString();
            }
            return '';
          })
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .take(8)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// getCategories → GET /products/category/tree
  Future<List<CategoryNode>> getCategoryTree() async {
    final data = await _api.get(ApiEndpoints.categoryTree, auth: false);
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => CategoryNode.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
