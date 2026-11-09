import 'package:flutter/material.dart';

/// Mô hình dữ liệu cho từng mục menu trên thanh Sidebar bên trái (Màn hình 2, 3, 4, 5, 6, 7)
class SidebarMenuItemModel {
  final String id;
  final String title;
  final IconData icon;

  const SidebarMenuItemModel({
    required this.id,
    required this.title,
    required this.icon,
  });
}
