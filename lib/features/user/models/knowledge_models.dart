/// Mô hình dữ liệu cho từng nút lọc Danh mục trên màn hình "5. Tra cứu kiến thức" (Màn hình 5)
class KnowledgeCategoryModel {
  final String id;
  final String label;

  const KnowledgeCategoryModel({required this.id, required this.label});
}

/// Mô hình dữ liệu cho từng Thẻ Kiến thức Sơ cứu trên màn hình "5. Tra cứu kiến thức" (Màn hình 5)
class KnowledgeTopicModel {
  final String id;
  final String categoryId;
  final String title;
  final String subtitle;
  final String? imageUrl;

  const KnowledgeTopicModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });
}
