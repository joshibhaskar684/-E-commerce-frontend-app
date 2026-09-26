import '../core/utils/formatters.dart';

/// A Spring Data `Page<T>` as returned by the /products/page* endpoints.
///
/// Supports both JSON shapes Spring can produce:
///   classic:  {content:[…], number, totalPages, totalElements, last}
///   VIA_DTO:  {content:[…], page:{number, size, totalPages, totalElements}}
class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.totalElements,
    required this.last,
  });

  final List<T> content;

  /// Zero-based page index (the website sends `pageno - 1`).
  final int number;
  final int totalPages;
  final int totalElements;
  final bool last;

  factory PageResponse.fromJson(dynamic json, T Function(Map<String, dynamic>) fromItem) {
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};
    final items = (map['content'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => fromItem(Map<String, dynamic>.from(e)))
        .toList();
    final meta = map['page'] is Map ? Map<String, dynamic>.from(map['page'] as Map) : map;
    final number = toInt(meta['number']) ?? 0;
    final totalPages = toInt(meta['totalPages']) ?? (items.isEmpty ? 0 : 1);
    final totalElements = toInt(meta['totalElements']) ?? items.length;
    final last = map['last'] is bool ? map['last'] as bool : number >= totalPages - 1;
    return PageResponse(
      content: items,
      number: number,
      totalPages: totalPages,
      totalElements: totalElements,
      last: last || items.isEmpty,
    );
  }
}
