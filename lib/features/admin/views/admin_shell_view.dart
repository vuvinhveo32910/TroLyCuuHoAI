// File: lib/views/admin_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_viewmodel.dart';
import 'admin_login_view.dart';
import 'admin_dashboard_view.dart';
import 'admin_feedback_audit_view.dart';
import 'admin_management_views.dart';

class AdminShellView extends StatefulWidget {
  const AdminShellView({super.key});

  @override
  State<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<AdminShellView> {
  final ScrollController _adminHorizontalMenuScrollController =
      ScrollController();

  @override
  void dispose() {
    _adminHorizontalMenuScrollController.dispose();
    super.dispose();
  }

  void _scrollAdminMenuBy(double delta) {
    if (!_adminHorizontalMenuScrollController.hasClients) return;
    final position = _adminHorizontalMenuScrollController.position;
    final targetOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _adminHorizontalMenuScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    if (adminViewModel.currentAdminScreenIndex == 0) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: DangNhapQuanTriView(),
      );
    }

    if (isMobile) {
      return _buildMobileAdminScaffold(context, adminViewModel);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: _buildAdminWorkspaceShell(context, adminViewModel),
    );
  }

  // ===========================================================================
  // GIAO DIỆN MOBILE CHO PHÂN HỆ QUẢN TRỊ (< 768PX)
  // ===========================================================================

  Widget _buildMobileAdminScaffold(
    BuildContext context,
    AdminViewModel viewModel,
  ) {
    final selectedItem =
        viewModel.adminSidebarItems[viewModel.selectedAdminSidebarIndex.clamp(
          0,
          viewModel.adminSidebarItems.length - 1,
        )];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE8EEF5), width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Icon(
                          Icons.favorite,
                          color: Color(0xFF2563EB),
                          size: 32,
                        ),
                        Icon(Icons.add, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quản trị • ${selectedItem.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D2B6B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildAdminUserPopupMenu(context, viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.white,
              child: _buildAdminLeftSidebar(context, viewModel, isWide: false),
            ),
            const Divider(height: 1, color: Color(0xFFE8EEF5)),
            _buildSelectedAdminContent(viewModel),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KHUNG KHÔNG GIAN LÀM VIỆC QUẢN TRỊ TRÊN PC (MÀN HÌNH 10+)
  // ===========================================================================

  Widget _buildAdminWorkspaceShell(
    BuildContext context,
    AdminViewModel viewModel,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        final minShellHeight = (constraints.maxHeight - 32).clamp(
          600.0,
          2000.0,
        );

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 1240,
                  minHeight: minShellHeight,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFBFD),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F0D2B6B),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 245,
                      constraints: BoxConstraints(minHeight: minShellHeight),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFBFD),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE8EEF5), width: 1),
                        ),
                      ),
                      child: _buildAdminLeftSidebar(
                        context,
                        viewModel,
                        isWide: true,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(minHeight: minShellHeight),
                        color: Colors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildAdminTopHeaderBar(context, viewModel),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE8EEF5),
                            ),
                            _buildSelectedAdminContent(viewModel),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1240),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0D2B6B),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAdminTopHeaderBar(context, viewModel),
                  const Divider(height: 1, color: Color(0xFFE8EEF5)),
                  _buildAdminLeftSidebar(context, viewModel, isWide: false),
                  const Divider(height: 1, color: Color(0xFFE8EEF5)),
                  _buildSelectedAdminContent(viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminLeftSidebar(
    BuildContext context,
    AdminViewModel viewModel, {
    required bool isWide,
  }) {
    if (!isWide) {
      // Thanh menu ngang trên Mobile hỗ trợ kéo chuột mượt + 2 nút mũi tên hai đầu
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            _buildMenuScrollArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => _scrollAdminMenuBy(-200),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                controller: _adminHorizontalMenuScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Row(
                  children: List.generate(
                    viewModel.adminSidebarItems.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildAdminSidebarMenuItem(viewModel, index),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildMenuScrollArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _scrollAdminMenuBy(200),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 24),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => viewModel.selectAdminSidebarIndex(1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Icon(
                          Icons.favorite,
                          color: Color(0xFF2563EB),
                          size: 36,
                        ),
                        Icon(Icons.add, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Quản trị',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2B6B),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(viewModel.adminSidebarItems.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildAdminSidebarMenuItem(viewModel, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuScrollArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _buildAdminSidebarMenuItem(AdminViewModel viewModel, int index) {
    final item = viewModel.adminSidebarItems[index];
    final isSelected = viewModel.selectedAdminSidebarIndex == index;

    return Material(
      color: isSelected ? const Color(0xFFE8F1FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => viewModel.selectAdminSidebarIndex(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF334155),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.hasTrailingChevron) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTopHeaderBar(
    BuildContext context,
    AdminViewModel viewModel,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: Colors.white,
      alignment: Alignment.centerRight,
      child: _buildAdminUserPopupMenu(context, viewModel),
    );
  }

  Widget _buildAdminUserPopupMenu(
    BuildContext context,
    AdminViewModel viewModel,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'profile') {
          final idx = viewModel.adminSidebarItems.indexWhere((i) => i.id == 'admin_profile');
          if (idx != -1) {
            viewModel.selectAdminSidebarIndex(idx);
          }
        } else if (value == 'user_app') {
          viewModel.exitAdminPortalToUserApp();
        } else if (value == 'logout') {
          viewModel.logoutAdmin();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Hồ sơ tài khoản'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'user_app',
          child: Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: Color(0xFF475569)),
              SizedBox(width: 10),
              Text('Về giao diện Người dùng'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
              SizedBox(width: 10),
              Text(
                'Đăng xuất Quản trị',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.person, size: 20, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 8),
            Text(
              viewModel.currentAdminSession.username.isNotEmpty
                  ? viewModel.currentAdminSession.username
                  : 'admin',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAdminContent(AdminViewModel viewModel) {
    final items = viewModel.adminSidebarItems;
    final selectedIndex = viewModel.selectedAdminSidebarIndex;

    if (items.isEmpty) {
      return const DashboardQuanTriView();
    }

    final safeIndex = selectedIndex.clamp(0, items.length - 1);
    final selectedItem = items[safeIndex];

    switch (selectedItem.id) {
      case 'dashboard':
        return const DashboardQuanTriView();
      case 'ai_feedback_audit':
        return const AdminAiFeedbackAuditView();
      case 'knowledge_base':
        return const AdminKnowledgeBaseView();
      case 'injury_types':
        return const AdminInjuryTypesView();
      case 'rule_engine':
        return const AdminRuleEngineView();
      case 'history_analytics':
        return const AdminHistoryAnalyticsView();
      case 'user_management':
        return const AdminUserManagementView();
      case 'admin_profile':
        return const AdminProfileView();
      case 'settings':
        return const AdminSettingsView();
      default:
        return const DashboardQuanTriView();
    }
  }
}
