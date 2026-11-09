import 'package:flutter/material.dart';

/// Mô hình dữ liệu cho mỗi Thẻ tính năng (Feature Card) trên Trang chủ (Màn hình 1)
class FeatureCardModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const FeatureCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
}

/// Mô hình dữ liệu cho mỗi thẻ trong mục "Tình huống thường gặp" trên Trang chủ (Màn hình 1)
class CommonSituationModel {
  final String id;
  final String title;
  final String? imageUrl;
  final Color baseSkinColor;
  final Color woundAccentColor;
  final IconData medicalIcon;

  const CommonSituationModel({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.baseSkinColor,
    required this.woundAccentColor,
    required this.medicalIcon,
  });
}
