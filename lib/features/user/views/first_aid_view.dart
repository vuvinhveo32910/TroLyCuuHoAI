import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/url_launcher_helper.dart';
import '../models/first_aid_models.dart';
import '../viewmodels/user_viewmodel.dart';

class HuongDanSoCuuView extends StatelessWidget {
  const HuongDanSoCuuView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final guide = viewModel.firstAidGuide;
    final ruleResult = guide.ruleResult;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề trang + Nút quay lại
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
              Expanded(
                child: Text(
                  guide.screenTitle,
                  style: TextStyle(
                    fontSize: isMobile ? 19 : 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D2B6B),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. BANNER ĐÁNH GIÁ TỪ RULE ENGINE (Mức độ nghiêm trọng & Hướng xử lý)
          if (ruleResult != null)
            _buildRuleEngineAssessmentCard(context, ruleResult, isMobile: isMobile)
          else
            _buildLegacyStatusBox(guide, isMobile: isMobile),

          const SizedBox(height: 18),

          // 2. KHUNG CHECKLIST DẤU HIỆU CẢNH BÁO (TƯƠNG TÁC THỜI GIAN THỰC VỚI RULE ENGINE)
          _buildWarningSymptomsInteractiveBox(context, viewModel, isMobile: isMobile),

          const SizedBox(height: 22),

          // 3. CÁC BƯỚC SƠ CỨU BAN ĐẦU
          Text(
            guide.stepsSectionTitle,
            style: TextStyle(
              fontSize: isMobile ? 17 : 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D2B6B),
            ),
          ),
          const SizedBox(height: 12),
          _buildFirstAidStepsTimelineCard(guide.steps, isMobile: isMobile),

          const SizedBox(height: 22),

          // 4. NHỮNG ĐIỀU TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM (CHỐNG CHỈ ĐỊNH)
          if (guide.contraindications.isNotEmpty) ...[
            _buildContraindicationsBox(guide.contraindications, isMobile: isMobile),
            const SizedBox(height: 20),
          ],

          // 5. CẢNH BÁO KHI NÀO CẦN ĐẾN CƠ SỞ Y TẾ
          _buildWhenToSeeDoctorRedBox(guide, isMobile: isMobile),

          const SizedBox(height: 22),

          // 6. NGUỒN (LINK) TRÍCH XUẤT HƯỚNG DẪN CHI TIẾT
          _buildMedicalSourcesSection(context, guide.sourceLinks, isMobile: isMobile),

          const SizedBox(height: 26),

          // Nút quay lại
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerRight,
            child: _buildBackToImageAnalysisButton(
              context,
              guide.backButtonLabel,
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ hiển thị đánh giá thông minh từ Rule Engine
  Widget _buildRuleEngineAssessmentCard(
    BuildContext context,
    RuleEvaluationResult result, {
    bool isMobile = false,
  }) {
    final severity = result.finalSeverity;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: severity.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: severity.borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0D2B6B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: severity.color, width: 2),
                ),
                child: Icon(severity.icon, color: severity.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: severity.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'RULE ENGINE ĐÁNH GIÁ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          severity.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: severity.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.summaryTitle,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: severity.color,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.statusDescription,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Khung tương tác người dùng cung cấp dấu hiệu để Rule Engine đánh giá lại
  Widget _buildWarningSymptomsInteractiveBox(
    BuildContext context,
    UserViewModel viewModel, {
    bool isMobile = false,
  }) {
    final ctx = viewModel.injuryContext;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_folder_outlined, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dấu hiệu cảnh báo kèm theo (Tích chọn để Rule Engine điều chỉnh hướng dẫn):',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => viewModel.resetWarningSymptoms(),
                child: const Text('Đặt lại', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Chảy máu nhiều / Không cầm',
                isSelected: ctx.isBleedingHeavy,
                onSelected: (val) =>
                    viewModel.toggleWarningSymptom(isBleedingHeavy: val),
              ),
              _buildFilterChip(
                label: 'Vết thương sâu / Có dị vật cắm vào',
                isSelected: ctx.hasDeepWoundOrForeignBody,
                onSelected: (val) =>
                    viewModel.toggleWarningSymptom(hasDeepWoundOrForeignBody: val),
              ),
              _buildFilterChip(
                label: 'Bỏng diện rộng / Hóa chất / Điện',
                isSelected: ctx.isLargeAreaBurnOrChemical,
                onSelected: (val) =>
                    viewModel.toggleWarningSymptom(isLargeAreaBurnOrChemical: val),
              ),
              _buildFilterChip(
                label: 'Đau dữ dội / Nghi gãy xương',
                isSelected: ctx.isSeverePainOrFractureSuspected,
                onSelected: (val) => viewModel.toggleWarningSymptom(
                    isSeverePainOrFractureSuspected: val),
              ),
              _buildFilterChip(
                label: 'Sưng mủ / Sốt (Nhiễm trùng)',
                isSelected: ctx.hasSignsOfInfection,
                onSelected: (val) =>
                    viewModel.toggleWarningSymptom(hasSignsOfInfection: val),
              ),
              _buildFilterChip(
                label: 'Nạn nhân là Trẻ nhỏ hoặc Người cao tuổi',
                isSelected: ctx.isChildOrElderly,
                onSelected: (val) =>
                    viewModel.toggleWarningSymptom(isChildOrElderly: val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFFB91C1C) : const Color(0xFF334155),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      selectedColor: const Color(0xFFFEE2E2),
      checkmarkColor: const Color(0xFFB91C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      onSelected: onSelected,
    );
  }

  /// Khung Các bước sơ cứu dạng timeline
  Widget _buildFirstAidStepsTimelineCard(
    List<FirstAidStepModel> steps, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFBFDBFE),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Khung những điều TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM (chống chỉ định)
  Widget _buildContraindicationsBox(
    List<String> contraindications, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFFEA580C), size: 22),
              SizedBox(width: 10),
              Text(
                'Những điều TUYỆT ĐỐI TRÁNH khi sơ cứu:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...contraindications.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✖ ', style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF7C2D12), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khung cảnh báo khi nào cần đến cơ sở y tế
  Widget _buildWhenToSeeDoctorRedBox(
    FirstAidGuideModel guide, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Text(
                guide.redWarningTitle,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...guide.redWarningBullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 16)),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF7F1D1D), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mục Nguồn (link) đường dẫn nguồn trích xuất hướng dẫn chi tiết
  Widget _buildMedicalSourcesSection(
    BuildContext context,
    List<MedicalSourceLink> sourceLinks, {
    bool isMobile = false,
  }) {
    if (sourceLinks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 8),
              Text(
                'Nguồn trích xuất hướng dẫn y khoa chi tiết:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...sourceLinks.map(
            (src) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  UrlLauncherHelper.launchWebUrl(context, src.url, fallbackTitle: src.title);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                            children: [
                              TextSpan(
                                text: '${src.organization}: ',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                              ),
                              TextSpan(
                                text: src.title,
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyStatusBox(
    FirstAidGuideModel guide, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide.statusBoxTitle,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
                ),
                Text(
                  guide.severityText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToImageAnalysisButton(
    BuildContext context,
    String label, {
    bool isMobile = false,
  }) {
    return OutlinedButton.icon(
      onPressed: () => context.read<UserViewModel>().onBackToImageAnalysisPressed(),
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0D2B6B),
        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.3),
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isMobile ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
