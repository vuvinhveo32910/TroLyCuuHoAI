import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/rule_engine/rule_models.dart';
import '../../../core/url_launcher_helper.dart';
import '../models/admin_management_models.dart';
import '../viewmodels/admin_management_viewmodel.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_pagination_footer.dart';

// =============================================================================
// 1. VIEW QUẢN LÝ KNOWLEDGE BASE (Tùy chỉnh sâu kiến thức & phác đồ sơ cứu)
// =============================================================================
class AdminKnowledgeBaseView extends StatefulWidget {
  const AdminKnowledgeBaseView({super.key});

  @override
  State<AdminKnowledgeBaseView> createState() => _AdminKnowledgeBaseViewState();
}

class _AdminKnowledgeBaseViewState extends State<AdminKnowledgeBaseView> {
  int _selectedTab = 0; // 0: Cẩm nang bài viết sơ cứu, 1: Nguồn trích xuất y khoa chi tiết

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final articles = viewModel.filteredKnowledgeArticles;
    final paginatedArticles = viewModel.paginatedKnowledgeArticles;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(context, viewModel, isMobile),
          const SizedBox(height: 16),
          _buildTabSelector(viewModel),
          const SizedBox(height: 16),
          if (_selectedTab == 0) ...[
            _buildArticlesTab(context, viewModel, articles, paginatedArticles, isMobile),
          ] else ...[
            _buildMedicalSourcesTab(context, viewModel, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicFilterChip(
    BuildContext context,
    AdminViewModel viewModel,
    String topicId,
    String label,
  ) {
    final isSelected = viewModel.selectedInjuryTopicFilter == topicId;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFEFF6FF),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => viewModel.setSelectedInjuryTopicFilter(topicId),
    );
  }

