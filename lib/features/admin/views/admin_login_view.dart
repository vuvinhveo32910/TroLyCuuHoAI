import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_painters.dart';

class DangNhapQuanTriView extends StatefulWidget {
  const DangNhapQuanTriView({super.key});

  @override
  State<DangNhapQuanTriView> createState() => _DangNhapQuanTriViewState();
}

class _DangNhapQuanTriViewState extends State<DangNhapQuanTriView> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AdminViewModel>();
    _usernameController = TextEditingController(text: vm.usernameInput);
    _passwordController = TextEditingController(text: vm.passwordInput);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final vm = context.read<AdminViewModel>();
    await vm.loadSavedAdminCredentials();
    if (mounted) {
      if (vm.usernameInput.isNotEmpty && _usernameController.text.isEmpty) {
        _usernameController.text = vm.usernameInput;
      }
      if (vm.passwordInput.isNotEmpty && _passwordController.text.isEmpty) {
        _passwordController.text = vm.passwordInput;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = context.watch<AdminViewModel>();
    final spec = adminViewModel.loginSpec;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    // Tự động đồng bộ tài khoản đã ghi nhớ vào ô nhập
    if (adminViewModel.usernameInput.isNotEmpty && _usernameController.text.isEmpty) {
      _usernameController.text = adminViewModel.usernameInput;
    }
    if (adminViewModel.passwordInput.isNotEmpty && _passwordController.text.isEmpty) {
      _passwordController.text = adminViewModel.passwordInput;
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: isMobile ? 16 : 24,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 980),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120D2B6B),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: const AdminLoginWaveBackgroundPainter(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildLeftLoginForm(
                            context,
                            adminViewModel,
                            spec,
                            isMobile: false,
                          ),
                        ),
                        Container(
                          width: 1,
                          color: const Color(0xFFE8EEF7),
                        ),
                        Expanded(
                          flex: 5,
                          child: _buildRightIllustrationPanel(
                            spec,
                            isMobile: false,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLeftLoginForm(
                      context,
                      adminViewModel,
                      spec,
                      isMobile: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EEF7)),
                    _buildRightIllustrationPanel(spec, isMobile: true),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftLoginForm(
    BuildContext context,
    AdminViewModel viewModel,
    dynamic spec, {
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 22 : 44,
        vertical: isMobile ? 26 : 42,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Icon(Icons.favorite, color: Color(0xFF2563EB), size: 32),
                    Icon(Icons.add, color: Colors.white, size: 16),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.brandTitle,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0D2B6B),
                      ),
                    ),
                    Text(
                      spec.brandSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: viewModel.exitAdminPortalToUserApp,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Người dùng'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 22 : 32),
          Text(
            spec.formTitle,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D2B6B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            spec.usernameLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            onChanged: viewModel.updateUsername,
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: spec.usernameHint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD8E2EE),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            spec.passwordLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            onChanged: viewModel.updatePassword,
            obscureText: viewModel.isPasswordObscured,
            onSubmitted: (_) => viewModel.submitAdminLogin(),
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: spec.passwordHint,
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              suffixIcon: IconButton(
                onPressed: viewModel.togglePasswordVisibility,
                icon: Icon(
                  viewModel.isPasswordObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF475569),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFFD8E2EE),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => viewModel.toggleRememberMe(!viewModel.rememberMe),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: viewModel.rememberMe,
                        onChanged: viewModel.toggleRememberMe,
                        activeColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      spec.rememberMeLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showForgotPasswordDialog(context, viewModel),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          if (viewModel.loginFeedbackMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: viewModel.isLoginError
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: viewModel.isLoginError
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    viewModel.isLoginError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: viewModel.isLoginError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viewModel.loginFeedbackMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: viewModel.isLoginError
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: isMobile ? 18 : 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                viewModel.updateUsername(_usernameController.text);
                viewModel.updatePassword(_passwordController.text);
                viewModel.submitAdminLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                spec.loginButtonLabel,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightIllustrationPanel(dynamic spec, {required bool isMobile}) {
    return Container(
      color: const Color(0xFFF8FAFD),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 22 : 44,
        vertical: isMobile ? 28 : 42,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 68,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            spec.rightPanelTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2B6B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.rightPanelSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp thoại Quên mật khẩu Quản trị viên (Gửi OTP qua email cấu hình trong /admin)
  void _showForgotPasswordDialog(BuildContext context, AdminViewModel viewModel) {
    final identifierCtrl = TextEditingController(text: _usernameController.text.trim());
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    int step = 1; // 1: Nhập tài khoản/email nhận OTP, 2: Nhập OTP & Mật khẩu mới
    String? feedbackError;
    String? feedbackSuccess;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String targetEmail = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF2563EB),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Khôi phục mật khẩu Quản trị',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D2B6B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step == 1
                                      ? 'Bước 1: Xác định tài khoản quản trị'
                                      : 'Bước 2: Xác thực OTP & Thiết lập mật khẩu mới',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Thông báo lỗi / thành công
                      if (feedbackError != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feedbackError!,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (feedbackSuccess != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feedbackSuccess!,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Nội dung Bước 1
                      if (step == 1) ...[
                        const Text(
                          'Nhập tên tài khoản hoặc địa chỉ email quản trị đã đăng ký trong mục Hồ sơ tài khoản:',
                          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: identifierCtrl,
                          decoration: InputDecoration(
                            labelText: 'Tài khoản hoặc Email Admin',
                            hintText: 'admin hoặc email@domain.com',
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              feedbackError = null;
                              feedbackSuccess = null;
                            });
                            final input = identifierCtrl.text.trim();
                            if (input.isEmpty) {
                              setDialogState(() => feedbackError = 'Vui lòng nhập tài khoản hoặc email.');
                              return;
                            }
                            final res = viewModel.requestAdminPasswordResetOtp(input);
                            if (res['success'] == true) {
                              setDialogState(() {
                                step = 2;
                                targetEmail = res['targetEmail'] as String? ?? '';
                                feedbackSuccess = 'Mã OTP gồm 6 chữ số đã được gửi tới $targetEmail.';
                              });
                            } else {
                              setDialogState(() => feedbackError = res['message'] as String? ?? 'Yêu cầu không thành công.');
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Gửi mã OTP xác nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],

                      // Nội dung Bước 2
                      if (step == 2) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            'Email nhận mã: $targetEmail (Kiểm tra cả hòm thư Spam nếu chưa thấy)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: 'Mã xác thực OTP (6 chữ số)',
                            hintText: 'Nhập mã 6 số...',
                            prefixIcon: const Icon(Icons.key_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPassCtrl,
                          obscureText: obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPassCtrl,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => setDialogState(() {
                                step = 1;
                                feedbackError = null;
                                feedbackSuccess = null;
                              }),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Quay lại'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    feedbackError = null;
                                    feedbackSuccess = null;
                                  });
                                  final otp = otpCtrl.text.trim();
                                  final newPass = newPassCtrl.text.trim();
                                  final confirmPass = confirmPassCtrl.text.trim();

                                  if (otp.length != 6) {
                                    setDialogState(() => feedbackError = 'Mã OTP phải có đúng 6 chữ số.');
                                    return;
                                  }

                                  final res = viewModel.verifyAdminOtpAndResetPassword(
                                    otp: otp,
                                    newPassword: newPass,
                                    confirmPassword: confirmPass,
                                  );

                                  if (res['success'] == true) {
                                    Navigator.pop(dialogCtx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(res['message'] as String)),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF16A34A),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  } else {
                                    setDialogState(() => feedbackError = res['message'] as String? ?? 'Xác thực OTP thất bại.');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
