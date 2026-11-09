// File: lib/features/admin/views/admin_history_analytics_view.dart
import 'package:flutter/material.dart';

import '../../../core/history/analysis_history_service.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../user/models/history_models.dart';

/// Màn hình Lịch sử & Thống kê hệ thống dành cho Quản trị viên (/admin)
/// Kết nối và đồng bộ trực tiếp với bảng 'analysis_history' trên Supabase PostgreSQL
class AdminHistoryAnalyticsView extends StatefulWidget {
  const AdminHistoryAnalyticsView({super.key});

  @override
  State<AdminHistoryAnalyticsView> createState() => _AdminHistoryAnalyticsViewState();
}

class _AdminHistoryAnalyticsViewState extends State<AdminHistoryAnalyticsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSeverityFilter = 'all';
  String _selectedInjuryTypeFilter = 'all';

  int _currentPage = 1;
  static const int _pageSize = 8;

  @override
  void initState() {
    super.initState();
    AnalysisHistoryService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    AnalysisHistoryService.instance.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = AnalysisHistoryService.instance;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    // Lọc danh sách dữ liệu thực tế
    final allItems = service.items;
    final filteredItems = allItems.where((item) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty) {
        final matchesQuery = item.injuryType.toLowerCase().contains(q) ||
            (item.username?.toLowerCase().contains(q) ?? false) ||
            (item.firstAidSummary?.toLowerCase().contains(q) ?? false) ||
            item.locationLabel.toLowerCase().contains(q);
        if (!matchesQuery) return false;
      }

      if (_selectedSeverityFilter != 'all') {
        final sev = item.severityLevel.toLowerCase();
        if (_selectedSeverityFilter == 'severe' &&
            !(sev == 'severe' || sev == 'nặng' || sev == 'nang')) {
          return false;
        }
        if (_selectedSeverityFilter == 'moderate' &&
            !(sev == 'moderate' || sev == 'vừa' || sev == 'vua')) {
          return false;
        }
        if (_selectedSeverityFilter == 'mild' &&
            !(sev == 'mild' || sev == 'nhẹ' || sev == 'nhe')) {
          return false;
        }
      }

      if (_selectedInjuryTypeFilter != 'all') {
        if (item.injuryType != _selectedInjuryTypeFilter) {
          return false;
        }
      }

      return true;
    }).toList();

    final totalPages = (filteredItems.length / _pageSize).ceil().clamp(1, 9999);
    final validPage = _currentPage.clamp(1, totalPages);
    final startIndex = (validPage - 1) * _pageSize;
    final paginatedItems = startIndex >= filteredItems.length
        ? <AnalysisHistoryItemModel>[]
        : filteredItems.sublist(
            startIndex,
            (startIndex + _pageSize > filteredItems.length)
                ? filteredItems.length
                : startIndex + _pageSize,
          );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề & Nút thao tác
          _buildHeader(context, service, isMobile),
          const SizedBox(height: 18),

          // 4 Thẻ chỉ số KPI thời gian thực tính từ Database Supabase
          _buildKpiCards(service, isMobile),
          const SizedBox(height: 20),

          // Thanh thông báo trạng thái Supabase Cloud
          _buildCloudStatusBanner(service),
          const SizedBox(height: 20),

          // Thanh tìm kiếm và bộ lọc đa chiều
          _buildFilterBar(service, allItems, isMobile),
          const SizedBox(height: 16),

          // Danh sách hoặc Bảng dữ liệu thực tế
          if (service.isLoading && allItems.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (filteredItems.isEmpty) ...[
            _buildEmptyState(service, allItems.isEmpty),
          ] else ...[
            _buildHistoryTable(context, paginatedItems, service),
            const SizedBox(height: 16),
            _buildPagination(validPage, totalPages, filteredItems.length),
          ],
        ],
      ),
    );
  }

  /// Tiêu đề và nút làm mới / tạo dữ liệu mẫu
  Widget _buildHeader(BuildContext context, AnalysisHistoryService service, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lịch sử & Thống kê hệ thống',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D2B6B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Theo dõi dữ liệu thực tế các ca quét chẩn đoán sơ cứu từ cơ sở dữ liệu Supabase Cloud',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: service.isLoading
                  ? null
                  : () => service.fetchHistoryFromSupabase(),
              icon: service.isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isMobile ? 'Làm mới' : 'Làm mới Supabase'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFD8E2EE)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (service.totalScans == 0)
              ElevatedButton.icon(
                onPressed: service.isLoading
                    ? null
                    : () => service.seedSampleDataToSupabase(),
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('Tạo 4 ca mẫu thật'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 4 Thẻ KPI động tính trực tiếp từ dữ liệu thực
  Widget _buildKpiCards(AnalysisHistoryService service, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 800
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth > 500
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth);

        return Wrap(
          spacing: 16,
          runSpacing: 14,
          children: [
            _buildStatCard(
              title: 'Tổng ca phân tích',
              val: '${service.totalScans} ca',
              subtitle: 'Đồng bộ Supabase',
              icon: Icons.center_focus_strong_rounded,
              color: const Color(0xFF2563EB),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Độ tin cậy AI trung bình',
              val: '${service.averageConfidence}%',
              subtitle: 'Độ chính xác nhận diện',
              icon: Icons.verified_rounded,
              color: const Color(0xFF16A34A),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Ca nghiêm trọng (Nặng)',
              val: '${service.severeCount} ca',
              subtitle: 'Cần can thiệp y tế gấp',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFDC2626),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Người dùng tham gia',
              val: '${service.uniqueUsersCount} tài khoản',
              subtitle: 'Đã lưu lịch sử quét',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF7C3AED),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String val,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050D2B6B),
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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  val,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
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

  /// Banner trạng thái kết nối Cloud thay thế cho ghi chú cũ
  Widget _buildCloudStatusBanner(AnalysisHistoryService service) {
    final isOnline = SupabaseService.instance.isConnected;
    final lastSync = service.lastSyncTime;
    final syncText = lastSync != null
        ? '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')} ngày ${lastSync.day}/${lastSync.month}/${lastSync.year}'
        : 'Vừa xong';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_rounded, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cơ sở dữ liệu Supabase PostgreSQL: Đang kết nối bảng "analysis_history" | Lần đồng bộ gần nhất: $syncText.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF166534),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh tìm kiếm và bộ lọc phân loại
  Widget _buildFilterBar(
    AnalysisHistoryService service,
    List<AnalysisHistoryItemModel> allItems,
    bool isMobile,
  ) {
    // Thu thập danh sách các loại tổn thương có trong data
    final types = allItems.map((e) => e.injuryType).toSet().toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Ô tìm kiếm
          SizedBox(
            width: isMobile ? double.infinity : 280,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _currentPage = 1;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo người dùng, loại vết thương...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

          // Lọc theo Mức độ nghiêm trọng
          DropdownButton<String>(
            value: _selectedSeverityFilter,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(8),
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Tất cả mức độ')),
              DropdownMenuItem(value: 'mild', child: Text('Mức độ: Nhẹ')),
              DropdownMenuItem(value: 'moderate', child: Text('Mức độ: Trung bình')),
              DropdownMenuItem(value: 'severe', child: Text('Mức độ: Nghiêm trọng')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSeverityFilter = val;
                  _currentPage = 1;
                });
              }
            },
          ),

          // Lọc theo Loại tổn thương
          if (types.isNotEmpty)
            DropdownButton<String>(
              value: _selectedInjuryTypeFilter,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(8),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('Tất cả loại vết thương')),
                ...types.map(
                  (t) => DropdownMenuItem(value: t, child: Text(t)),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedInjuryTypeFilter = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
        ],
      ),
    );
  }

  /// Bảng hiển thị danh sách các ca quét thật
  Widget _buildHistoryTable(
    BuildContext context,
    List<AnalysisHistoryItemModel> items,
    AnalysisHistoryService service,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050D2B6B),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          horizontalMargin: 20,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('THỜI GIAN', style: _colHeaderStyle)),
            DataColumn(label: Text('NGƯỜI DÙNG', style: _colHeaderStyle)),
            DataColumn(label: Text('CHẨN ĐOÁN AI', style: _colHeaderStyle)),
            DataColumn(label: Text('ĐỘ TIN CẬY', style: _colHeaderStyle)),
            DataColumn(label: Text('MỨC ĐỘ', style: _colHeaderStyle)),
            DataColumn(label: Text('THAO TÁC', style: _colHeaderStyle)),
          ],
          rows: items.map((item) {
            final isGuest = item.username == null || item.username!.isEmpty;

            return DataRow(
              cells: [
                // Thời gian
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.timestamp,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'ID: ${item.id.length > 8 ? item.id.substring(0, 8) : item.id}...',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                // Người dùng
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isGuest ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isGuest ? const Color(0xFFCBD5E1) : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGuest ? Icons.person_outline_rounded : Icons.account_circle_rounded,
                          size: 14,
                          color: isGuest ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGuest ? 'Khách vãng lai' : item.username!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isGuest ? const Color(0xFF475569) : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Chẩn đoán AI
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.woundAccentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.injuryType,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Độ tin cậy
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      '${item.confidencePercent ?? 80}%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),

                // Mức độ nghiêm trọng
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.severityLabelVi,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: item.severityColor,
                      ),
                    ),
                  ),
                ),

                // Thao tác
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        tooltip: 'Xem chi tiết ca sơ cứu',
                        color: const Color(0xFF2563EB),
                        onPressed: () => _showDetailDialog(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        tooltip: 'Xóa khỏi Supabase',
                        color: const Color(0xFFDC2626),
                        onPressed: () => _confirmDelete(context, item, service),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Trạng thái trống khi chưa có ca quét nào
  Widget _buildEmptyState(AnalysisHistoryService service, bool isTrulyEmpty) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded, size: 40, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          Text(
            isTrulyEmpty
                ? 'Chưa có ca phân tích nào trên máy chủ Supabase'
                : 'Không tìm thấy ca quét phù hợp với bộ lọc',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D2B6B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isTrulyEmpty
                ? 'Khi người dùng thực hiện quét ảnh sơ cứu ở ứng dụng, dữ liệu sẽ tự động lưu vĩnh viễn và hiển thị tại đây.'
                : 'Vui lòng thử xóa từ khóa tìm kiếm hoặc chọn lại các bộ lọc phía trên.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          if (isTrulyEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => service.seedSampleDataToSupabase(),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Tạo 4 ca phân tích mẫu lên Supabase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Thanh phân trang
  Widget _buildPagination(int currentPage, int totalPages, int totalRecords) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tổng cộng $totalRecords bản ghi thực tế',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: currentPage > 1
                  ? () => setState(() => _currentPage = currentPage - 1)
                  : null,
            ),
            Text(
              'Trang $currentPage / $totalPages',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: currentPage < totalPages
                  ? () => setState(() => _currentPage = currentPage + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  /// Hộp thoại xem chi tiết một ca phân tích
  void _showDetailDialog(BuildContext context, AnalysisHistoryItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.woundAccentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medical_services_rounded, color: item.woundAccentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.injuryType,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                    ),
                  ),
                  Text(
                    'Độ tin cậy: ${item.confidencePercent ?? 80}% • Mức độ: ${item.severityLabelVi}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: item.severityColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                _buildInfoRow('Mã định danh (Supabase ID):', item.id),
                _buildInfoRow('Thời gian thực hiện:', item.timestamp),
                _buildInfoRow(
                  'Tài khoản người dùng:',
                  item.username != null && item.username!.isNotEmpty
                      ? item.username!
                      : 'Khách vãng lai (Chưa đăng nhập)',
                ),
                _buildInfoRow('Vị trí tổn thương:', item.locationLabel),
                _buildInfoRow('Mức độ đau ước lượng:', '${item.painLevel} / 10'),
                const SizedBox(height: 12),
                if (item.symptoms.isNotEmpty) ...[
                  const Text(
                    'Dấu hiệu & Triệu chứng ghi nhận:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.symptoms
                        .map(
                          (s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'Khuyến cáo sơ cứu đã hướng dẫn:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    item.firstAidSummary ??
                        'Làm sạch vết thương, sát trùng và theo dõi triệu chứng nhiễm trùng.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại xác nhận xóa ca khỏi Supabase
  void _confirmDelete(
    BuildContext context,
    AnalysisHistoryItemModel item,
    AnalysisHistoryService service,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận xóa bản ghi'),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn ca phân tích "${item.injuryType}" lúc ${item.timestamp} khỏi cơ sở dữ liệu Supabase?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await service.deleteRecord(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Đã xóa bản ghi thành công khỏi Supabase!'
                        : 'Không thể xóa bản ghi trên Supabase.'),
                    backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}

const TextStyle _colHeaderStyle = TextStyle(
  fontSize: 11.5,
  fontWeight: FontWeight.w800,
  color: Color(0xFF475569),
  letterSpacing: 0.5,
);
