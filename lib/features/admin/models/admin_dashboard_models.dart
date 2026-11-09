import 'package:flutter/material.dart';

/// Mô hình dữ liệu cho từng mục menu trên thanh Sidebar bên trái của Quản trị (Màn hình 10+)
class AdminSidebarItemModel {
  final String id;
  final String title;
  final IconData icon;
  final bool hasTrailingChevron;

  const AdminSidebarItemModel({
    required this.id,
    required this.title,
    required this.icon,
    this.hasTrailingChevron = false,
  });
}

/// Mô hình dữ liệu cho mỗi Thẻ chỉ số thống kê (KPI Card) ở hàng trên của Dashboard (Màn hình 10)
class AdminKpiCardModel {
  final String id;
  final String title;
  final String mainValue;
  final String growthHighlight;
  final String growthComparisonText;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color valueColor;

  const AdminKpiCardModel({
    required this.id,
    required this.title,
    required this.mainValue,
    required this.growthHighlight,
    required this.growthComparisonText,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.valueColor,
  });
}

/// Mô hình dữ liệu cho từng phân khúc trong "Thống kê loại tổn thương" (Biểu đồ Donut - Màn hình 10)
class AdminInjuryStatItemModel {
  final String id;
  final String label;
  final int percentage;
  final Color color;

  const AdminInjuryStatItemModel({
    required this.id,
    required this.label,
    required this.percentage,
    required this.color,
  });

  String get formattedPercentage => '$percentage%';
}

/// Mô hình dữ liệu cho từng mục trong danh sách "Hoạt động gần đây" (Màn hình 10)
class AdminRecentActivityModel {
  final String id;
  final String title;
  final String relativeTime;
  final IconData icon;

  const AdminRecentActivityModel({
    required this.id,
    required this.title,
    required this.relativeTime,
    required this.icon,
  });
}
