import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/rule_engine/rule_models.dart';
import '../models/image_analysis_models.dart';
import '../viewmodels/user_viewmodel.dart';
import 'widgets/user_painters.dart';

class PhanTichAnhView extends StatelessWidget {
  const PhanTichAnhView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final spec = viewModel.uploadSpec;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () {
          context.read<UserViewModel>().onPasteImagePressed(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () {
          context.read<UserViewModel>().onPasteImagePressed(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 18 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isMobile) ...[
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              context.read<UserViewModel>().navigateBack(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0D2B6B),
                            size: 22,
                          ),
                          tooltip: 'Quay lại',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            hoverColor: const Color(0xFFE2E8F0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          spec.screenTitle,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D2B6B),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Nếu đã nạp ảnh vào (Staged): Hiển thị khung xem trước và nút Bắt đầu quét
                  if (viewModel.hasStagedImage)
                    _buildStagedImagePreviewArea(context, viewModel, isMobile: isMobile)
                  else ...[
                    // Chưa có ảnh: Hiển thị khung kéo thả / chọn tệp
                    _buildDashedUploadArea(context, viewModel, spec, isMobile: isMobile),
                    const SizedBox(height: 18),
                    _buildClinicalCheckboxesCard(context, viewModel, isMobile: isMobile),
                  ],

                  SizedBox(height: isMobile ? 20 : 28),
                  _buildOrCaptureDivider(spec.dividerText),
                  SizedBox(height: isMobile ? 18 : 24),

                  if (isMobile)
                    _buildCameraButton(
                      context,
                      viewModel,
                      spec.cameraButtonLabel,
                      isMobile: true,
                    )
                  else
                    Center(
                      child: _buildCameraButton(
                        context,
                        viewModel,
                        spec.cameraButtonLabel,
                      ),
                    ),
                  SizedBox(height: isMobile ? 22 : 32),
                  _buildBottomWarningNotice(spec, isMobile: isMobile),
                ],
              ),
            ),

