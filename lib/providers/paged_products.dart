import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/page_response.dart';
import '../models/product.dart';

typedef PageFetcher = Future<PageResponse<ProductSummary>> Function(int pageNo);

/// Infinite-scroll helper for any paginated product endpoint.
/// (The website shows numbered pages; on mobile we load the next page
/// automatically when the user reaches the bottom.)
class PagedProducts extends ChangeNotifier {
  PagedProducts(this._fetch);

  final PageFetcher _fetch;

  final List<ProductSummary> items = [];
  int _nextPage = 1;
  int totalElements = 0;
  bool hasMore = true;
  bool loading = false;
  ApiException? error;
  bool _disposed = false;

  bool get isFirstLoad => loading && items.isEmpty;
  bool get isEmpty => !loading && error == null && items.isEmpty && !hasMore;

  Future<void> refresh() async {
    items.clear();
    _nextPage = 1;
    hasMore = true;
    error = null;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    _notify();
    try {
      final page = await _fetch(_nextPage);
      final known = items.map((e) => e.id).toSet();
      items.addAll(page.content.where((p) => !known.contains(p.id)));
      totalElements = page.totalElements;
      hasMore = !page.last && page.content.isNotEmpty;
      _nextPage++;
    } on ApiException catch (e) {
      error = e;
    } catch (e) {
      error = ApiException('Unexpected response from server.');
      debugPrint('PagedProducts error: $e');
    } finally {
      loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
