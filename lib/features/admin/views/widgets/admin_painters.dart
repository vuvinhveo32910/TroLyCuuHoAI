import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/admin_dashboard_models.dart';

/// Vẽ họa tiết sóng nền mềm mại cho khung thẻ Đăng nhập quản trị (Màn hình 9)
class AdminLoginWaveBackgroundPainter extends CustomPainter {
  const AdminLoginWaveBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bottomWavePaint = Paint()
      ..color = const Color(0xFFE9F0FA).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final bottomPath = Path()
      ..moveTo(size.width * 0.22, size.height)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.80,
        size.width * 0.56,
        size.height * 0.86,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.93,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottomPath, bottomWavePaint);

    final topCornerPaint = Paint()
      ..color = const Color(0xFFDCE8FC).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    final topCornerPath = Path()
      ..moveTo(size.width * 0.84, 0)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.16,
        size.width,
        size.height * 0.14,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(topCornerPath, topCornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Vẽ hình minh họa Laptop và Khiên bảo mật có dấu tích trắng (Cột phải Màn hình 9)

/// Vẽ Biểu đồ vòng (Donut Chart) cho thẻ "Thống kê loại tổn thương" (Màn hình 10)
class AdminInjuryDonutChartPainter extends CustomPainter {
  final List<AdminInjuryStatItemModel> segments;
  final double strokeWidth;

  const AdminInjuryDonutChartPainter({
    required this.segments,
    this.strokeWidth = 34.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = segments.fold<int>(0, (sum, item) => sum + item.percentage);
    if (total <= 0) return;

    // Bắt đầu vẽ từ góc -110 độ (phía trên hơi lệch trái giống hệt ảnh thiết kế Màn hình 10)
    double startAngle = -110 * (math.pi / 180.0);
    const double gapRadians =
        0.035; // Khe trắng mảnh phân tách giữa các cung màu

    for (final segment in segments) {
      final sweepAngle = (segment.percentage / total) * (2 * math.pi);
      final adjustedSweep = math.max(0.01, sweepAngle - gapRadians);

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect,
        startAngle + (gapRadians / 2),
        adjustedSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant AdminInjuryDonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
