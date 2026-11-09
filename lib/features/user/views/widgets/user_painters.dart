import 'dart:math' as math;

import 'package:flutter/material.dart';

class MedicalDocumentRowIconPainter extends CustomPainter {
  const MedicalDocumentRowIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 1.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final docPath = Path()
      ..moveTo(w * 0.20, h * 0.08)
      ..lineTo(w * 0.62, h * 0.08)
      ..lineTo(w * 0.84, h * 0.30)
      ..lineTo(w * 0.84, h * 0.88)
      ..quadraticBezierTo(w * 0.84, h * 0.94, w * 0.76, h * 0.94)
      ..lineTo(w * 0.24, h * 0.94)
      ..quadraticBezierTo(w * 0.16, h * 0.94, w * 0.16, h * 0.88)
      ..lineTo(w * 0.16, h * 0.14)
      ..quadraticBezierTo(w * 0.16, h * 0.08, w * 0.20, h * 0.08)
      ..close();
    canvas.drawPath(docPath, paint);

    final foldPath = Path()
      ..moveTo(w * 0.60, h * 0.08)
      ..lineTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.84, h * 0.30);
    canvas.drawPath(foldPath, paint);

    canvas.drawLine(
      Offset(w * 0.50, h * 0.45),
      Offset(w * 0.50, h * 0.71),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.37, h * 0.58),
      Offset(w * 0.63, h * 0.58),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DocumentSubCategoryIconPainter extends CustomPainter {
  final String categoryId;
  final Color color;

  const DocumentSubCategoryIconPainter({
    required this.categoryId,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (categoryId == 'other') {
      canvas.drawCircle(Offset(w * 0.50, h * 0.32), w * 0.18, paint);
      final bodyPath = Path()
        ..moveTo(w * 0.20, h * 0.86)
        ..quadraticBezierTo(w * 0.24, h * 0.58, w * 0.50, h * 0.58)
        ..quadraticBezierTo(w * 0.76, h * 0.58, w * 0.80, h * 0.86);
      canvas.drawPath(bodyPath, paint);
      return;
    }

    if (categoryId == 'all') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.64),
          const Radius.circular(3.5),
        ),
        paint,
      );
      canvas.drawLine(
        Offset(w * 0.32, h * 0.44),
        Offset(w * 0.68, h * 0.44),
        paint,
      );
      canvas.drawLine(
        Offset(w * 0.32, h * 0.64),
        Offset(w * 0.58, h * 0.64),
        paint,
      );
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.12, w * 0.64, h * 0.76),
        const Radius.circular(3.5),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.36),
      Offset(w * 0.50, h * 0.64),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.36, h * 0.50),
      Offset(w * 0.64, h * 0.50),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant DocumentSubCategoryIconPainter oldDelegate) {
    return oldDelegate.categoryId != categoryId || oldDelegate.color != color;
  }
}

