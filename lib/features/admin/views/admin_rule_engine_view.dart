import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/rule_engine/rule_models.dart';
import '../viewmodels/admin_management_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_pagination_footer.dart';

// =============================================================================
// 3. VIEW QUẢN LÝ RULE ENGINE (TÙY BIẾN SÂU 4 PHẠM TRÙ VẾT THƯƠNG)
// =============================================================================
class AdminRuleEngineView extends StatelessWidget {
  const AdminRuleEngineView({super.key});

  static const Map<String, String> categoryLabels = {
    'all': 'Áp dụng chung',
    'abrasion': 'Trầy xước',
    'cut_laceration': 'Vết cắt / rách',
    'burn': 'Bỏng',
    'bruise': 'Bầm tím',
  };

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final allRules = viewModel.adminRuleList;
    final rules = viewModel.filteredAdminRules;
    final paginatedRules = viewModel.paginatedAdminRules;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final activeCount = allRules.where((r) => r.isEnabled).length;
    final emergencyCount = allRules.where((r) => r.severity == RuleSeverityLevel.emergency).length;
    final warningCount = allRules.where((r) => r.severity == RuleSeverityLevel.warning).length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER & THAO TÁC HỆ THỐNG
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Quản lý Rule Engine Sơ cứu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bộ máy quy tắc suy luận lâm sàng – Đánh giá tình huống dựa trên triệu chứng, mức độ đau & liên kết phác đồ Knowledge Base',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showResetRulesConfirmationDialog(context, viewModel),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Khôi phục chuẩn y tế'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showDeepEditRuleDialog(context, viewModel),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Thêm quy tắc mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Banner phân biệt vai trò: Rule Engine vs Knowledge Base
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.tune_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bộ máy Quy tắc Lâm sàng Động (Rule Engine) – Xử lý tình huống theo thời gian thực',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Rule Engine đánh giá tình trạng thực tế của nạn nhân dựa trên 3 triệu chứng (chảy máu, dị vật, sưng mủ), cảm giác đau (Không đau/Đau nhẹ/Đau nặng) và loại vết thương. Rule Engine phân loại mức độ khẩn cấp (Nhẹ/Cần chú ý/Khẩn cấp), đưa ra việc cấm kỵ và liên kết tới Phác đồ chuẩn tương ứng trong Knowledge Base.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. THẺ THỐNG KÊ NHANH CÁC QUY TẮC
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final statCards = [
                _buildStatMetricCard('Tổng quy tắc', '${allRules.length}', Icons.rule_rounded, const Color(0xFF2563EB)),
                _buildStatMetricCard('Đang kích hoạt', '$activeCount', Icons.check_circle_rounded, const Color(0xFF16A34A)),
                _buildStatMetricCard('Quy tắc Khẩn cấp', '$emergencyCount', Icons.emergency_rounded, const Color(0xFFDC2626)),
                _buildStatMetricCard('Cần chú ý', '$warningCount', Icons.warning_amber_rounded, const Color(0xFFD97706)),
              ];

