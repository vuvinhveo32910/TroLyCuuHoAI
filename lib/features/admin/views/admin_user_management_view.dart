// File: lib/features/admin/views/admin_user_management_view.dart
import 'package:flutter/material.dart';

import '../../../core/user_management/user_account_service.dart';
import '../../user/models/user_account_model.dart';

/// Màn hình Quản lý người dùng trong phân hệ Quản trị (/admin)
/// Thiết kế tuân thủ nguyên tắc Zero-Knowledge:
/// - Admin KHÔNG THỂ xem mật khẩu cá nhân hay bệnh án của người dùng
/// - Admin có quyền: Khóa/Mở khóa, Xóa tài khoản rác/offline quá lâu, Xem lần cuối truy cập
/// - Admin có tab xem và phê duyệt Đơn yêu cầu mở khóa tài khoản
/// - Hỗ trợ phân trang chuẩn 5 mục / trang
class AdminUserManagementView extends StatefulWidget {
  const AdminUserManagementView({super.key});

  @override
  State<AdminUserManagementView> createState() => _AdminUserManagementViewState();
}

class _AdminUserManagementViewState extends State<AdminUserManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Search & Filter cho Tab 1: Danh sách người dùng
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'all'; // 'all', 'active', 'locked'
  int _userCurrentPage = 1;
  static const int _pageSize = 5;

  // Pagination cho Tab 2: Yêu cầu mở khóa
  int _appealCurrentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    UserAccountService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    UserAccountService.instance.removeListener(_onServiceUpdate);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final service = UserAccountService.instance;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 28,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề & giới thiệu chức năng
          _buildHeader(service),
          const SizedBox(height: 16),

          // Banner Zero-Knowledge Security
          _buildZeroKnowledgeSecurityBanner(),
          const SizedBox(height: 20),

          // Tab Bar chuyển đổi giữa 2 phân mục
          _buildTabBar(service),
          const SizedBox(height: 20),

          // Nội dung tab tương ứng
          if (_tabController.index == 0)
            _buildUserListTab(service, isMobile)
          else
            _buildUnlockAppealsTab(service, isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(UserAccountService service) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Quản lý người dùng hệ thống',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D2B6B),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Giám sát tài khoản người dùng, xử lý tài khoản rác/offline lâu ngày và duyệt yêu cầu mở khóa.',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZeroKnowledgeSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyên tắc Bảo mật Quyền riêng tư Y tế (Zero-Knowledge)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hệ thống được thiết kế theo chuẩn Zero-Knowledge: Quản trị viên chỉ có quyền quản lý trạng thái tài khoản (Khóa / Mở khóa / Xóa tài khoản rác) và xem thời gian hoạt động. Quản trị viên TUYỆT ĐỐI KHÔNG THỂ xem mật khẩu cá nhân hay bất kỳ thông tin bệnh án y tế nào của người dùng.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF14532D), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(UserAccountService service) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() {}),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        labelColor: const Color(0xFF2563EB),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Danh sách tài khoản (${service.accounts.length})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_open_rounded, size: 18),
                const SizedBox(width: 8),
                const Text('Yêu cầu mở khóa'),
                if (service.pendingAppealCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${service.pendingAppealCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DANH SÁCH TÀI KHOẢN NGƯỜI DÙNG
  // ===========================================================================

  Widget _buildUserListTab(UserAccountService service, bool isMobile) {
    final allAccounts = service.accounts;

    // Lọc theo search và trạng thái
    final filtered = allAccounts.where((acc) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchQuery = query.isEmpty ||
          acc.username.toLowerCase().contains(query) ||
          (acc.emailOrPhone != null && acc.emailOrPhone!.toLowerCase().contains(query));

      final matchStatus = _statusFilter == 'all' ||
          (_statusFilter == 'active' && !acc.isLocked) ||
          (_statusFilter == 'locked' && acc.isLocked);

      return matchQuery && matchStatus;
    }).toList();

    // Thống kê nhanh
    final totalCount = allAccounts.length;
    final activeCount = allAccounts.where((a) => !a.isLocked).length;
    final lockedCount = allAccounts.where((a) => a.isLocked).length;

    // Phân trang chuẩn 5 mục / trang
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final currentPage = _userCurrentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final pageItems = filtered.skip(startIndex).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thẻ thống kê
        _buildUserStatCards(totalCount, activeCount, lockedCount, isMobile),
        const SizedBox(height: 18),

        // Thanh tìm kiếm và bộ lọc trạng thái
        _buildSearchAndFilters(),
        const SizedBox(height: 14),

        // Danh sách tài khoản
        if (pageItems.isEmpty)
          _buildEmptyUserPlaceholder()
        else
          ...pageItems.map((user) => _buildUserCard(user, service, isMobile)),

        const SizedBox(height: 16),
        // Thanh phân trang
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: filtered.length,
          onPageChanged: (p) => setState(() => _userCurrentPage = p),
        ),
      ],
    );
  }

  Widget _buildUserStatCards(int total, int active, int locked, bool isMobile) {
    final items = [
      _buildStatTile(
        title: 'Tổng người dùng',
        value: '$total',
        icon: Icons.group_outlined,
        color: const Color(0xFF2563EB),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _buildStatTile(
        title: 'Đang hoạt động',
        value: '$active',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF16A34A),
        bgColor: const Color(0xFFF0FDF4),
      ),
      _buildStatTile(
        title: 'Tài khoản bị khóa',
        value: '$locked',
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFFDC2626),
        bgColor: const Color(0xFFFEF2F2),
      ),
    ];

    if (isMobile) {
      return Column(
        children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList(),
      );
    }

    return Row(
      children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w))).toList(),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
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
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() => _userCurrentPage = 1),
              decoration: InputDecoration(
                hintText: 'Tìm theo @username hoặc email/SĐT...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'Tất cả'),
              _buildFilterChip('active', 'Đang hoạt động'),
              _buildFilterChip('locked', 'Đã bị khóa'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _statusFilter = value;
        _userCurrentPage = 1;
      }),
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }

  Widget _buildUserCard(UserAccountModel user, UserAccountService service, bool isMobile) {
    final lastActiveText = _formatRelativeTime(user.lastActiveAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isLocked ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: user.isLocked ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: user.isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                child: Icon(
                  user.isLocked ? Icons.lock_person_rounded : Icons.person_rounded,
                  color: user.isLocked ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.isLocked ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: user.isLocked ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Text(
                            user.isLocked ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: user.isLocked ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Tạo lúc: ${_formatDate(user.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Lần cuối truy cập: $lastActiveText',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getLastActiveColor(user.lastActiveAt),
                              ),
                            ),
                          ],
                        ),
                        if (user.emailOrPhone != null)
                          Text(
                            'Liên hệ: ${user.emailOrPhone}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (user.isLocked && user.lockReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFE11D48)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do khóa: ${user.lockReason}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Các nút hành động
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (!user.isLocked)
                OutlinedButton.icon(
                  onPressed: () => _promptBlockUser(context, user.username),
                  icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text('Khóa tài khoản', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _confirmUnblockUser(context, user.username),
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('Mở khóa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteUser(context, user.username),
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF64748B)),
                label: const Text('Xóa tài khoản', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUserPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: const [
          Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Không tìm thấy tài khoản người dùng nào',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
          SizedBox(height: 4),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc chuyển sang bộ lọc "Tất cả".',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: YÊU CẦU MỞ KHÓA & TRỢ GIÚP
  // ===========================================================================

  Widget _buildUnlockAppealsTab(UserAccountService service, bool isMobile) {
    final appeals = service.appeals;
    final totalPages = (appeals.length / _pageSize).ceil().clamp(1, 999);
    final currentPage = _appealCurrentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final pageItems = appeals.skip(startIndex).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Khi người dùng bị khóa tài khoản đăng nhập vào hệ thống, họ có thể gửi lý do yêu cầu gỡ khóa. Quản trị viên duyệt đơn tại đây để khôi phục quyền truy cập cho họ.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (pageItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF16A34A)),
                SizedBox(height: 12),
                Text(
                  'Hiện không có yêu cầu mở khóa nào cần xử lý',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                SizedBox(height: 4),
                Text(
                  'Tất cả các tài khoản đang hoạt động bình thường hoặc các đơn khiếu nại đã được phê duyệt.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ...pageItems.map((appeal) => _buildAppealCard(appeal, service)),

        const SizedBox(height: 16),
        _buildPaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          totalItems: appeals.length,
          onPageChanged: (p) => setState(() => _appealCurrentPage = p),
        ),
      ],
    );
  }

  Widget _buildAppealCard(UserUnlockAppealModel appeal, UserAccountService service) {
    Color statusBg;
    Color statusFg;
    String statusLabel;

    switch (appeal.status) {
      case 'approved':
        statusBg = const Color(0xFFF0FDF4);
        statusFg = const Color(0xFF16A34A);
        statusLabel = 'ĐÃ MỞ KHÓA';
        break;
      case 'rejected':
        statusBg = const Color(0xFFFEF2F2);
        statusFg = const Color(0xFFDC2626);
        statusLabel = 'ĐÃ TỪ CHỐI';
        break;
      default:
        statusBg = const Color(0xFFFEFCE8);
        statusFg = const Color(0xFFCA8A04);
        statusLabel = 'CHỜ DUYỆT';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appeal.isPending ? const Color(0xFFFDE047) : const Color(0xFFE2E8F0),
          width: appeal.isPending ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle_outlined, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '@${appeal.username}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: statusFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gửi lúc: ${_formatDate(appeal.createdAt)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // Khung lý do người dùng ghi
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
                const Text(
                  'Lý do người dùng muốn mở khóa:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 4),
                Text(
                  appeal.reason,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B), height: 1.35),
                ),
              ],
            ),
          ),

          if (appeal.adminNote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú Admin: ${appeal.adminNote}',
              style: TextStyle(
                fontSize: 12,
                color: appeal.status == 'approved' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          if (appeal.isPending) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _promptRejectAppeal(context, appeal.id),
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text('Từ chối', style: TextStyle(color: Color(0xFFDC2626))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    service.approveUnlockAppeal(appeal.id);
                    _showToast(context, 'Đã phê duyệt và mở khóa tài khoản @${appeal.username}!');
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Phê duyệt mở khóa', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // THANH PHÂN TRANG CHUẨN 5 MỤC / TRANG
  // ===========================================================================

  Widget _buildPaginationBar({
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required ValueChanged<int> onPageChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng: $totalItems bản ghi (5 mục / trang)',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
              ),
              Text(
                'Trang $currentPage / $totalPages',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HỘP THOẠI XỬ LÝ KHÓA / MỞ KHÓA / XÓA
  // ===========================================================================

  void _promptBlockUser(BuildContext context, String username) {
    final reasonCtrl = TextEditingController(text: 'Tài khoản có dấu hiệu bất thường hoặc offline quá lâu.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Color(0xFFDC2626)),
              const SizedBox(width: 8),
              Text('Khóa tài khoản @$username'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Người dùng sẽ không thể đăng nhập cho đến khi được mở khóa.'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do khóa tài khoản',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                UserAccountService.instance.blockUser(
                  username: username,
                  reason: reasonCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                _showToast(context, 'Đã khóa tài khoản @$username.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Xác nhận khóa'),
            ),
          ],
        );
      },
    );
  }

  void _confirmUnblockUser(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mở khóa tài khoản'),
          content: Text('Bạn có chắc chắn muốn mở khóa cho tài khoản @$username?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                UserAccountService.instance.unblockUser(username);
                Navigator.pop(ctx);
                _showToast(context, 'Đã mở khóa tài khoản @$username.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
              child: const Text('Mở khóa ngay'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Xác nhận xóa tài khoản'),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản @$username khỏi hệ thống?\n\n'
            'Hành động này thường dùng để dọn dẹp các tài khoản rác hoặc tài khoản offline quá lâu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                UserAccountService.instance.deleteUser(username);
                Navigator.pop(ctx);
                _showToast(context, 'Đã xóa tài khoản @$username khỏi hệ thống.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Xác nhận xóa'),
            ),
          ],
        );
      },
    );
  }

  void _promptRejectAppeal(BuildContext context, String appealId) {
    final noteCtrl = TextEditingController(text: 'Lý do giải trình không hợp lệ hoặc không đủ căn cứ.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Từ chối yêu cầu mở khóa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập lý do từ chối để phản hồi cho người dùng:'),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Ghi chú lý do', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                UserAccountService.instance.rejectUnlockAppeal(appealId, note: noteCtrl.text.trim());
                Navigator.pop(ctx);
                _showToast(context, 'Đã từ chối yêu cầu mở khóa.');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Từ chối yêu cầu'),
            ),
          ],
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Chưa đăng nhập lần nào';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';
    return '${(diff.inDays / 30).floor()} tháng trước';
  }

  Color _getLastActiveColor(DateTime? dt) {
    if (dt == null) return const Color(0xFF94A3B8);
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 24) return const Color(0xFF16A34A); // Hoạt động gần đây
    if (diff.inDays < 7) return const Color(0xFF2563EB); // Vài ngày trước
    return const Color(0xFFDC2626); // Quá 7 ngày (offline lâu)
  }
}