class AiShieldBadgePainter extends CustomPainter {
  const AiShieldBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shieldPath = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.86, h * 0.22)
      ..lineTo(w * 0.86, h * 0.50)
      ..quadraticBezierTo(w * 0.86, h * 0.78, w * 0.50, h * 0.92)
      ..quadraticBezierTo(w * 0.14, h * 0.78, w * 0.14, h * 0.50)
      ..lineTo(w * 0.14, h * 0.22)
      ..close();

    canvas.drawPath(shieldPath, shieldStrokePaint);

    final checkPath = Path()
      ..moveTo(w * 0.35, h * 0.51)
      ..lineTo(w * 0.46, h * 0.62)
      ..lineTo(w * 0.67, h * 0.39);
    canvas.drawPath(checkPath, shieldStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChatUserPortraitAvatarPainter extends CustomPainter {
  const ChatUserPortraitAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    canvas.drawRect(rect, Paint()..color = const Color(0xFFDCEBFE));

    final suitPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.20, h * 0.64, w * 0.50, h * 0.64)
      ..quadraticBezierTo(w * 0.80, h * 0.64, w * 0.88, h)
      ..close();
    canvas.drawPath(suitPath, Paint()..color = const Color(0xFF1E3A8A));

    final collarPath = Path()
      ..moveTo(w * 0.38, h * 0.66)
      ..lineTo(w * 0.50, h * 0.86)
      ..lineTo(w * 0.62, h * 0.66)
      ..close();
    canvas.drawPath(collarPath, Paint()..color = Colors.white);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.61),
        width: w * 0.16,
        height: h * 0.14,
      ),
      Paint()..color = const Color(0xFFEAC0A2),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.40),
        width: w * 0.38,
        height: h * 0.42,
      ),
      Paint()..color = const Color(0xFFF3CFB6),
    );

    final hairPath = Path()
      ..moveTo(w * 0.31, h * 0.40)
      ..quadraticBezierTo(w * 0.32, h * 0.16, w * 0.52, h * 0.17)
      ..quadraticBezierTo(w * 0.70, h * 0.18, w * 0.69, h * 0.39)
      ..quadraticBezierTo(w * 0.54, h * 0.28, w * 0.31, h * 0.40)
      ..close();
    canvas.drawPath(hairPath, Paint()..color = const Color(0xFF1E293B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperPlaneSendIconPainter extends CustomPainter {
  const PaperPlaneSendIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final planePath = Path()
      ..moveTo(w * 0.88, h * 0.12)
      ..lineTo(w * 0.10, h * 0.46)
      ..lineTo(w * 0.44, h * 0.56)
      ..lineTo(w * 0.56, h * 0.90)
      ..close();

    canvas.drawPath(planePath, paint);
    canvas.drawLine(
      Offset(w * 0.88, h * 0.12),
      Offset(w * 0.44, h * 0.56),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KnowledgeTopicThumbnailPainter extends CustomPainter {
  final String topicId;

  const KnowledgeTopicThumbnailPainter({required this.topicId});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    switch (topicId) {
      case 'abrasion':
        final skinPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3D5C1), Color(0xFFE5B89B), Color(0xFFD6A080)],
          ).createShader(rect);
        canvas.drawRect(rect, skinPaint);

        final center = Offset(w * 0.50, h * 0.50);
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFDC2626).withValues(alpha: 0.45),
              const Color(0xFFDC2626).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: 24));
        canvas.drawCircle(center, 24, glowPaint);

        final patchPaint = Paint()
          ..color = const Color(0xFFC84B31).withValues(alpha: 0.78)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 18, height: 26),
          patchPaint,
        );
        break;

      case 'cut_laceration':
        final skinPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECC7B0), Color(0xFFD8A486), Color(0xFFC58C6D)],
          ).createShader(rect);
        canvas.drawRect(rect, skinPaint);

        final cutGlowPaint = Paint()
          ..color = const Color(0xFFDC2626).withValues(alpha: 0.28)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(w * 0.34, h * 0.18),
          Offset(w * 0.62, h * 0.80),
          cutGlowPaint,
        );

        final cutLinePaint = Paint()
          ..color = const Color(0xFF991B1B)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(w * 0.34, h * 0.18),
          Offset(w * 0.62, h * 0.80),
          cutLinePaint,
        );

        canvas.drawCircle(
          Offset(w * 0.49, h * 0.52),
          3.2,
          Paint()..color = const Color(0xFFFEE2E2),
        );
        break;

      case 'burn':
        final bgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64748B), Color(0xFF475569)],
          ).createShader(rect);
        canvas.drawRect(rect, bgPaint);

        final handPath = Path()
          ..moveTo(w * 0.15, h)
          ..quadraticBezierTo(w * 0.22, h * 0.25, w * 0.58, h * 0.18)
          ..quadraticBezierTo(w * 0.88, h * 0.24, w * 0.86, h)
          ..close();

        final handSkinPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEABFA4), Color(0xFFD79C7A)],
          ).createShader(rect);
        canvas.drawPath(handPath, handSkinPaint);

        final burnCenter = Offset(w * 0.54, h * 0.55);
        final burnPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFDC2626).withValues(alpha: 0.72),
              const Color(0xFFEA580C).withValues(alpha: 0.35),
              const Color(0xFFEA580C).withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: burnCenter, radius: 24));
        canvas.drawCircle(burnCenter, 24, burnPaint);
        break;

      case 'bruise':
        final skinPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1D4C2), Color(0xFFE0B8A0)],
          ).createShader(rect);
        canvas.drawRect(rect, skinPaint);

        final bruiseCenter = Offset(w * 0.48, h * 0.52);
        final bruisePaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF4C1D95).withValues(alpha: 0.65),
              const Color(0xFF6D28D9).withValues(alpha: 0.38),
              const Color(0xFF7C3AED).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: bruiseCenter, radius: 28));
        canvas.drawCircle(bruiseCenter, 28, bruisePaint);
        break;

      case 'foreign_body':
        final darkBgPaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64748B), Color(0xFF334155), Color(0xFF1E293B)],
          ).createShader(rect);
        canvas.drawRect(rect, darkBgPaint);

        final strapPaint = Paint()
          ..color = const Color(0xFF0F172A)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(w * 0.20, h * 0.88),
          Offset(w * 0.78, h * 0.22),
          strapPaint,
        );

        final objCenter = Offset(w * 0.48, h * 0.50);
        canvas.drawCircle(
          objCenter,
          17,
          Paint()..color = const Color(0xFF1E293B),
        );
        canvas.drawCircle(
          objCenter,
          14,
          Paint()
            ..color = const Color(0xFFD97706)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0,
        );
        canvas.drawCircle(
          objCenter,
          8,
          Paint()..color = const Color(0xFF78350F),
        );
        break;

      default:
        final tablePaint = Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5E1DA), Color(0xFFE5C4B8)],
          ).createShader(rect);
        canvas.drawRect(rect, tablePaint);

        canvas.drawCircle(
          Offset(w * 0.36, h * 0.44),
          16,
          Paint()..color = const Color(0xFFDC2626).withValues(alpha: 0.75),
        );

        final moldCenter = Offset(w * 0.54, h * 0.54);
        canvas.drawCircle(
          moldCenter,
          19,
          Paint()..color = const Color(0xFF4D7C0F),
        );
        canvas.drawCircle(
          Offset(w * 0.52, h * 0.50),
          13,
          Paint()..color = const Color(0xFF84CC16),
        );
        canvas.drawCircle(
          Offset(w * 0.60, h * 0.58),
          8,
          Paint()..color = const Color(0xFFBEF264),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant KnowledgeTopicThumbnailPainter oldDelegate) {
    return oldDelegate.topicId != topicId;
  }
}