            // Lớp phủ hiển thị trạng thái khi AI đang quét ảnh kèm Progress Bar
            // DÙNG Positioned.fill ĐỂ PHỦ KÍN 100% TOÀN MÀN HÌNH KHÔNG BỊ TRÔI HOẶC LỖI GIAO DIỆN
            if (viewModel.isAnalyzing)
              Positioned.fill(
                child: _buildAnalyzingLoadingOverlay(context, viewModel),
              ),
          ],
        ),
      ),
    );
  }

  /// Khung hiển thị ảnh xem trước khi người dùng vừa chọn/dán xong, kèm 3 checkbox và nút "Bắt đầu quét AI"
  Widget _buildStagedImagePreviewArea(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final imageBytes = viewModel.stagedImageBytes;
    final imageName = viewModel.stagedImageName ?? 'Ảnh được chọn';
    final imageSizeKb = ((imageBytes?.length ?? 0) / 1024).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D2B6B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh đã nạp thành công',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                    Text(
                      '$imageName ($imageSizeKb KB)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => viewModel.clearStagedImage(),
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                tooltip: 'Hủy ảnh này',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Khung ảnh xem trước (Đã đổi nền sáng trung tính, loại bỏ hoàn toàn khung đen)
          Container(
            height: isMobile ? 240 : 340,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes != null
                ? Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),

          // 3 CHECKBOX QUAN SÁT TÌNH TRẠNG VẾT THƯƠNG (Dị vật cắm vào, chảy máu, chảy mủ)
          _buildClinicalCheckboxesCard(context, viewModel, isMobile: isMobile),
          const SizedBox(height: 18),

          // Hàng nút hành động: Nút QUÉT AI + Nút đổi ảnh khác
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => viewModel.onSelectImageFromFilePressed(context),
                        icon: const Icon(Icons.folder_open_rounded, size: 18),
                        label: const Text('Chọn ảnh khác'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => viewModel.onCaptureFromCameraPressed(context),
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: const Text('Chụp lại bằng Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => viewModel.onPasteImagePressed(context),
                        icon: const Icon(Icons.content_paste_rounded, size: 18),
                        label: const Text('Dán ảnh khác (Ctrl+V)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // NÚT CHÍNH: BẮT ĐẦU QUÉT AI
              ElevatedButton.icon(
                onPressed: () => viewModel.startAnalysis(context),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text('Bắt đầu quét phân tích AI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Nút gạt 3 mức cảm giác đau: Không đau -> Đau nhẹ -> Đau nặng
  Widget _buildPainLevelSelector(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final currentLevel = viewModel.painLevel;
    final int activeIndex = currentLevel == PainLevel.none ? 0 : (currentLevel == PainLevel.mild ? 1 : 2);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 19),
              const SizedBox(width: 8),
              const Text(
                'Cảm giác đau hiện tại:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: currentLevel.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: currentLevel.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(currentLevel.icon, size: 14, color: currentLevel.color),
                    const SizedBox(width: 4),
                    Text(
                      currentLevel.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: currentLevel.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nút gạt 3 nấc: Không đau (0) -> Đau nhẹ (1) -> Đau nặng (2)
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: currentLevel.color,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: currentLevel.color,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayColor: currentLevel.color.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: const Color(0xFF94A3B8),
            ),
            child: Slider(
              value: activeIndex.toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: (val) {
                viewModel.setPainLevelFromIndex(val.round());
              },
            ),
          ),

          // 3 nhãn tương tác có thể bấm trực tiếp
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => viewModel.setPainLevel(PainLevel.none),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: activeIndex == 0 ? const Color(0xFFDCFCE7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: activeIndex == 0 ? const Color(0xFF86EFAC) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Không đau',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                            color: activeIndex == 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '0/10',
                          style: TextStyle(
                            fontSize: 10,
                            color: activeIndex == 0 ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => viewModel.setPainLevel(PainLevel.mild),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: activeIndex == 1 ? const Color(0xFFFEF3C7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: activeIndex == 1 ? const Color(0xFFFCD34D) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Đau nhẹ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                            color: activeIndex == 1 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '1 - 4/10',
                          style: TextStyle(
                            fontSize: 10,
                            color: activeIndex == 1 ? const Color(0xFFB45309) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => viewModel.setPainLevel(PainLevel.severe),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: activeIndex == 2 ? const Color(0xFFFEE2E2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: activeIndex == 2 ? const Color(0xFFFCA5A5) : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Đau nặng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: activeIndex == 2 ? FontWeight.w800 : FontWeight.w600,
                            color: activeIndex == 2 ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '7 - 10/10',
                          style: TextStyle(
                            fontSize: 10,
                            color: activeIndex == 2 ? const Color(0xFFB91C1C) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentLevel.description,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Khung Cảm giác đau 3 nấc + 3 Checkbox tình trạng vết thương
  Widget _buildClinicalCheckboxesCard(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nút gạt 3 mức cảm giác đau (Không đau - Đau nhẹ - Đau nặng)
          _buildPainLevelSelector(context, viewModel, isMobile: isMobile),

          Row(
            children: const [
              Icon(Icons.checklist_rtl_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tình trạng quan sát kèm theo tại vết thương (nếu có):',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSingleCheckboxTile(
            title: 'Dị vật cắm vào vết thương (kim loại, dằm, thủy tinh...)',
            subtitle: 'Rule Engine sẽ cảnh báo KHÔNG được tự ý rút dị vật ra',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFEA580C),
            value: viewModel.hasForeignBody,
            onChanged: (val) => viewModel.toggleHasForeignBody(val),
          ),
          const SizedBox(height: 8),
          _buildSingleCheckboxTile(
            title: 'Vết thương đang chảy máu (chảy nhiều hoặc liên tục)',
            subtitle: 'Hệ thống sẽ ưu tiên các bước cầm máu khẩn cấp',
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFFDC2626),
            value: viewModel.isBleeding,
            onChanged: (val) => viewModel.toggleIsBleeding(val),
          ),
          const SizedBox(height: 8),
          _buildSingleCheckboxTile(
            title: 'Vết thương chảy mủ / Sưng đỏ tấy (dấu hiệu nhiễm trùng)',
            subtitle: 'Hướng dẫn sát trùng chuyên sâu và khuyến cáo khám y tế',
            icon: Icons.healing_outlined,
            iconColor: const Color(0xFFD97706),
            value: viewModel.hasPusOrInfection,
            onChanged: (val) => viewModel.toggleHasPusOrInfection(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleCheckboxTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: value ? const Color(0xFFEFF6FF) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
              width: value ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: value ? FontWeight.w700 : FontWeight.w600,
                        color: value ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashedUploadArea(
    BuildContext context,
    UserViewModel viewModel,
    AiUploadSpecModel spec, {
    bool isMobile = false,
  }) {
    return CustomPaint(
      painter: const DashedBorderPainter(
        color: Color(0xFFBFDBFE),
        strokeWidth: 1.8,
        dashLength: 7.0,
        gapLength: 5.0,
        borderRadius: 14.0,
      ),
      child: Material(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => viewModel.onSelectImageFromFilePressed(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 24,
              vertical: isMobile ? 28 : 44,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 68,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: const [
                      Icon(
                        Icons.cloud_outlined,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      Positioned(
                        bottom: 10,
                        child: Icon(
                          Icons.add,
                          size: 26,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D2B6B),
                    ),
                    children: [
                      TextSpan(text: spec.dropzonePrefixText),
                      TextSpan(
                        text: spec.dropzoneActionText,
                        style: const TextStyle(color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hỗ trợ: Trầy xước, Vết cắt, Bỏng, Bầm tím và Ảnh da bình thường',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 12.5 : 13.5,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => viewModel.onSelectImageFromFilePressed(context),
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: Text(spec.selectButtonLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 28,
                          vertical: isMobile ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => viewModel.onPasteImagePressed(context),
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: const Text('Dán ảnh (Ctrl+V)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD), width: 1.4),
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 22,
                          vertical: isMobile ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrCaptureDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }

  Widget _buildCameraButton(
    BuildContext context,
    UserViewModel viewModel,
    String label, {
    bool isMobile = false,
  }) {
    return OutlinedButton(
      onPressed: () => viewModel.onCaptureFromCameraPressed(context),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D2B6B),
        side: const BorderSide(color: Color(0xFFD8E3F2), width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 32,
          vertical: isMobile ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.photo_camera_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D2B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomWarningNotice(
    AiUploadSpecModel spec, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Phạm vi nhận diện AI:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B6B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hệ thống tập trung nhận diện 4 nhóm thương tổn ngoài da: Trầy xước, Vết cắt/rách, Bỏng, Bầm tím và ảnh da bình thường (tránh ảnh không liên quan).',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// THIẾT KẾ LẠI TOÀN BỘ GIAO DIỆN PROGRESS BAR QUÉT AI:
  /// Phủ kín toàn màn hình với BackdropFilter blur mờ, không bao giờ bị lệch hay trôi giao diện
  Widget _buildAnalyzingLoadingOverlay(
    BuildContext context,
    UserViewModel viewModel,
  ) {
    final int percent = (viewModel.analysisProgress * 100).clamp(0, 100).toInt();
    final stagedBytes = viewModel.stagedImageBytes;

    return Container(
      color: Colors.white.withValues(alpha: 0.85),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Container(
            width: 380,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x380D2B6B),
                  blurRadius: 36,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vòng tròn quét AI với ảnh thumbnail thu nhỏ
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF93C5FD), width: 2.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: stagedBytes != null
                          ? Image.memory(
                              stagedBytes,
                              fit: BoxFit.cover,
                              cacheWidth: 160,
                              cacheHeight: 160,
                            )
                          : const Icon(Icons.center_focus_strong, color: Color(0xFF2563EB), size: 36),
                    ),
                    const SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'AI Đang Quét Hình Ảnh...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Phân loại: Trầy xước, Vết cắt, Bỏng, Bầm tím, Da lành',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),

                // THANH TIẾN TRÌNH PROGRESS BAR THIẾT KẾ MỚI
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: viewModel.analysisProgress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ phân tích:',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thông báo trạng thái theo thời gian thực
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          viewModel.analysisStatusMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
