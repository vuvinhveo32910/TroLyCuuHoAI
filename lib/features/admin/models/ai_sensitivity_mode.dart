import 'package:flutter/material.dart';

/// Mức độ nhạy AI nhận diện vết thương thay thế cho thanh trượt ngưỡng % khó hiểu
enum AiSensitivityMode {
  lenient, // Nhạy bén (Bắt nhanh - Ngưỡng 35%)
  balanced, // Cân bằng (Tiêu chuẩn y tế - Ngưỡng 50% - Khuyên dùng)
  strict, // Chính xác cao (Nghiêm ngặt - Ngưỡng 70%)
}

extension AiSensitivityModeExt on AiSensitivityMode {
  String get label {
    switch (this) {
      case AiSensitivityMode.lenient:
        return 'Nhạy bén (Bắt nhanh)';
      case AiSensitivityMode.balanced:
        return 'Cân bằng (Chuẩn y tế)';
      case AiSensitivityMode.strict:
        return 'Chính xác cao (Nghiêm ngặt)';
    }
  }

  String get shortLabel {
    switch (this) {
      case AiSensitivityMode.lenient:
        return 'Nhạy cao';
      case AiSensitivityMode.balanced:
        return 'Cân bằng';
      case AiSensitivityMode.strict:
        return 'Chính xác';
    }
  }

  String get description {
    switch (this) {
      case AiSensitivityMode.lenient:
        return 'Dễ phát hiện tổn thương ngay cả khi ảnh mờ, tối hoặc góc khó (ngưỡng 35%). Phù hợp sơ cứu khẩn cấp.';
      case AiSensitivityMode.balanced:
        return 'Cân bằng tối ưu giữa phát hiện vết thương và độ chính xác phân loại (ngưỡng 50%). Khuyên dùng.';
      case AiSensitivityMode.strict:
        return 'Chỉ kích hoạt khi hình ảnh thật sự rõ nét, loại trừ tối đa nhận diện sai (ngưỡng 70%).';
    }
  }

  double get thresholdValue {
    switch (this) {
      case AiSensitivityMode.lenient:
        return 0.35;
      case AiSensitivityMode.balanced:
        return 0.50;
      case AiSensitivityMode.strict:
        return 0.70;
    }
  }

  int get thresholdPercent => (thresholdValue * 100).toInt();

  Color get color {
    switch (this) {
      case AiSensitivityMode.lenient:
        return const Color(0xFF0D9488); // Teal
      case AiSensitivityMode.balanced:
        return const Color(0xFF2563EB); // Blue
      case AiSensitivityMode.strict:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  IconData get icon {
    switch (this) {
      case AiSensitivityMode.lenient:
        return Icons.bolt_rounded;
      case AiSensitivityMode.balanced:
        return Icons.balance_rounded;
      case AiSensitivityMode.strict:
        return Icons.verified_rounded;
    }
  }
}
