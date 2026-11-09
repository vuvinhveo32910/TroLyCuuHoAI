// File: lib/features/user/views/analysis_result_view.dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/feedback/ai_feedback_model.dart';
import '../../../core/feedback/ai_feedback_service.dart';
import '../../../core/rule_engine/rule_models.dart';
import '../models/image_analysis_models.dart';
import '../viewmodels/user_viewmodel.dart';
import 'widgets/user_painters.dart';

/// Màn hình Kết quả phân tích hình ảnh AI
/// Thiết kế trực quan, gom gọn thông tin trong 1 khung nhìn (hạn chế tối đa cuộn chuột)
class KetQuaPhanTichView extends StatelessWidget {
  const KetQuaPhanTichView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final result = viewModel.analysisResult;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 860;
    final isMobile = screenWidth < 600;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. THANH TIÊU ĐỀ TRÊN CÙNG: Tích hợp nút Quay lại + Tiêu đề + Huy hiệu trạng thái
              _buildCompactTopBar(context, viewModel, result, isDesktop: isDesktop),
              const SizedBox(height: 12),

              // 2. BỐ CỤC NỘI DUNG CHÍNH (2 CỘT TRÊN MÀN HÌNH RỘNG, 1 CỘT TRÊN MÀN HÌNH NHỎ)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CỘT TRÁI: Ảnh quét AI + Khung Bounding Box + Cụm nút hành động chính
                    Expanded(
                      flex: 46,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRealWoundImageCard(context, viewModel, result, isDesktop: true),
                          const SizedBox(height: 10),
                          _buildActionButtonsBlock(context, viewModel, result, isDesktop: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),

                    // CỘT PHẢI: Bảng điều khiển ngữ cảnh lâm sàng thu gọn (vừa vặn không tràn)
                    Expanded(
                      flex: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAiDiagnosisCard(context, viewModel, result),
                          const SizedBox(height: 10),
                          _buildLocationCard(context, viewModel),
                          const SizedBox(height: 10),
                          _buildPainLevelCard(context, viewModel),
                          const SizedBox(height: 10),
                          _buildClinicalSymptomsCard(context, viewModel),
                        ],
                      ),
                    ),
                  ],
                )
              else
                // Bố cục di động / màn hình hẹp
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRealWoundImageCard(context, viewModel, result, isDesktop: false),
                    const SizedBox(height: 12),
                    _buildAiDiagnosisCard(context, viewModel, result),
                    const SizedBox(height: 10),
                    _buildLocationCard(context, viewModel),
                    const SizedBox(height: 10),
                    _buildPainLevelCard(context, viewModel),
                    const SizedBox(height: 10),
                    _buildClinicalSymptomsCard(context, viewModel),
                    const SizedBox(height: 14),
                    _buildActionButtonsBlock(context, viewModel, result, isDesktop: false),
                  ],
                ),
            ],
          ),
        ),

        // Lớp phủ loading khi người dùng bấm Quét lại với độ tương phản
        if (viewModel.isAnalyzing)
          Positioned.fill(
            child: _buildReAnalyzingLoadingOverlay(context, viewModel),
          ),
      ],
    );
  }

  // ===========================================================================
  // 1. THANH TIÊU ĐỀ TRÊN CÙNG GỌN GÀNG (TÍCH HỢP TRẠNG THÁI AI TRONG 1 HÀNG)
  // ===========================================================================
  Widget _buildCompactTopBar(
    BuildContext context,
    UserViewModel viewModel,
    AiAnalysisResultModel result, {
    required bool isDesktop,
  }) {
    final bool isSuccess = result.isDetected && result.confidencePercent >= 50;
    final bool isLowConfidence = !result.isManualSelection &&
        (result.isDetected && result.confidencePercent < 50);

    final Color statusBg = result.isManualSelection
        ? const Color(0xFFDCFCE7)
        : (isSuccess
            ? const Color(0xFFECFDF5)
            : (isLowConfidence ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2)));

    final Color statusBorder = result.isManualSelection
        ? const Color(0xFF86EFAC)
        : (isSuccess
            ? const Color(0xFFA7F3D0)
            : (isLowConfidence ? const Color(0xFFFED7AA) : const Color(0xFFFECACA)));

    final Color statusTextColor = result.isManualSelection
        ? const Color(0xFF15803D)
        : (isSuccess
            ? const Color(0xFF047857)
            : (isLowConfidence ? const Color(0xFFC2410C) : const Color(0xFFB91C1C)));

    final String statusLabel = result.isManualSelection
        ? 'Thủ công: ${result.injuryType}'
        : (result.isDetected
            ? (result.hasMultipleInjuries
                ? 'Phát hiện ${result.allDetections.length} vết thương (${result.formattedConfidence})'
                : 'YOLO AI: ${result.injuryType} (${result.formattedConfidence})')
            : 'Chưa phát hiện vết thương rõ');

    return Row(
      children: [
        IconButton(
          onPressed: () => context.read<UserViewModel>().navigateBack(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0D2B6B),
            size: 20,
          ),
          tooltip: 'Quay lại',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            hoverColor: const Color(0xFFE2E8F0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Kết quả phân tích hình ảnh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D2B6B),
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),

        // Huy hiệu trạng thái chẩn đoán
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.isManualSelection
                    ? Icons.check_circle_rounded
                    : (isSuccess ? Icons.verified_rounded : Icons.info_outline_rounded),
                size: 14,
                color: statusTextColor,
              ),
              const SizedBox(width: 5),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusTextColor,
                ),
              ),
            ],
          ),
        ),

        if (result.appliedContrast != 1.0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Text(
              'Tương phản x${result.appliedContrast.toStringAsFixed(1)}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // 2. KHUNG HIỂN THỊ ẢNH THỰC TẾ + BOUNDING BOX YOLO (GỌN CAO 310PX)
  // ===========================================================================
  Widget _buildRealWoundImageCard(
    BuildContext context,
    UserViewModel viewModel,
    AiAnalysisResultModel result, {
    required bool isDesktop,
  }) {
    final Uint8List? imageBytes = result.rawImageBytes;
    final double cardHeight = isDesktop ? 310 : 250;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100D2B6B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ảnh gốc người dùng đã tải
          if (imageBytes != null && imageBytes.isNotEmpty)
            Positioned.fill(
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.white54),
                  SizedBox(height: 6),
                  Text(
                    'Chưa có dữ liệu ảnh',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

          // 2. Lớp vẽ Bounding Box của mô hình YOLO offline best.pt
          if (imageBytes != null &&
              (result.allDetections.isNotEmpty ||
                  (result.boundingBox != null && result.boundingBox!.length == 4)))
            _buildRealBoundingBoxes(result),

          // 3. Tên file ảnh hiển thị góc dưới trái
          if (result.imageFileName != null && result.imageFileName!.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_outlined, size: 12, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(
                      result.imageFileName!,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Nhãn số lượng phát hiện (nếu có đa vết thương)
          if (result.allDetections.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${result.allDetections.length} vùng tổn thương',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Vẽ các khung Bounding Box theo toạ độ YOLO [x1, y1, x2, y2]
  Widget _buildRealBoundingBoxes(AiAnalysisResultModel result) {
    final double? origW = result.originalImageWidth;
    final double? origH = result.originalImageHeight;

    final List<DetectedWoundItemModel> detections = result.allDetections.isNotEmpty
        ? result.allDetections
        : (result.boundingBox != null && result.boundingBox!.length == 4
            ? [
                DetectedWoundItemModel(
                  label: result.injuryType,
                  topicId: result.detectedTopicId,
                  confidencePercent: result.confidencePercent,
                  severity: 'Nhẹ',
                  box: result.boundingBox!,
                  classId: '',
                )
              ]
            : []);

    if (detections.isEmpty) return const SizedBox.shrink();

    if (origW == null || origH == null || origW <= 0 || origH <= 0) {
      return Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEF4444), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            color: const Color(0xFFEF4444),
            child: Text(
              result.boundingBoxLabel,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerW = constraints.maxWidth;
        final double containerH = constraints.maxHeight;

        final double imageAspect = origW / origH;
        final double containerAspect = containerW / containerH;

        double renderW, renderH, offsetX, offsetY;
        if (imageAspect > containerAspect) {
          renderW = containerW;
          renderH = containerW / imageAspect;
          offsetX = 0;
          offsetY = (containerH - renderH) / 2;
        } else {
          renderH = containerH;
          renderW = containerH * imageAspect;
          offsetX = (containerW - renderW) / 2;
          offsetY = 0;
        }

        return Stack(
          children: detections.map((det) {
            final box = det.box;
            if (box.length < 4) return const SizedBox.shrink();

            final double leftRatio = (box[0] / origW).clamp(0.0, 1.0);
            final double topRatio = (box[1] / origH).clamp(0.0, 1.0);
            final double rightRatio = (box[2] / origW).clamp(0.0, 1.0);
            final double bottomRatio = (box[3] / origH).clamp(0.0, 1.0);

            final double boxLeft = offsetX + (leftRatio * renderW);
            final double boxTop = offsetY + (topRatio * renderH);
            final double boxW = (rightRatio - leftRatio) * renderW;
            final double boxH = (bottomRatio - topRatio) * renderH;
            final boxColor = det.tagColor;

            return Positioned(
              left: boxLeft,
              top: boxTop,
              width: boxW.clamp(16.0, containerW),
              height: boxH.clamp(16.0, containerH),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: boxColor, width: 2.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                    child: Text(
                      '${det.label} ${det.confidencePercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ===========================================================================
  // 3. CỤM NÚT HÀNH ĐỘNG CHÍNH (ĐẶT NGAY DƯỚI ẢNH - TRỰC QUAN KHÔNG CẦN CUỘN)
  // ===========================================================================
  Widget _buildActionButtonsBlock(
    BuildContext context,
    UserViewModel viewModel,
    AiAnalysisResultModel result, {
    required bool isDesktop,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hàng 1: 2 nút hành động lớn quan trọng nhất (Xem sơ cứu & Hỏi đáp AI)
        Row(
          children: [
            Expanded(
              flex: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.read<UserViewModel>().onViewFirstAidGuidePressed(),
                icon: const Icon(Icons.verified_rounded, size: 17),
                label: const Text(
                  'Xem sơ cứu nhanh',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.read<UserViewModel>().consultAiWithCurrentAnalysis(),
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text(
                  'Xem với AI',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Hàng 2: Nút Quét ảnh khác & Quét lại với độ tương phản
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => viewModel.onSelectImageFromFilePressed(context),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 15),
                label: const Text(
                  'Quét ảnh khác',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final double current = result.appliedContrast;
                  double nextContrast = 1.35;
                  if (current == 1.35) {
                    nextContrast = 1.6;
                  } else if (current == 1.6) {
                    nextContrast = 0.85;
                  } else {
                    nextContrast = 1.35;
                  }
                  viewModel.reScanWithContrast(context, newContrast: nextContrast);
                },
                icon: const Icon(Icons.contrast_rounded, size: 15, color: Color(0xFF2563EB)),
                label: Text(
                  result.appliedContrast != 1.0
                      ? 'Tương phản (x${result.appliedContrast == 1.35 ? 1.6 : 1.35})'
                      : 'Tăng tương phản',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Hàng 3: Ghi chú nhắc nhở y tế gọn nhẹ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.bottomNoticeText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. THẺ THÔNG TIN NHẬN DIỆN AI & ĐÁNH GIÁ (CỘT PHẢI)
  // ===========================================================================
  Widget _buildAiDiagnosisCard(
    BuildContext context,
    UserViewModel viewModel,
    AiAnalysisResultModel result,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề thẻ & Nhãn Model
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    result.infoCardTitle,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: result.isManualSelection
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: result.isManualSelection
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  result.isManualSelection ? 'Người dùng chọn' : 'YOLO Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: result.isManualSelection
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tên tổn thương chính & Độ tin cậy
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.injuryType,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• Độ tin cậy: ${result.formattedConfidence}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          // Các tổn thương phụ kết hợp (nếu có)
          if (result.hasMultipleInjuries) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: result.allDetections.map((det) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: det.tagColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: det.tagColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: det.tagColor),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${det.label} (${det.confidencePercent}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: det.tagColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          // Thanh tiện ích: [Chọn loại khác] + [Đánh giá: 👍 / ⚠️]
          Row(
            children: [
              InkWell(
                onTap: () => _showManualPickerModal(context, viewModel),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'Không khớp? Chọn thủ công',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Đánh giá AI:',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showAiFeedbackDialog(
                  context,
                  viewModel,
                  result,
                  initialType: AiFeedbackType.helpful,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thumb_up_alt_rounded, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 3),
                      Text(
                        'Chuẩn',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: () => _showAiFeedbackDialog(
                  context,
                  viewModel,
                  result,
                  initialType: AiFeedbackType.inaccurate,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.report_problem_rounded, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 3),
                      Text(
                        'Báo sai',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CHỌN VỊ TRÍ TỔN THƯƠNG: THANH 5 PHÂN ĐOẠN NHỎ GỌN (CHIỀU CAO ~36PX)
  // ===========================================================================
  Widget _buildLocationCard(BuildContext context, UserViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.accessibility_new_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              const Text(
                'Vị trí tổn thương trên cơ thể:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B6B),
                ),
              ),
              const Spacer(),
              Text(
                viewModel.selectedLocationLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 5 phân đoạn vị trí theo hàng ngang
          LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = (constraints.maxWidth - (4 * 6)) / 5;

              return Row(
                children: viewModel.injuryLocations.map((option) {
                  final bool isSelected = viewModel.selectedLocationId == option.id;

                  return Container(
                    width: itemWidth,
                    margin: EdgeInsets.only(right: option == viewModel.injuryLocations.last ? 0 : 6),
                    child: Material(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(7),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () {
                          final vm = context.read<UserViewModel>();
                          vm.selectInjuryLocation(option.id);
                          vm.updateLatestHistoryLocation(option.label);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 15,
                                height: 15,
                                child: CustomPaint(
                                  painter: BodyPartIconPainter(
                                    partId: option.id,
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. CẢM GIÁC ĐAU: BẬT 3 PHÂN ĐOẠN 1-CLICK (CHIỀU CAO ~38PX)
  // ===========================================================================
  Widget _buildPainLevelCard(BuildContext context, UserViewModel viewModel) {
    final currentLevel = viewModel.painLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              const Text(
                'Mức độ cảm giác đau:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B6B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: currentLevel.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: currentLevel.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  currentLevel.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: currentLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3 Nút phân đoạn đau: Không đau (0) | Đau nhẹ (1-4) | Đau nặng (7-10)
          Row(
            children: [
              Expanded(
                child: _buildPainSegmentButton(
                  label: 'Không đau',
                  sub: '0/10',
                  isSelected: currentLevel == PainLevel.none,
                  activeColor: const Color(0xFF16A34A),
                  onTap: () => viewModel.setPainLevel(PainLevel.none),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPainSegmentButton(
                  label: 'Đau nhẹ',
                  sub: '1-4/10',
                  isSelected: currentLevel == PainLevel.mild,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => viewModel.setPainLevel(PainLevel.mild),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPainSegmentButton(
                  label: 'Đau nặng',
                  sub: '7-10/10',
                  isSelected: currentLevel == PainLevel.severe,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => viewModel.setPainLevel(PainLevel.severe),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainSegmentButton({
    required String label,
    required String sub,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF475569),
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? activeColor : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. TRIỆU CHỨNG NGUY CẤP QUAN SÁT: 3 HÀNG CHỌN NHANH SIÊU GỌN
  // ===========================================================================
  Widget _buildClinicalSymptomsCard(BuildContext context, UserViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rtl_rounded, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                'Triệu chứng nguy cấp kèm theo (nếu có):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _buildCompactSymptomRow(
            label: 'Dị vật cắm vào vết thương (dằm, kim loại, thủy tinh...)',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEA580C),
            value: viewModel.hasForeignBody,
            onChanged: (val) {
              viewModel.toggleHasForeignBody(val);
              viewModel.toggleWarningSymptom(hasDeepWoundOrForeignBody: val ?? false);
            },
          ),
          const SizedBox(height: 6),
          _buildCompactSymptomRow(
            label: 'Vết thương đang chảy máu (chảy nhiều hoặc liên tục)',
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFFDC2626),
            value: viewModel.isBleeding,
            onChanged: (val) {
              viewModel.toggleIsBleeding(val);
              viewModel.toggleWarningSymptom(isBleedingHeavy: val ?? false);
            },
          ),
          const SizedBox(height: 6),
          _buildCompactSymptomRow(
            label: 'Vết thương chảy mủ / Sưng tấy đỏ (dấu hiệu nhiễm trùng)',
            icon: Icons.healing_outlined,
            iconColor: const Color(0xFFD97706),
            value: viewModel.hasPusOrInfection,
            onChanged: (val) {
              viewModel.toggleHasPusOrInfection(val);
              viewModel.toggleWarningSymptom(hasSignsOfInfection: val ?? false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSymptomRow({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: value ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
              width: value ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF2563EB),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    color: value ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 8. HỘP THOẠI MODAL CHỌN THỦ CÔNG 4 LOẠI VẾT THƯƠNG (KHÔNG LÀM XÔ LỆCH GIAO DIỆN)
  // ===========================================================================
  void _showManualPickerModal(BuildContext context, UserViewModel viewModel) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chọn thủ công loại tổn thương',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn trực tiếp 1 trong 4 loại tổn thương dưới đây nếu AI nhận diện chưa khớp:',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF78350F)),
                ),
                const SizedBox(height: 14),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: viewModel.manualInjuryOptions.map((option) {
                    final isCurrentSelected =
                        viewModel.analysisResult.isManualSelection &&
                        viewModel.analysisResult.detectedTopicId == option.topicId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isCurrentSelected ? const Color(0xFFFEF3C7) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            viewModel.selectManualInjury(option);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã chọn thủ công: ${option.label}'),
                                backgroundColor: const Color(0xFF15803D),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrentSelected
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFE2E8F0),
                                width: isCurrentSelected ? 1.6 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isCurrentSelected
                                        ? const Color(0xFFFDE68A)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: isCurrentSelected
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF475569),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.label,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrentSelected
                                              ? const Color(0xFF92400E)
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        option.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrentSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFFD97706), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 9. HỘP THOẠI ĐÁNH GIÁ & PHẢN HỒI AI GỬI VỀ /ADMIN (FEEDBACK LOOP)
  // ===========================================================================
  void _showAiFeedbackDialog(
    BuildContext context,
    UserViewModel viewModel,
    AiAnalysisResultModel result, {
    AiFeedbackType initialType = AiFeedbackType.inaccurate,
  }) {
    AiFeedbackType selectedType = initialType;
    String selectedCategory = initialType == AiFeedbackType.inaccurate
        ? 'YOLO nhận diện nhầm loại tổn thương'
        : 'Chính xác & Hữu ích';
    String? selectedProposedLabel = initialType == AiFeedbackType.inaccurate ? 'Trầy xước ngoài da' : null;

    final commentCtrl = TextEditingController(
      text: initialType == AiFeedbackType.inaccurate
          ? 'YOLO nhận diện nhầm loại tổn thương trên ảnh.'
          : 'Kết quả nhận diện chuẩn xác và hướng dẫn sơ cứu kịp thời.',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isInaccurate = selectedType == AiFeedbackType.inaccurate;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isInaccurate ? Icons.report_problem_rounded : Icons.thumb_up_alt_rounded,
                          color: isInaccurate ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isInaccurate
                                ? 'Báo cáo chẩn đoán AI nghi ngờ'
                                : 'Đánh giá kết quả AI hữu ích',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0D2B6B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ý kiến đánh giá sẽ được lưu trực tiếp vào cơ sở dữ liệu Supabase để quản trị viên theo dõi.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 18),

                    // Lựa chọn Hữu ích hay Không chính xác
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedType = AiFeedbackType.helpful;
                                selectedCategory = 'Chính xác & Hữu ích';
                                selectedProposedLabel = null;
                                commentCtrl.text = 'Kết quả nhận diện chuẩn xác và hữu ích.';
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isInaccurate ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: !isInaccurate ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '👍 Hữu ích / Chuẩn',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: !isInaccurate ? const Color(0xFF166534) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedType = AiFeedbackType.inaccurate;
                                selectedCategory = 'YOLO nhận diện nhầm loại tổn thương';
                                selectedProposedLabel = 'Trầy xước ngoài da';
                                commentCtrl.text = 'YOLO nhận diện nhầm loại tổn thương trên ảnh.';
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isInaccurate ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isInaccurate ? const Color(0xFFFCA5A5) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '⚠️ Không chính xác',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isInaccurate ? const Color(0xFF991B1B) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tóm tắt chẩn đoán hiện tại
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.psychology_outlined, size: 15, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'AI chẩn đoán: ${result.injuryType} (${result.confidencePercent}%) - Vị trí: ${viewModel.selectedLocationLabel}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (isInaccurate) ...[
                      const Text(
                        'Vấn đề bạn quan sát thấy:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          'YOLO nhận diện nhầm loại tổn thương',
                          'Độ tin cậy / vị trí không đúng',
                          'Bỏ sót tổn thương phụ trên ảnh',
                          'Lời khuyên sơ cứu chưa phù hợp',
                          'Lý do khác',
                        ].map((cat) {
                          final isSel = selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : const Color(0xFF334155))),
                            selected: isSel,
                            selectedColor: const Color(0xFFDC2626),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedCategory = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    Text(
                      isInaccurate ? 'Chi tiết góp ý của bạn:' : 'Ghi chú thêm:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Nhập góp ý...',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final commentText = commentCtrl.text.trim();
                            final feedback = AiFeedbackModel(
                              id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
                              analysisId: result.serverAnalysisId,
                              timestamp: DateTime.now(),
                              userDisplayName: viewModel.currentUserName,
                              sourceModel: AiSourceModel.yoloVision,
                              feedbackType: selectedType,
                              issueCategory: selectedCategory,
                              userComment: commentText.isNotEmpty
                                  ? commentText
                                  : (isInaccurate
                                      ? 'YOLO nhận diện nhầm loại tổn thương'
                                      : 'Đánh giá AI hữu ích và chính xác'),
                              userProposedLabel: selectedProposedLabel,
                              detectedWoundSummary: '${result.injuryType} (${result.confidencePercent}%)',
                              woundLocation: viewModel.selectedLocationLabel,
                              painLevel: viewModel.painLevel.label,
                              observedSymptoms: [
                                if (viewModel.isBleeding) 'Đang chảy máu nhiều/liên tục',
                                if (viewModel.hasForeignBody) 'Có dị vật cắm sâu',
                                if (viewModel.hasPusOrInfection) 'Chảy mủ hoặc sưng đỏ tấy',
                              ],
                              imageBytes: result.rawImageBytes,
                              imageFileName: result.imageFileName,
                            );

                            AiFeedbackService.instance.submitFeedback(feedback);
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isInaccurate
                                            ? 'Cảm ơn bạn! Đánh giá đã được ghi nhận về trang /admin để cải thiện mô hình AI.'
                                            : 'Cảm ơn bạn đã gửi đánh giá! Phản hồi tích cực đã được đồng bộ lên Supabase.',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 15),
                          label: Text(
                            isInaccurate ? 'Gửi báo sai' : 'Gửi đánh giá',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInaccurate ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 10. LỚP OVERLAY LOADING KHI ĐANG QUÉT LẠI VỚI ĐỘ TƯƠNG PHẢN
  // ===========================================================================
  Widget _buildReAnalyzingLoadingOverlay(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final int percent = (viewModel.analysisProgress * 100).clamp(0, 100).toInt();

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Đang phân tích lại...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.analysisStatusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: viewModel.analysisProgress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
