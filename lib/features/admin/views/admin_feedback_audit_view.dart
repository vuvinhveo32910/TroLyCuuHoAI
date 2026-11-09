// File: lib/features/admin/views/admin_feedback_audit_view.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/feedback/ai_feedback_model.dart';
import '../viewmodels/admin_viewmodel.dart';

/// Màn hình xem các đánh giá đúng / sai và phản hồi của người dùng về kết quả AI
/// Giúp nhóm phát triển theo dõi sai số và thu thập dữ liệu cải thiện mô hình trong tương lai.
class AdminAiFeedbackAuditView extends StatefulWidget {
  const AdminAiFeedbackAuditView({super.key});

  @override
  State<AdminAiFeedbackAuditView> createState() => _AdminAiFeedbackAuditViewState();
}

class _AdminAiFeedbackAuditViewState extends State<AdminAiFeedbackAuditView> {
  String _searchQuery = '';
  String _selectedTypeFilter = 'all'; // 'all', 'inaccurate', 'helpful'
  String _selectedSourceFilter = 'all'; // 'all', 'yoloVision', 'medgemma', 'gemini'
  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final allFeedbacks = viewModel.aiFeedbacks;

    // Lọc theo bộ lọc và từ khóa tìm kiếm
    final filteredFeedbacks = allFeedbacks.where((item) {
      if (_selectedTypeFilter == 'inaccurate' && !item.isInaccurate) return false;
      if (_selectedTypeFilter == 'helpful' && !item.isHelpful) return false;

      if (_selectedSourceFilter != 'all' && item.sourceModel.name != _selectedSourceFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchComment = item.userComment.toLowerCase().contains(q);
        final matchId = (item.analysisId ?? item.id).toLowerCase().contains(q);
        final matchWound = item.detectedWoundSummary.toLowerCase().contains(q);
        final matchUser = item.userDisplayName.toLowerCase().contains(q);
        final matchProposed = (item.userProposedLabel ?? '').toLowerCase().contains(q);
        final matchCategory = item.issueCategory.toLowerCase().contains(q);
        return matchComment || matchId || matchWound || matchUser || matchProposed || matchCategory;
      }

      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TIÊU ĐỀ & NÚT XUẤT TẬP DỮ LIỆU
          _buildHeaderBar(context, viewModel),
          const SizedBox(height: 20),

          // 2. CÁC THẺ THỐNG KÊ METRIC CARDS
          _buildMetricCards(viewModel),
          const SizedBox(height: 22),

          // 3. THANH TÌM KIẾM & BỘ LỌC
          _buildFilterToolbar(),
          const SizedBox(height: 18),

          // 4. DANH SÁCH CÁC PHẢN HỒI TỪ NGƯỜI DÙNG (5 MỤC / TRANG)
          if (filteredFeedbacks.isEmpty)
            _buildEmptyState()
          else () {
            final totalPages = (filteredFeedbacks.length / _pageSize).ceil().clamp(1, 999);
            final safePage = _currentPage.clamp(1, totalPages);
            final startIndex = (safePage - 1) * _pageSize;
            final paginatedFeedbacks = startIndex >= filteredFeedbacks.length
                ? <AiFeedbackModel>[]
                : filteredFeedbacks.sublist(
                    startIndex,
                    math.min(startIndex + _pageSize, filteredFeedbacks.length),
                  );

            return Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paginatedFeedbacks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = paginatedFeedbacks[index];
                    return _buildFeedbackItemCard(context, viewModel, item);
                  },
                ),
                const SizedBox(height: 20),
                _buildPaginationControls(
                  currentPage: safePage,
                  totalPages: totalPages,
                  totalItems: filteredFeedbacks.length,
                ),
              ],
            );
          }(),
        ],
      ),
    );
  }

  /// Tiêu đề + Nút xuất dữ liệu
  Widget _buildHeaderBar(BuildContext context, AdminViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rate_review_rounded, color: Color(0xFF1E3A8A), size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Đánh Giá & Phản Hồi AI Từ Người Dùng',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Theo dõi người dùng đánh giá kết quả đúng hay sai kèm lý do thực tế, phục vụ nghiên cứu và nâng cấp mô hình AI trong tương lai.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showExportDatasetDialog(context, viewModel),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: Text('Xuất dữ liệu phản hồi (${viewModel.totalAiFeedbackCount})'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
          ),
        ),
      ],
    );
  }

  /// 4 Thẻ thống kê tổng quan
  Widget _buildMetricCards(AdminViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final cardWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Tổng số lượt đánh giá',
              count: viewModel.totalAiFeedbackCount.toString(),
              subtitle: 'Phản hồi từ người dùng',
              icon: Icons.forum_outlined,
              color: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Đánh giá ĐÚNG / Hài lòng',
              count: viewModel.helpfulAiReportCount.toString(),
              subtitle: 'Người dùng xác nhận đúng',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF16A34A),
              bgColor: const Color(0xFFF0FDF4),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Đánh giá SAI / Nhận diện nhầm',
              count: viewModel.inaccurateAiReportCount.toString(),
              subtitle: 'Cần phân tích để cải thiện',
              icon: Icons.highlight_off_rounded,
              color: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Tỷ lệ người dùng đánh giá đúng',
              count: '${viewModel.aiAccuracyRate.toStringAsFixed(1)}%',
              subtitle: 'Mức độ hài lòng của người dùng',
              icon: Icons.auto_graph_rounded,
              color: const Color(0xFF7C3AED),
              bgColor: const Color(0xFFFAF5FF),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh tìm kiếm và bộ lọc nhanh
  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              onChanged: (val) => setState(() { _searchQuery = val.trim(); _currentPage = 1; }),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo mã ca, nhận diện AI, phản ánh của người dùng...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Lọc Loại đánh giá (Tất cả, Đánh giá Sai, Đánh giá Đúng)
          DropdownButton<String>(
            value: _selectedTypeFilter,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả đánh giá')),
              DropdownMenuItem(value: 'inaccurate', child: Text('⚠️ Người dùng báo SAI')),
              DropdownMenuItem(value: 'helpful', child: Text('👍 Người dùng báo ĐÚNG')),
            ],
            onChanged: (val) => setState(() { _selectedTypeFilter = val ?? 'all'; _currentPage = 1; }),
          ),
          const SizedBox(width: 12),
          // Lọc Nguồn Model AI
          DropdownButton<String>(
            value: _selectedSourceFilter,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(8),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả mô hình AI')),
              DropdownMenuItem(value: 'yoloVision', child: Text('YOLO Vision')),
              DropdownMenuItem(value: 'medgemma', child: Text('MedGemma Local')),
              DropdownMenuItem(value: 'gemini', child: Text('Gemini API')),
            ],
            onChanged: (val) => setState(() { _selectedSourceFilter = val ?? 'all'; _currentPage = 1; }),
          ),
        ],
      ),
    );
  }

  /// Thẻ chi tiết phản hồi của người dùng
  Widget _buildFeedbackItemCard(
    BuildContext context,
    AdminViewModel viewModel,
    AiFeedbackModel item,
  ) {
    final isInaccurate = item.isInaccurate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInaccurate ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060D2B6B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dòng tiêu đề: Nguồn model + Mã ca + Thời gian + Badge ĐÚNG / SAI
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.sourceModelLabel,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mã: ${item.analysisId ?? item.id}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${item.userDisplayName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const Spacer(),
              // Badge đánh giá của người dùng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isInaccurate ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isInaccurate ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInaccurate ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      size: 15,
                      color: isInaccurate ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isInaccurate ? 'NGƯỜI DÙNG BÁO: SAI' : 'NGƯỜI DÙNG BÁO: ĐÚNG',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isInaccurate ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // 2. Chi tiết đối chiếu: AI dự đoán vs Người dùng nhận định
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kết quả AI ban đầu
                    Row(
                      children: [
                        const Text(
                          'Dự đoán của AI: ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.detectedWoundSummary,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                          ),
                        ),
                        if (item.userProposedLabel != null && item.userProposedLabel!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          const Text(
                            'Người dùng nhận định: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.userProposedLabel!,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Lý do phản ánh của người dùng
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Loại vấn đề: ${item.issueCategory}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '💬 "${item.userComment}"',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),

                    if (item.woundLocation != null || item.observedSymptoms.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (item.woundLocation != null)
                            Chip(
                              label: Text('Vị trí: ${item.woundLocation}', style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          if (item.painLevel != null)
                            Chip(
                              label: Text('Cảm giác đau: ${item.painLevel}', style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ...item.observedSymptoms.map((symp) {
                            return Chip(
                              label: Text(symp, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Hàng nút hành động dưới cùng
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmDeleteFeedback(context, viewModel, item),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                label: const Text('Xóa phản hồi', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Trạng thái trống
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy phản hồi nào phù hợp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          SizedBox(height: 4),
          Text(
            'Các đánh giá đúng / sai và góp ý từ người dùng sẽ hiển thị tại đây.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại xuất tập dữ liệu phản hồi JSON
  void _showExportDatasetDialog(BuildContext context, AdminViewModel viewModel) {
    final jsonString = viewModel.exportAiFeedbackDatasetJson();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tập Dữ Liệu Phản Hồi Người Dùng (JSON)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bao gồm ${viewModel.totalAiFeedbackCount} bản ghi đánh giá đúng/sai từ người dùng để phục vụ phân tích và cải thiện mô hình AI.',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 320,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép toàn bộ dữ liệu phản hồi JSON vào Clipboard!'),
                            backgroundColor: Color(0xFF2563EB),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Sao chép JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _confirmDeleteFeedback(
    BuildContext context,
    AdminViewModel viewModel,
    AiFeedbackModel item,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phản hồi này?'),
        content: Text('Bạn có chắc chắn muốn xóa phản hồi "${item.analysisId ?? item.id}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteAiFeedback(item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa phản hồi thành công!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
  Widget _buildPaginationControls({
    required int currentPage,
    required int totalPages,
    required int totalItems,
  }) {
    if (totalItems == 0) return const SizedBox.shrink();

    final startItem = (currentPage - 1) * _pageSize + 1;
    final endItem = math.min(currentPage * _pageSize, totalItems);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final infoText = 'Hiển thị $startItem - $endItem trên tổng số $totalItems đánh giá (5 đánh giá / trang)';

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(totalPages, (i) {
          final pageNum = i + 1;
          final isSelected = pageNum == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Material(
              color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _currentPage = pageNum),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          Text(infoText, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(infoText, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        controls,
      ],
    );
  }
}