  Widget _buildArticleItemCard(
    BuildContext context,
    AdminViewModel viewModel,
    KnowledgeArticleModel article,
  ) {
    // Màu badge theo phạm trù vết thương
    Color topicBgColor = const Color(0xFFEFF6FF);
    Color topicTextColor = const Color(0xFF2563EB);
    IconData topicIcon = Icons.healing_rounded;

    switch (article.targetInjuryTypeId) {
      case 'abrasion':
        topicBgColor = const Color(0xFFEFF6FF);
        topicTextColor = const Color(0xFF1D4ED8);
        topicIcon = Icons.grain;
        break;
      case 'cut_laceration':
        topicBgColor = const Color(0xFFFFF7ED);
        topicTextColor = const Color(0xFFC2410C);
        topicIcon = Icons.content_cut_rounded;
        break;
      case 'burn':
        topicBgColor = const Color(0xFFFEF2F2);
        topicTextColor = const Color(0xFFB91C1C);
        topicIcon = Icons.local_fire_department_rounded;
        break;
      case 'bruise':
        topicBgColor = const Color(0xFFFAF5FF);
        topicTextColor = const Color(0xFF7E22CE);
        topicIcon = Icons.blur_circular_rounded;
        break;
      case 'other_wounds':
      default:
        topicBgColor = const Color(0xFFF0FDF4);
        topicTextColor = const Color(0xFF15803D);
        topicIcon = Icons.medical_services_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: article.isPublished ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dải badge thông tin đầu thẻ
          Row(
            children: [
              // Badge phạm trù vết thương
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: topicBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: topicTextColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(topicIcon, size: 14, color: topicTextColor),
                    const SizedBox(width: 5),
                    Text(
                      'Phạm trù: ${article.effectiveInjuryTypeName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: topicTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge danh mục
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.categoryName,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),

              // Switch trạng thái xuất bản
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.isPublished ? 'Đang xuất bản' : 'Tạm ẩn',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: article.isPublished ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: article.isPublished,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (_) => viewModel.toggleArticlePublished(article.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tiêu đề bài viết
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2B6B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),

          // Tóm tắt
          Text(
            article.summary,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
          ),
          const SizedBox(height: 14),

          // Thống kê chi tiết
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.format_list_numbered_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text('${article.steps.length} bước sơ cứu chi tiết',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text('${article.warnings.length} dấu hiệu cảnh báo',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                ],
              ),
              if (article.contraindications.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block_rounded, size: 15, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text('${article.contraindications.length} Không được làm',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                  ],
                ),
              Text(
                '• Cập nhật: ${article.lastUpdated}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (article.sourceUrl != null && article.sourceUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => UrlLauncherHelper.launchWebUrl(context, article.sourceUrl),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Text(
                      '${article.sourceOrganization ?? "Nguồn y tế"}: ',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                    ),
                    Flexible(
                      child: Text(
                        article.sourceUrl!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ],
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Thanh nút hành động: Xem trước, Chỉnh sửa sâu, Xóa
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPreviewArticleDialog(context, article),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Xem trước'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditArticleDialog(context, viewModel, articleToEdit: article),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Tùy chỉnh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                tooltip: 'Xóa bài viết này',
                onPressed: () => _showConfirmDeleteDialog(context, viewModel, article),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showConfirmDeleteDialog(
    BuildContext context,
    AdminViewModel viewModel,
    KnowledgeArticleModel article,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận xóa bài viết'),
        content: Text('Bạn có chắc chắn muốn xóa bài viết "${article.title}" khỏi Knowledge Base?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteKnowledgeArticle(article.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  /// Dialog xem trước chi tiết bài viết phác đồ sơ cứu chuẩn
  void _showPreviewArticleDialog(BuildContext context, KnowledgeArticleModel article) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.medical_services_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B))),
                  Text('Phạm trù: ${article.effectiveInjuryTypeName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tóm tắt
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                  child: Text(article.summary, style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155))),
                ),
                const SizedBox(height: 18),

                // Các bước sơ cứu
                const Text('CÁC BƯỚC SƠ CỨU CHI TIẾT:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2563EB))),
                const SizedBox(height: 8),
                ...article.steps.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text('$idx', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(step, style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B), height: 1.4))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Cảnh báo nguy hiểm
                if (article.warnings.isNotEmpty) ...[
                  const Text('DẤU HIỆU CẢNH BÁO NGUY HIỂM / ĐI KHÁM:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFD97706))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: article.warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                            Expanded(child: Text(w, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Điều cấm kỵ
                if (article.contraindications.isNotEmpty) ...[
                  const Text('NHỮNG ĐIỀU TUYỆT ĐỐI KHÔNG ĐƯỢC LÀM:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFDC2626))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: article.contraindications.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🚫 ', style: TextStyle(fontSize: 12)),
                            Expanded(child: Text(c, style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
                if (article.sourceUrl != null && article.sourceUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('NGUỒN THẨM ĐỊNH Y KHOA:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => UrlLauncherHelper.launchWebUrl(context, article.sourceUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.sourceOrganization ?? 'Nguồn y khoa chính thức',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                                ),
                                Text(
                                  article.sourceUrl!,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => UrlLauncherHelper.launchWebUrl(context, article.sourceUrl),
                            icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                            label: const Text('Mở Web'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Modal Dialog "Thêm bài viết mới" hoặc "Tùy chỉnh sâu bài viết"
  void _showAddOrEditArticleDialog(
    BuildContext context,
    AdminViewModel viewModel, {
    KnowledgeArticleModel? articleToEdit,
    String? initialTopicId,
  }) {
    final bool isEditing = articleToEdit != null;

    final titleController = TextEditingController(text: articleToEdit?.title ?? '');
    final summaryController = TextEditingController(text: articleToEdit?.summary ?? '');
    final stepsController = TextEditingController(
      text: articleToEdit?.steps.join('\n') ?? 'Rửa sạch vết thương bằng nước muối sinh lý 0.9%\nSát trùng nhẹ nhàng mép da bị thương\nBăng gạc vô trùng che phủ bảo vệ',
    );
    final warningsController = TextEditingController(
      text: articleToEdit?.warnings.join('\n') ?? 'Vết thương sưng mủ, sốt cao hoặc đỏ tấy lan rộng\nChảy máu nhiều không cầm sau 10 - 15 phút ép trực tiếp',
    );
    final contraindicationsController = TextEditingController(
      text: articleToEdit?.contraindications.join('\n') ?? 'Không đắp lá cây, tro than hay bột thuốc chưa chỉ định',
    );
    final sourceOrgController = TextEditingController(
      text: articleToEdit?.sourceOrganization ?? 'Hội Chữ Thập Đỏ Việt Nam',
    );
    final sourceUrlController = TextEditingController(
      text: articleToEdit?.sourceUrl ?? 'https://redcross.org.vn/so-cap-cuu',
    );

    String selectedTopicId = articleToEdit?.targetInjuryTypeId ?? initialTopicId ?? 'abrasion';
    String selectedCategory = articleToEdit?.categoryId ?? 'wound';
    String selectedCategoryName = articleToEdit?.categoryName ?? 'Vết thương';
    RuleSeverityLevel selectedSeverity = articleToEdit?.defaultSeverity ?? RuleSeverityLevel.normal;
    bool isPublished = articleToEdit?.isPublished ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEditing ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.post_add_rounded,
                  color: isEditing ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Tùy chỉnh nội dung sơ cứu' : 'Thêm bài viết kiến thức mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
                    ),
                    Text(
                      isEditing ? 'Cập nhật nội dung, các bước xử lý vết thương' : 'Đăng tải nội dung sơ cứu chuẩn y tế vào hệ thống',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PHẦN 1: PHẠM TRÙ VẾT THƯƠNG (TRỌNG TÂM) ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.category_rounded, size: 18, color: Color(0xFF2563EB)),
                            SizedBox(width: 6),
                            Text(
                              'Phạm trù vết thương áp dụng kiến thức này:',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTopicId,
                          items: const [
                            DropdownMenuItem(value: 'abrasion', child: Text('🩹 Trầy xước ngoài da (abrasion)')),
                            DropdownMenuItem(value: 'cut_laceration', child: Text('✂️ Vết cắt / rách da (cut_laceration)')),
                            DropdownMenuItem(value: 'burn', child: Text('🔥 Bỏng nhiệt / hóa chất (burn)')),
                            DropdownMenuItem(value: 'bruise', child: Text('🟣 Bầm tím phần mềm (bruise)')),
                            DropdownMenuItem(value: 'other_wounds', child: Text('🩺 Vết thương khác / Sơ cứu chung (other_wounds)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedTopicId = val);
                            }
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề
                  const Text('Tiêu đề bài viết:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Phác đồ cầm máu và vô trùng vết rách da...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Danh mục và Mức độ nghiêm trọng
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Danh mục y tế:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              items: const [
                                DropdownMenuItem(value: 'wound', child: Text('Vết thương')),
                                DropdownMenuItem(value: 'burn', child: Text('Bỏng')),
                                DropdownMenuItem(value: 'musculoskeletal', child: Text('Xương khớp')),
                                DropdownMenuItem(value: 'other', child: Text('Vết thương khác')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    selectedCategory = val;
                                    if (val == 'wound') selectedCategoryName = 'Vết thương';
                                    if (val == 'burn') selectedCategoryName = 'Bỏng';
                                    if (val == 'musculoskeletal') selectedCategoryName = 'Xương khớp';
                                    if (val == 'other') selectedCategoryName = 'Vết thương khác';
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mức độ cảnh báo:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<RuleSeverityLevel>(
                              initialValue: selectedSeverity,
                              items: const [
                                DropdownMenuItem(value: RuleSeverityLevel.normal, child: Text('🟢 Nhẹ (Thường gặp)')),
                                DropdownMenuItem(value: RuleSeverityLevel.warning, child: Text('🟠 Cần chú ý (Quan trọng)')),
                                DropdownMenuItem(value: RuleSeverityLevel.emergency, child: Text('🔴 Nguy cấp (Báo động đỏ)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => selectedSeverity = val);
                              },
                              decoration: InputDecoration(
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

                  // Tóm tắt
                  const Text('Tóm tắt tổng quan:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: summaryController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Tóm tắt ngắn gọn mục tiêu của bài hướng dẫn sơ cứu...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PHẦN 2: CÁC BƯỚC SƠ CỨU CHI TIẾT ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Các bước thực hiện sơ cứu chi tiết:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF2563EB))),
                      Text('(Mỗi dòng là 1 bước)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: stepsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Bước 1: Rửa tay...\nBước 2: Cầm máu...\nBước 3: Băng bảo vệ...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PHẦN 3: CẢNH BÁO NGUY HIỂM ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Dấu hiệu nguy hiểm / Cần chuyển viện:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFFD97706))),
                      Text('(Mỗi dòng là 1 cảnh báo)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: warningsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Chảy máu phun thành tia...\nNạn nhân choáng váng hoặc khó thở...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- PHẦN 4: ĐIỀU CẤM KỴ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Những việc TUYỆT ĐỐI KHÔNG LÀM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFFDC2626))),
                      Text('(Mỗi dòng 1 điều)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: contraindicationsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Không tự ý rút dị vật cắm sâu...\nKhông bôi kem đánh răng lên vết bỏng...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- PHẦN 5: TÙY BIẾN ĐƯỜNG DẪN LIÊN KẾT WEB (URL) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Nguồn tài liệu y khoa & Đường dẫn web (URL):',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1D4ED8)),
                      ),
                      Text('(Bấm vào sẽ nhảy trực tiếp ra trình duyệt)', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: sourceOrgController,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Tổ chức thẩm định',
                            hintText: 'VD: Bộ Y Tế, WHO...',
                            prefixIcon: const Icon(Icons.verified_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: TextField(
                          controller: sourceUrlController,
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'Đường dẫn liên kết web (URL)',
                            hintText: 'https://...',
                            prefixIcon: const Icon(Icons.link_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Thử nhảy ra web ngay',
                        onPressed: () {
                          UrlLauncherHelper.launchWebUrl(context, sourceUrlController.text);
                        },
                        icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF2563EB)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Xuất bản
                  Row(
                    children: [
                      Checkbox(
                        value: isPublished,
                        activeColor: const Color(0xFF2563EB),
                        onChanged: (val) => setState(() => isPublished = val ?? true),
                      ),
                      const Text(
                        'Kích hoạt xuất bản (Người dùng có thể tra cứu và xem hướng dẫn bài viết này)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                // Tách các bước
                final steps = stepsController.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final warnings = warningsController.text
                    .split('\n')
                    .map((w) => w.trim())
                    .where((w) => w.isNotEmpty)
                    .toList();
                final contraindications = contraindicationsController.text
                    .split('\n')
                    .map((c) => c.trim())
                    .where((c) => c.isNotEmpty)
                    .toList();

                final updatedArticle = KnowledgeArticleModel(
                  id: articleToEdit?.id ?? 'kb_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  categoryId: selectedCategory,
                  categoryName: selectedCategoryName,
                  summary: summaryController.text.trim().isNotEmpty
                      ? summaryController.text.trim()
                      : 'Phác đồ sơ cứu chuẩn y tế được cập nhật bởi quản trị viên.',
                  targetInjuryTypeId: selectedTopicId,
                  targetInjuryTypeName: getInjuryTopicName(selectedTopicId),
                  defaultSeverity: selectedSeverity,
                  steps: steps.isNotEmpty ? steps : const ['Rửa sạch vết thương', 'Băng bảo vệ'],
                  warnings: warnings.isNotEmpty ? warnings : const ['Đến viện nếu đau tăng hoặc sưng phù'],
                  contraindications: contraindications,
                  lastUpdated: 'Hôm nay',
                  isPublished: isPublished,
                  sourceOrganization: sourceOrgController.text.trim().isNotEmpty
                      ? sourceOrgController.text.trim()
                      : null,
                  sourceUrl: sourceUrlController.text.trim().isNotEmpty
                      ? sourceUrlController.text.trim()
                      : null,
                );

                if (isEditing) {
                  viewModel.updateKnowledgeArticle(updatedArticle);
                } else {
                  viewModel.addKnowledgeArticle(updatedArticle);
                }

                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm bài viết'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CÁC COMPONENT TAB & NGUỒN TRÍCH XUẤT Y KHOA CHI TIẾT
  // ===========================================================================
  Widget _buildHeaderRow(
    BuildContext context,
    AdminViewModel viewModel,
    bool isMobile,
  ) {
    if (_selectedTab == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Quản lý Knowledge Base & Kiến thức sơ cứu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kho cẩm nang & phác đồ chuẩn y khoa (Bộ - Tổ chức Y tế) – Cung cấp nội dung sơ cứu các bước chuẩn',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showAddOrEditArticleDialog(context, viewModel),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('Thêm bài viết mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Nguồn trích xuất hướng dẫn y khoa chi tiết',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2B6B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tùy chỉnh danh sách liên kết tài liệu y khoa tham chiếu hiển thị trực tiếp ở chân trang sơ cứu của người dùng',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  viewModel.resetMedicalSourcesToDefault();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã khôi phục 4 nguồn trích xuất y khoa mặc định!'),
                      backgroundColor: Color(0xFF2563EB),
                    ),
                  );
                },
                icon: const Icon(Icons.restore_rounded, size: 17),
                label: const Text('Mặc định'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditSourceDialog(context, viewModel),
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text('Thêm nguồn mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildTabSelector(AdminViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            title: 'Cẩm nang bài viết sơ cứu (${viewModel.knowledgeArticles.length})',
            icon: Icons.menu_book_rounded,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 8),
          _buildTabButton(
            title: 'Nguồn trích xuất y khoa chi tiết (${viewModel.adminMedicalSources.length})',
            icon: Icons.link_rounded,
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesTab(
    BuildContext context,
    AdminViewModel viewModel,
    List<KnowledgeArticleModel> articles,
    List<KnowledgeArticleModel> paginatedArticles,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner phân biệt vai trò: Knowledge Base vs Rule Engine
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cơ sở Tri thức Y khoa (Knowledge Base) – Phác đồ điều trị chuẩn',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Knowledge Base lưu trữ các bài viết, cẩm nang và quy trình sơ cứu 4 bước chuẩn theo bệnh học. Rule Engine sẽ tự động trích xuất các phác đồ này khi điều kiện lâm sàng thực tế của người dùng được kích hoạt.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Thanh lọc theo Phạm trù vết thương (Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTopicFilterChip(context, viewModel, 'all', 'Tất cả (${viewModel.knowledgeArticles.length})'),
              const SizedBox(width: 8),
              _buildTopicFilterChip(context, viewModel, 'abrasion', '🩹 Trầy xước'),
              const SizedBox(width: 8),
              _buildTopicFilterChip(context, viewModel, 'cut_laceration', '✂️ Vết cắt / rách'),
              const SizedBox(width: 8),
              _buildTopicFilterChip(context, viewModel, 'burn', '🔥 Bỏng'),
              const SizedBox(width: 8),
              _buildTopicFilterChip(context, viewModel, 'bruise', '🟣 Bầm tím'),
              const SizedBox(width: 8),
              _buildTopicFilterChip(context, viewModel, 'other_wounds', '🩺 Vết thương khác'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Ô tìm kiếm
        TextField(
          onChanged: (val) => viewModel.setKbSearchQuery(val),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bài viết theo tiêu đề, phạm trù vết thương, nội dung...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Danh sách bài viết
        if (articles.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                const Icon(Icons.menu_book_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'Không tìm thấy bài viết kiến thức nào cho phạm trù này.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showAddOrEditArticleDialog(
                    context,
                    viewModel,
                    initialTopicId: viewModel.selectedInjuryTopicFilter != 'all'
                        ? viewModel.selectedInjuryTopicFilter
                        : 'other_wounds',
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm bài viết cho phạm trù này'),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedArticles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final article = paginatedArticles[index];
                  return _buildArticleItemCard(context, viewModel, article);
                },
              ),
              const SizedBox(height: 16),
              buildAdminPaginationFooter(
                currentPage: viewModel.currentKbPage,
                totalPages: viewModel.totalKbPages,
                totalItems: articles.length,
                pageSize: AdminManagementViewModel.kbPageSize,
                itemLabel: 'bài viết phác đồ',
                onPageSelected: (page) => viewModel.selectKbPage(page),
                onPrevious: () => viewModel.goToPreviousKbPage(),
                onNext: () => viewModel.goToNextKbPage(),
                isMobile: isMobile,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMedicalSourcesTab(
    BuildContext context,
    AdminViewModel viewModel,
    bool isMobile,
  ) {
    final sources = viewModel.adminMedicalSources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner thông tin giải thích
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.link_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tùy chỉnh danh sách nguồn trích xuất hướng dẫn y khoa chi tiết',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Các liên kết này hiển thị trực tiếp ở chân trang của người dùng khi xem hướng dẫn sơ cứu tổn thương. Bạn có thể thêm link mới, sửa tổ chức / URL, hoặc bật/tắt hiển thị từng nguồn.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (sources.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.link_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có nguồn trích xuất y khoa nào được cấu hình.',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Người dùng sẽ không thấy khối "Nguồn trích xuất hướng dẫn y khoa chi tiết" ở chân trang.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => viewModel.resetMedicalSourcesToDefault(),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Khôi phục danh sách mặc định (4 nguồn chuẩn)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ...sources.map((src) => _buildMedicalSourceCard(context, viewModel, src, isMobile)),
      ],
    );
  }

  Widget _buildMedicalSourceCard(
    BuildContext context,
    AdminViewModel viewModel,
    MedicalSourceLink src,
    bool isMobile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: src.isEnabled ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon tròn
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: src.isEnabled ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.link_rounded,
              size: 20,
              color: src.isEnabled ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 14),

          // Nội dung chi tiết
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        src.organization,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: src.isEnabled ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: src.isEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        src.isEnabled ? 'Đang hiển thị' : 'Đã ẩn',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: src.isEnabled ? const Color(0xFF166534) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  src.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: src.isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => UrlLauncherHelper.launchWebUrl(context, src.url, fallbackTitle: src.title),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            src.url,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildSourceTag(
                      label: 'Phạm vi: ${src.targetTopicId == "all" ? "Tất cả hướng dẫn sơ cứu" : getInjuryTopicName(src.targetTopicId)}',
                      icon: Icons.category_outlined,
                    ),
                    _buildSourceTag(
                      label: 'Năm: ${src.publishYear}',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action buttons
          Column(
            children: [
              Switch(
                value: src.isEnabled,
                activeThumbColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  viewModel.toggleAdminMedicalSource(src.id);
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                    tooltip: 'Chỉnh sửa nguồn này',
                    onPressed: () => _showAddOrEditSourceDialog(context, viewModel, sourceToEdit: src),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    tooltip: 'Xóa nguồn này',
                    onPressed: () => _confirmDeleteSource(context, viewModel, src),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTag({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSource(
    BuildContext context,
    AdminViewModel viewModel,
    MedicalSourceLink src,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa nguồn trích xuất'),
        content: Text('Bạn có chắc chắn muốn xóa nguồn "${src.organization}: ${src.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteAdminMedicalSource(src.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa nguồn "${src.organization}"!'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa nguồn'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditSourceDialog(
    BuildContext context,
    AdminViewModel viewModel, {
    MedicalSourceLink? sourceToEdit,
  }) {
    final isEditing = sourceToEdit != null;
    final orgController = TextEditingController(text: sourceToEdit?.organization ?? '');
    final titleController = TextEditingController(text: sourceToEdit?.title ?? '');
    final urlController = TextEditingController(text: sourceToEdit?.url ?? '');
    final yearController = TextEditingController(text: sourceToEdit?.publishYear ?? DateTime.now().year.toString());
    String selectedTopic = sourceToEdit?.targetTopicId ?? 'all';
    bool isEnabled = sourceToEdit?.isEnabled ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.add_link_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Chỉnh sửa nguồn trích xuất y khoa' : 'Thêm nguồn trích xuất y khoa mới',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tên tổ chức y tế phát hành / Tham chiếu *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: orgController,
                    decoration: const InputDecoration(
                      hintText: 'VD: Hội Chữ Thập Đỏ Việt Nam, Bộ Y Tế, WHO, Mayo Clinic...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Tiêu đề tài liệu hướng dẫn y khoa *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'VD: Tài liệu hướng dẫn sơ cấp cứu ban đầu',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Đường dẫn web (URL) đầy đủ *',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            hintText: 'https://...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (urlController.text.trim().isNotEmpty) {
                            UrlLauncherHelper.launchWebUrl(context, urlController.text.trim());
                          }
                        },
                        icon: const Icon(Icons.open_in_browser_rounded),
                        tooltip: 'Thử mở link kiểm tra',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Năm ban hành', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '2025',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Áp dụng cho phạm trù', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedTopic,
                              isDense: true,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Tất cả hướng dẫn sơ cứu')),
                                DropdownMenuItem(value: 'abrasion', child: Text('Trầy xước ngoài da')),
                                DropdownMenuItem(value: 'cut_laceration', child: Text('Vết cắt / rách da')),
                                DropdownMenuItem(value: 'burn', child: Text('Bỏng nhiệt / hóa chất')),
                                DropdownMenuItem(value: 'bruise', child: Text('Bầm tím phần mềm')),
                                DropdownMenuItem(value: 'other_wounds', child: Text('Vết thương khác')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedTopic = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hiển thị nguồn này cho người dùng', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tắt để tạm ẩn khỏi chân trang hướng dẫn sơ cứu', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: isEnabled,
                    activeThumbColor: const Color(0xFF2563EB),
                    onChanged: (val) => setDialogState(() => isEnabled = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy bỏ'),
            ),
            ElevatedButton(
              onPressed: () {
                final org = orgController.text.trim();
                final title = titleController.text.trim();
                final url = urlController.text.trim();
                final year = yearController.text.trim();

                if (org.isEmpty || title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ Tổ chức, Tiêu đề và URL!')),
                  );
                  return;
                }

                if (isEditing) {
                  viewModel.updateAdminMedicalSource(
                    sourceToEdit.id,
                    sourceToEdit.copyWith(
                      organization: org,
                      title: title,
                      url: url,
                      publishYear: year.isNotEmpty ? year : '2025',
                      targetTopicId: selectedTopic,
                      isEnabled: isEnabled,
                    ),
                  );
                } else {
                  final newSource = MedicalSourceLink(
                    id: 'src_${DateTime.now().millisecondsSinceEpoch}',
                    organization: org,
                    title: title,
                    url: url,
                    publishYear: year.isNotEmpty ? year : '2025',
                    targetTopicId: selectedTopic,
                    isEnabled: isEnabled,
                  );
                  viewModel.addAdminMedicalSource(newSource);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Đã cập nhật nguồn trích xuất "$org" thành công!'
                          : 'Đã thêm nguồn trích xuất "$org" thành công!',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Lưu thay đổi' : 'Thêm nguồn'),
            ),
          ],
        ),
      ),
    );
  }
}