class WorkspaceSidebarBackgroundPainter extends CustomPainter {
  final double sidebarWidth;
  final Color backgroundColor;
  final Color dividerColor;

  const WorkspaceSidebarBackgroundPainter({
    required this.sidebarWidth,
    required this.backgroundColor,
    required this.dividerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, sidebarWidth, size.height), bgPaint);

    final dividerPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(sidebarWidth + 0.5, 0),
      Offset(sidebarWidth + 0.5, size.height),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WorkspaceSidebarBackgroundPainter oldDelegate) {
    return oldDelegate.sidebarWidth != sidebarWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dividerColor != dividerColor;
  }
}



class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  const DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = math.min(borderRadius, math.min(size.width, size.height) / 2);

    _drawDashedLine(canvas, paint, Offset(r, 0), Offset(size.width - r, 0));
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width, r),
      Offset(size.width, size.height - r),
    );
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width - r, size.height),
      Offset(r, size.height),
    );
    _drawDashedLine(canvas, paint, Offset(0, size.height - r), Offset(0, r));

    if (r > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r),
        math.pi,
        math.pi / 2,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width - r, r), radius: r),
        -math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width - r, size.height - r),
          radius: r,
        ),
        0,
        math.pi / 2,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, size.height - r), radius: r),
        math.pi / 2,
        math.pi / 2,
        false,
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final totalDistance = (end - start).distance;
    if (totalDistance <= 0) return;

    final direction = (end - start) / totalDistance;
    double currentDistance = 0;

    while (currentDistance < totalDistance) {
      final nextDistance = math.min(
        currentDistance + dashLength,
        totalDistance,
      );
      canvas.drawLine(
        start + direction * currentDistance,
        start + direction * nextDistance,
        paint,
      );
      currentDistance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}


