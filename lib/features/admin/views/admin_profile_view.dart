// File: lib/features/admin/views/admin_profile_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_viewmodel.dart';

/// Màn hình Quản lý hồ sơ tài khoản Quản trị viên (/admin)
/// Cho phép xem và thay đổi: Tên hiển thị, Mật khẩu, Email nhận OTP quên mật khẩu
class AdminProfileView extends StatefulWidget {
  const AdminProfileView({super.key});

  @override
  State<AdminProfileView> createState() => _AdminProfileViewState();
}

class _AdminProfileViewState extends State<AdminProfileView> {
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _emailCtrl;

  late final TextEditingController _currentPassCtrl;
  late final TextEditingController _newPassCtrl;
  late final TextEditingController _confirmPassCtrl;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AdminViewModel>();
    _displayNameCtrl = TextEditingController(text: vm.adminProfile.displayName);
    _emailCtrl = TextEditingController(text: vm.adminProfile.email);
    _currentPassCtrl = TextEditingController();
    _newPassCtrl = TextEditingController();
    _confirmPassCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final profile = viewModel.adminProfile;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
        vertical: isMobile ? 18 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header tiêu đề trang
          _buildHeader(),
          const SizedBox(height: 20),

          // Thẻ thông tin tổng quan hồ sơ
          _buildOverviewCard(profile),
          const SizedBox(height: 24),

          // Hai cột (hoặc xếp chồng trên Mobile): Chỉnh sửa thông tin & Đổi mật khẩu
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileInfoForm(viewModel)),
                const SizedBox(width: 20),
                Expanded(child: _buildChangePasswordForm(viewModel)),
              ],
            )
          else ...[
            _buildProfileInfoForm(viewModel),
            const SizedBox(height: 20),
            _buildChangePasswordForm(viewModel),
          ],

          const SizedBox(height: 24),
          // Thẻ lưu ý kết nối Supabase Auth
          _buildSupabaseAuthNoticeCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Hồ sơ tài khoản Quản trị',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0D2B6B),
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Quản lý thông tin cá nhân của Quản trị viên, đổi mật khẩu và thiết lập Email nhận mã OTP khôi phục.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(dynamic profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        profile.roleLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          'Tài khoản: @${profile.username}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          profile.email,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(
                          profile.lastLoginAt != null
                              ? 'Lần đăng nhập gần nhất: ${_formatDate(profile.lastLoginAt)}'
                              : 'Lần đầu đăng nhập',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoForm(AdminViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Text(
                'Thông tin cơ bản',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tên hiển thị',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _displayNameCtrl,
            decoration: InputDecoration(
              hintText: 'Nhập tên hiển thị quản trị...',
              prefixIcon: const Icon(Icons.badge_outlined, size: 19),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Email nhận mã OTP (Quên mật khẩu)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Khi bạn hoặc quản trị viên khác bấm "Quên mật khẩu?" tại màn hình đăng nhập, mã xác thực 6 số sẽ được gửi về hộp thư này.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            decoration: InputDecoration(
              hintText: 'admin.support@example.com',
              prefixIcon: const Icon(Icons.mark_email_read_outlined, size: 19),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () {
              final err = viewModel.updateAdminProfile(
                displayName: _displayNameCtrl.text,
                email: _emailCtrl.text,
              );
              if (err != null) {
                _showToast(context, err, isError: true);
              } else {
                _showToast(context, 'Cập nhật thông tin Quản trị viên thành công!');
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm(AdminViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.password_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 10),
              Text(
                'Đổi mật khẩu Quản trị',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Mật khẩu hiện tại',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _currentPassCtrl,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu hiện tại...',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mật khẩu mới (ít nhất 6 ký tự)',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _newPassCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu mới...',
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Xác nhận mật khẩu mới',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Nhập lại mật khẩu mới...',
              prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 19),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () {
              final err = viewModel.changeAdminPassword(
                currentPassword: _currentPassCtrl.text,
                newPassword: _newPassCtrl.text,
                confirmPassword: _confirmPassCtrl.text,
              );
              if (err != null) {
                _showToast(context, err, isError: true);
              } else {
                _currentPassCtrl.clear();
                _newPassCtrl.clear();
                _confirmPassCtrl.clear();
                _showToast(context, 'Đổi mật khẩu Quản trị viên thành công!');
              }
            },
            icon: const Icon(Icons.lock_outline_rounded, size: 18),
            label: const Text('Cập nhật mật khẩu', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupabaseAuthNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 24),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cơ chế cấp phát tài khoản Admin với Supabase Auth',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Khi dự án gắn cơ sở dữ liệu Supabase, các tài khoản Quản trị viên sẽ được khởi tạo trực tiếp qua Supabase Auth Dashboard hoặc lời mời từ Super Admin để đảm bảo an toàn tuyệt đối, tránh việc tự đăng ký tài khoản quản trị ngoài ý muốn.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