              if (isWide) {
                return Row(
                  children: statCards.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: w))).toList(),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: statCards.map((w) => SizedBox(width: (constraints.maxWidth - 10) / 2, child: w)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. THANH FILTER CHIPS THEO 4 PHẠM TRÙ VẾT THƯƠNG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilterChip(context, viewModel, 'all', 'Tất cả (${allRules.length})'),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(context, viewModel, 'abrasion', 'Trầy xước'),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(context, viewModel, 'cut_laceration', 'Vết cắt / rách'),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(context, viewModel, 'burn', 'Bỏng'),
                const SizedBox(width: 8),
                _buildCategoryFilterChip(context, viewModel, 'bruise', 'Bầm tím'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. DANH SÁCH QUY TẮC (CARD HIỂN THỊ CHI TIẾT & HÀNH ĐỘNG TÙY BIẾN)
          if (rules.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Không có quy tắc nào thuộc phạm trù này.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paginatedRules.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final rule = paginatedRules[index];
                    final severity = rule.severity;
                    final categoryName = categoryLabels[rule.targetInjuryTypeId] ?? rule.targetInjuryTypeId;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: rule.isEnabled
                          ? (severity == RuleSeverityLevel.emergency
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFCBD5E1))
                          : const Color(0xFFE2E8F0),
                      width: rule.isEnabled ? 1.5 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080D2B6B),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng Header của Rule
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              rule.code,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: severity.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: severity.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(severity.icon, size: 12, color: severity.color),
                                const SizedBox(width: 4),
                                Text(
                                  severity.label.split(' - ').first,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: severity.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            rule.isEnabled ? 'Kích hoạt' : 'Đang tắt',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: rule.isEnabled ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: rule.isEnabled,
                            activeTrackColor: const Color(0xFF2563EB),
                            onChanged: (_) => viewModel.toggleAdminRule(rule.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tên luật
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D2B6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule.description,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                      ),
                      const SizedBox(height: 12),

                      // Dấu hiệu lâm sàng kích hoạt (Khớp 100% với giao diện quét ảnh & kết quả)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (rule.requireBleedingHeavy)
                            _buildConditionBadge('🩸 Vết thương đang chảy máu', const Color(0xFFDC2626)),
                          if (rule.requireForeignBody)
                            _buildConditionBadge('📌 Có dị vật cắm vào', const Color(0xFFB45309)),
                          if (rule.requireInfection)
                            _buildConditionBadge('⚠️ Chảy mủ / Sưng đỏ tấy', const Color(0xFFC026D3)),
                          if (rule.requiredPainLevel == PainLevel.severe || rule.requireSeverePainOrFracture)
                            _buildConditionBadge('⚡ Cảm giác Đau nặng (7-10)', const Color(0xFFDC2626))
                          else if (rule.requiredPainLevel == PainLevel.mild)
                            _buildConditionBadge('⚡ Đau nhẹ trở lên (1-10)', const Color(0xFFD97706)),
                          if (rule.requireMultipleInjuries)
                            _buildConditionBadge('🩹 Đa tổn thương (2-3 vết thương)', const Color(0xFF2563EB)),
                          if (!rule.requireBleedingHeavy &&
                              !rule.requireForeignBody &&
                              !rule.requireInfection &&
                              rule.requiredPainLevel == null &&
                              !rule.requireMultipleInjuries &&
                              !rule.requireLargeBurnOrChemical &&
                              !rule.requireSeverePainOrFracture)
                            _buildConditionBadge('✅ Áp dụng tiêu chuẩn', const Color(0xFF16A34A)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Khung hành động sơ cứu
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hành động sơ cứu khuyến nghị:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...rule.primaryActions.map(
                              (act) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        act,
                                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Khung chống chỉ định nếu có
                      if (rule.contraindications.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.block_rounded, size: 14, color: Color(0xFFDC2626)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tuyệt đối không được làm:',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...rule.contraindications.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text('• $c', style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Khuyến nghị y tế
                      if (rule.emergencyRecommendation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Khuyến cáo: ${rule.emergencyRecommendation}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),

                      // Hàng nút hành động: Phác đồ Knowledge Base + Tùy biến + Xóa quy tắc
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Phác đồ liên kết từ Knowledge Base
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 15, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Phác đồ Knowledge Base: $categoryName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E40AF),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () => _showDeepEditRuleDialog(context, viewModel, existingRule: rule),
                                icon: const Icon(Icons.tune_rounded, size: 15),
                                label: const Text('Tùy biến'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => _showDeleteRuleConfirmationDialog(context, viewModel, rule),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                tooltip: 'Xóa quy tắc này',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            buildAdminPaginationFooter(
              currentPage: viewModel.currentRulePage,
              totalPages: viewModel.totalRulePages,
              totalItems: rules.length,
              pageSize: AdminManagementViewModel.rulePageSize,
              itemLabel: 'quy tắc lâm sàng',
              onPageSelected: (page) => viewModel.selectRulePage(page),
              onPrevious: () => viewModel.goToPreviousRulePage(),
              onNext: () => viewModel.goToNextRulePage(),
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    ),
  );
}

  void _showDeleteRuleConfirmationDialog(
    BuildContext context,
    AdminViewModel viewModel,
    FirstAidRule rule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xóa quy tắc ${rule.code}?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa quy tắc "${rule.name}" (${rule.code}) khỏi Rule Engine không?\n\nBạn có thể bấm "Khôi phục chuẩn y tế" ở phía trên bất cứ lúc nào để phục hồi.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.deleteAdminRule(rule.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa quy tắc ${rule.code} khỏi hệ thống.'),
                  backgroundColor: const Color(0xFFDC2626),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa quy tắc'),
          ),
        ],
      ),
    );
  }

  static Widget _buildAdminRuleCheckboxTile({
    required String title,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: activeColor,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(
    BuildContext context,
    AdminViewModel viewModel,
    String categoryId,
    String label,
  ) {
    final isSelected = viewModel.selectedRuleCategoryFilter == categoryId;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => viewModel.selectRuleCategoryFilter(categoryId),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildConditionBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // ===========================================================================
  // MODAL TÙY BIẾN SÂU QUY TẮC RULE ENGINE
  // ===========================================================================
  void _showDeepEditRuleDialog(
    BuildContext context,
    AdminViewModel viewModel, {
    FirstAidRule? existingRule,
  }) {
    final isEditing = existingRule != null;
    final codeController = TextEditingController(
      text: existingRule?.code ?? 'RULE-CUSTOM-0${viewModel.adminRuleList.length + 1}',
    );
    final nameController = TextEditingController(text: existingRule?.name ?? '');
    final descController = TextEditingController(text: existingRule?.description ?? '');
    final emergencyRecController = TextEditingController(
      text: existingRule?.emergencyRecommendation ?? 'Đến ngay cơ sở y tế gần nhất nếu có dấu hiệu nặng lên.',
    );

    String targetInjuryTypeId = existingRule?.targetInjuryTypeId ?? 'abrasion';
    RuleSeverityLevel severity = existingRule?.severity ?? RuleSeverityLevel.normal;

    bool requireBleedingHeavy = existingRule?.requireBleedingHeavy ?? false;
    bool requireForeignBody = existingRule?.requireForeignBody ?? false;
    bool requireInfection = existingRule?.requireInfection ?? false;
    PainLevel? requiredPainLevel = existingRule?.requiredPainLevel ??
        (existingRule?.requireSeverePainOrFracture == true ? PainLevel.severe : null);
    bool requireMultipleInjuries = existingRule?.requireMultipleInjuries ?? false;
    bool requireLargeBurnOrChemical = existingRule?.requireLargeBurnOrChemical ?? false;
    bool requireSeverePainOrFracture = existingRule?.requireSeverePainOrFracture ?? false;

    final List<TextEditingController> actionControllers = (existingRule?.primaryActions ?? [
      'Rửa sạch vùng tổn thương bằng nước muối sinh lý.',
      'Sát khuẩn nhẹ nhàng bằng dung dịch chuyên dụng.',
    ]).map((a) => TextEditingController(text: a)).toList();

    final List<TextEditingController> contraControllers = (existingRule?.contraindications ?? [
      'Không tự ý bôi các chất lạ hoặc thuốc chưa rõ nguồn gốc.',
    ]).map((c) => TextEditingController(text: c)).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Tùy biến chuyên sâu: ${existingRule.code}' : 'Thêm quy tắc mới cho Rule Engine',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Mã & Tên luật
                      Row(
                        children: [
                          SizedBox(
                            width: 170,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mã quy tắc:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: codeController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tên quy tắc:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'VD: Bỏng diện rộng, Trầy xước nhẹ...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Phạm trù áp dụng (4 phạm trù cốt lõi)
                      const Text(
                        'Phạm trù tổn thương áp dụng:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: categoryLabels.entries.map((entry) {
                          final isSelected = targetInjuryTypeId == entry.key;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: (_) => setModalState(() => targetInjuryTypeId = entry.key),
                            label: Text(entry.value),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                            selectedColor: const Color(0xFF2563EB),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 3. Mức độ nghiêm trọng y tế
                      const Text(
                        'Mức độ đánh giá y tế:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: RuleSeverityLevel.values.map((sev) {
                          final isSelected = severity == sev;
                          return ChoiceChip(
                            selected: isSelected,
                            onSelected: (_) => setModalState(() => severity = sev),
                            avatar: Icon(sev.icon, size: 14, color: isSelected ? Colors.white : sev.color),
                            label: Text(sev.label),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : sev.color,
                            ),
                            selectedColor: sev.color,
                            backgroundColor: sev.backgroundColor,
                            side: BorderSide(color: sev.borderColor),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // 4. Điều kiện lâm sàng kích hoạt (Khớp 100% với giao diện quét ảnh & kết quả)
                      const Text(
                        'Điều kiện lâm sàng kích hoạt quy tắc:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Khớp trực tiếp với các triệu chứng quan sát, mức độ đau và phát hiện trên giao diện người dùng:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3 Checkbox lâm sàng khớp giao diện người dùng
                            _buildAdminRuleCheckboxTile(
                              title: '🩸 Vết thương đang chảy máu (chảy nhiều hoặc liên tục)',
                              value: requireBleedingHeavy,
                              activeColor: const Color(0xFFDC2626),
                              onChanged: (v) => setModalState(() => requireBleedingHeavy = v ?? false),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            _buildAdminRuleCheckboxTile(
                              title: '📌 Dị vật cắm vào vết thương (kim loại, dằm, thủy tinh...)',
                              value: requireForeignBody,
                              activeColor: const Color(0xFFB45309),
                              onChanged: (v) => setModalState(() => requireForeignBody = v ?? false),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            _buildAdminRuleCheckboxTile(
                              title: '⚠️ Vết thương chảy mủ / Sưng đỏ tấy (dấu hiệu nhiễm trùng)',
                              value: requireInfection,
                              activeColor: const Color(0xFFC026D3),
                              onChanged: (v) => setModalState(() => requireInfection = v ?? false),
                            ),
                            const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            _buildAdminRuleCheckboxTile(
                              title: '🩹 Phát hiện từ 2-3 vết thương cùng lúc trên ảnh (Đa tổn thương)',
                              value: requireMultipleInjuries,
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (v) => setModalState(() => requireMultipleInjuries = v ?? false),
                            ),
                            const SizedBox(height: 10),

                            // Điều kiện mức độ đau
                            const Text(
                              'Yêu cầu cảm giác đau (khớp thanh gạt 3 mức):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                ChoiceChip(
                                  label: const Text('Bất kỳ mức đau'),
                                  selected: requiredPainLevel == null,
                                  onSelected: (_) => setModalState(() => requiredPainLevel = null),
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: requiredPainLevel == null ? Colors.white : const Color(0xFF334155),
                                    fontWeight: requiredPainLevel == null ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Từ Đau nhẹ trở lên (1-10)'),
                                  selected: requiredPainLevel == PainLevel.mild,
                                  onSelected: (_) => setModalState(() => requiredPainLevel = PainLevel.mild),
                                  selectedColor: const Color(0xFFD97706),
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: requiredPainLevel == PainLevel.mild ? Colors.white : const Color(0xFF334155),
                                    fontWeight: requiredPainLevel == PainLevel.mild ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Chỉ khi Đau nặng (7-10)'),
                                  selected: requiredPainLevel == PainLevel.severe,
                                  onSelected: (_) => setModalState(() => requiredPainLevel = PainLevel.severe),
                                  selectedColor: const Color(0xFFDC2626),
                                  labelStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: requiredPainLevel == PainLevel.severe ? Colors.white : const Color(0xFF334155),
                                    fontWeight: requiredPainLevel == PainLevel.severe ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Mô tả quy tắc
                      const Text('Mô tả quy tắc:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Mô tả ngắn gọn khi nào nên áp dụng luật này...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. Hành động sơ cứu ưu tiên (Thêm / Xóa / Sửa từng bước)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hành động sơ cứu ưu tiên:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                actionControllers.add(TextEditingController(text: 'Bước mới...'));
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Thêm bước'),
                          ),
                        ],
                      ),
                      ...List.generate(actionControllers.length, (idx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 11,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text('${idx + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: actionControllers[idx],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    actionControllers.removeAt(idx);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                tooltip: 'Xóa bước này',
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),

                      // 7. Chống chỉ định (Những việc TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Chống chỉ định (Tuyệt đối không làm):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626))),
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                contraControllers.add(TextEditingController(text: 'Điều cấm mới...'));
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFDC2626)),
                            label: const Text('Thêm điều cấm', style: TextStyle(color: Color(0xFFDC2626))),
                          ),
                        ],
                      ),
                      ...List.generate(contraControllers.length, (idx) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.block_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: contraControllers[idx],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setModalState(() {
                                    contraControllers.removeAt(idx);
                                  });
                                },
                                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                tooltip: 'Xóa điều cấm này',
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),

                      // 8. Khuyến cáo cơ sở y tế
                      const Text('Khuyến cáo y tế / Khi nào cần đi viện:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emergencyRecController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Cần đi viện khi nào...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _showDeleteRuleConfirmationDialog(context, viewModel, existingRule);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 18),
                    label: const Text('Xóa quy tắc này', style: TextStyle(color: Color(0xFFDC2626))),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;

                    final acts = actionControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    final contras = contraControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    if (isEditing) {
                      final updatedRule = existingRule.copyWith(
                        code: codeController.text.trim(),
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        severity: severity,
                        targetInjuryTypeId: targetInjuryTypeId,
                        requireBleedingHeavy: requireBleedingHeavy,
                        requireForeignBody: requireForeignBody,
                        requireInfection: requireInfection,
                        requiredPainLevel: requiredPainLevel,
                        requireMultipleInjuries: requireMultipleInjuries,
                        requireLargeBurnOrChemical: requireLargeBurnOrChemical,
                        requireSeverePainOrFracture: requireSeverePainOrFracture,
                        linkedKnowledgeTopicId: targetInjuryTypeId,
                        primaryActions: acts.isNotEmpty ? acts : ['Sơ cứu cẩn thận'],
                        contraindications: contras,
                        emergencyRecommendation: emergencyRecController.text.trim(),
                      );
                      viewModel.updateAdminRule(updatedRule);
                    } else {
                      final newRule = FirstAidRule(
                        id: 'rule_custom_${DateTime.now().millisecondsSinceEpoch}',
                        code: codeController.text.trim(),
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        severity: severity,
                        targetInjuryTypeId: targetInjuryTypeId,
                        requireBleedingHeavy: requireBleedingHeavy,
                        requireForeignBody: requireForeignBody,
                        requireInfection: requireInfection,
                        requiredPainLevel: requiredPainLevel,
                        requireMultipleInjuries: requireMultipleInjuries,
                        requireLargeBurnOrChemical: requireLargeBurnOrChemical,
                        requireSeverePainOrFracture: requireSeverePainOrFracture,
                        linkedKnowledgeTopicId: targetInjuryTypeId,
                        condition: (ctx) => true,
                        primaryActions: acts.isNotEmpty ? acts : ['Sơ cứu cẩn thận'],
                        contraindications: contras,
                        emergencyRecommendation: emergencyRecController.text.trim(),
                      );
                      viewModel.addAdminRule(newRule);
                    }
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Đã lưu thay đổi quy tắc!' : 'Đã thêm quy tắc mới vào Rule Engine!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo quy tắc'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResetRulesConfirmationDialog(BuildContext context, AdminViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Khôi phục quy tắc chuẩn y tế?'),
        content: const Text(
          'Thao tác này sẽ đặt lại toàn bộ quy tắc Rule Engine về mặc định chuẩn y tế (Bộ Y Tế / WHO) cho 4 phạm trù vết thương.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              viewModel.resetRulesToDefault();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã khôi phục Rule Engine về mặc định chuẩn y tế!')),
              );
            },
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }
}


