/// Matches backend `CategoryNode {id, name, children}` from
/// `GET /products/category/tree`.
class CategoryNode {
  const CategoryNode({required this.id, required this.name, this.children = const []});

  final String id;
  final String name;
  final List<CategoryNode> children;

  bool get hasChildren => children.isNotEmpty;

  factory CategoryNode.fromJson(Map<String, dynamic> j) => CategoryNode(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        children: (j['children'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => CategoryNode.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