class BodyPartIconPainter extends CustomPainter {
  final String partId;
  final Color color;

  const BodyPartIconPainter({required this.partId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (partId) {
      case 'arm':
        final path = Path()
          ..moveTo(w * 0.24, h * 0.62)
          ..quadraticBezierTo(w * 0.16, h * 0.84, w * 0.42, h * 0.84)
          ..lineTo(w * 0.72, h * 0.78)
          ..quadraticBezierTo(w * 0.86, h * 0.72, w * 0.78, h * 0.56)
          ..quadraticBezierTo(w * 0.66, h * 0.46, w * 0.52, h * 0.56)
          ..lineTo(w * 0.56, h * 0.26)
          ..quadraticBezierTo(w * 0.56, h * 0.14, w * 0.44, h * 0.16)
          ..quadraticBezierTo(w * 0.34, h * 0.18, w * 0.36, h * 0.32)
          ..lineTo(w * 0.34, h * 0.56);
        canvas.drawPath(path, paint);
        break;

      case 'leg':
        final legPath = Path()
          ..moveTo(w * 0.36, h * 0.16)
          ..lineTo(w * 0.36, h * 0.68)
          ..quadraticBezierTo(w * 0.22, h * 0.74, w * 0.22, h * 0.82)
          ..lineTo(w * 0.68, h * 0.82)
          ..quadraticBezierTo(w * 0.76, h * 0.82, w * 0.74, h * 0.72)
          ..lineTo(w * 0.58, h * 0.66)
          ..lineTo(w * 0.58, h * 0.16);
        canvas.drawPath(legPath, paint);
        break;

      case 'head':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.42),
            width: w * 0.52,
            height: h * 0.56,
          ),
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.23, h * 0.44),
            width: w * 0.1,
            height: h * 0.16,
          ),
          math.pi / 2,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.77, h * 0.44),
            width: w * 0.1,
            height: h * 0.16,
          ),
          -math.pi / 2,
          math.pi,
          false,
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.40, h * 0.68),
          Offset(w * 0.36, h * 0.84),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.60, h * 0.68),
          Offset(w * 0.64, h * 0.84),
          paint,
        );
        break;

      case 'back':
        final torsoPath = Path()
          ..moveTo(w * 0.22, h * 0.26)
          ..quadraticBezierTo(w * 0.50, h * 0.18, w * 0.78, h * 0.26)
          ..lineTo(w * 0.72, h * 0.82)
          ..lineTo(w * 0.28, h * 0.82)
          ..close();
        canvas.drawPath(torsoPath, paint);
        canvas.drawLine(
          Offset(w * 0.50, h * 0.24),
          Offset(w * 0.50, h * 0.80),
          paint,
        );
        break;

      case 'other':
      default:
        canvas.drawLine(
          Offset(w * 0.42, h * 0.42),
          Offset(w * 0.20, h * 0.20),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.20, h * 0.20),
          Offset(w * 0.36, h * 0.20),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.20, h * 0.20),
          Offset(w * 0.20, h * 0.36),
          paint,
        );

        canvas.drawLine(
          Offset(w * 0.58, h * 0.42),
          Offset(w * 0.80, h * 0.20),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.80, h * 0.20),
          Offset(w * 0.64, h * 0.20),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.80, h * 0.20),
          Offset(w * 0.80, h * 0.36),
          paint,
        );

        canvas.drawLine(
          Offset(w * 0.42, h * 0.58),
          Offset(w * 0.20, h * 0.80),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.20, h * 0.80),
          Offset(w * 0.36, h * 0.80),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.20, h * 0.80),
          Offset(w * 0.20, h * 0.64),
          paint,
        );

        canvas.drawLine(
          Offset(w * 0.58, h * 0.58),
          Offset(w * 0.80, h * 0.80),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.80, h * 0.80),
          Offset(w * 0.64, h * 0.80),
          paint,
        );
        canvas.drawLine(
          Offset(w * 0.80, h * 0.80),
          Offset(w * 0.80, h * 0.64),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant BodyPartIconPainter oldDelegate) {
    return oldDelegate.partId != partId || oldDelegate.color != color;
  }
}
