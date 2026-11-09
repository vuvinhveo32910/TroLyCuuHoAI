import 'package:flutter/material.dart';

/// Mô hình dữ liệu cho từng mục Danh mục trong màn hình "Kho tài liệu y tế (Người dùng)" (Màn hình 7)
class MedicalDocumentCategoryModel {
  final String id;
  final String sidebarLabel;
  final String dropdownLabel;
  final IconData icon;

  const MedicalDocumentCategoryModel({
    required this.id,
    required this.sidebarLabel,
    required this.dropdownLabel,
    required this.icon,
  });
}

/// Mô hình dữ liệu cho từng Tài liệu Y tế được lưu trữ cục bộ trên thiết bị (Màn hình 7)
class MedicalDocumentModel {
  final String id;
  final String title;
  final String categoryId;
  final String categoryLabel;
  final String dateAdded;
  final int pageGroup;
  final String fileName;
  final String fileExtension;
  final String fileSize;
  final String localFilePath;
  final bool isUserAdded;
  final String summary;
  final List<String> contentPoints;
  final String? relatedGuideTopicId;
  final String? externalUrl;

  const MedicalDocumentModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryLabel,
    required this.dateAdded,
    this.pageGroup = 1,
    required this.fileName,
    this.fileExtension = 'PDF',
    this.fileSize = '1.2 MB',
    required this.localFilePath,
    this.isUserAdded = false,
    required this.summary,
    required this.contentPoints,
    this.relatedGuideTopicId,
    this.externalUrl,
  });

  MedicalDocumentModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? categoryLabel,
    String? dateAdded,
    int? pageGroup,
    String? fileName,
    String? fileExtension,
    String? fileSize,
    String? localFilePath,
    bool? isUserAdded,
    String? summary,
    List<String>? contentPoints,
    String? relatedGuideTopicId,
    String? externalUrl,
  }) {
    return MedicalDocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      dateAdded: dateAdded ?? this.dateAdded,
      pageGroup: pageGroup ?? this.pageGroup,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      localFilePath: localFilePath ?? this.localFilePath,
      isUserAdded: isUserAdded ?? this.isUserAdded,
      summary: summary ?? this.summary,
      contentPoints: contentPoints ?? this.contentPoints,
      relatedGuideTopicId: relatedGuideTopicId ?? this.relatedGuideTopicId,
      externalUrl: externalUrl ?? this.externalUrl,
    );
  }

  /// Chuyển đổi Model sang Map JSON tương thích với bảng 'medical_documents' trong Supabase (PostgreSQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category_id': categoryId,
      'category_label': categoryLabel,
      'date_added': dateAdded,
      'page_group': pageGroup,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'local_file_path': localFilePath,
      'is_user_added': isUserAdded,
      'summary': summary,
      'content_points': contentPoints,
      'related_guide_topic_id': relatedGuideTopicId,
      'external_url': externalUrl,
    };
  }

  /// Khởi tạo Model từ dữ liệu truy vấn Supabase (hỗ trợ cả snake_case và camelCase)
  factory MedicalDocumentModel.fromMap(Map<String, dynamic> map) {
    return MedicalDocumentModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? map['categoryId'] as String? ?? 'other',
      categoryLabel: map['category_label'] as String? ?? map['categoryLabel'] as String? ?? 'Khác',
      dateAdded: map['date_added'] as String? ?? map['dateAdded'] as String? ?? '',
      pageGroup: (map['page_group'] as num?)?.toInt() ?? (map['pageGroup'] as num?)?.toInt() ?? 1,
      fileName: map['file_name'] as String? ?? map['fileName'] as String? ?? '',
      fileExtension: map['file_extension'] as String? ?? map['fileExtension'] as String? ?? 'PDF',
      fileSize: map['file_size'] as String? ?? map['fileSize'] as String? ?? '1.0 MB',
      localFilePath: map['local_file_path'] as String? ??
          map['localFilePath'] as String? ??
          map['file_url'] as String? ??
          '',
      isUserAdded: map['is_user_added'] as bool? ?? map['isUserAdded'] as bool? ?? false,
      summary: map['summary'] as String? ?? '',
      contentPoints: List<String>.from(
        map['content_points'] as List? ??
            map['contentPoints'] as List? ??
            const [],
      ),
      relatedGuideTopicId: map['related_guide_topic_id'] as String? ?? map['relatedGuideTopicId'] as String?,
      externalUrl: map['external_url'] as String? ?? map['externalUrl'] as String?,
    );
  }
}
