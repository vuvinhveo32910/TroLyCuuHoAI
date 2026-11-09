import '../../../../core/storage/local_storage_service.dart';
import 'package:flutter/material.dart';

import '../../../../core/user_management/user_account_service.dart';
import '../../viewmodels/user_viewmodel.dart';

class UserAuthModalDialog extends StatefulWidget {
  final UserViewModel viewModel;

  const UserAuthModalDialog({super.key, required this.viewModel});

  @override
  State<UserAuthModalDialog> createState() => _UserAuthModalDialogState();
}

class _UserAuthModalDialogState extends State<UserAuthModalDialog> {
  int _activeTab = 0; // 0 = Đăng nhập, 1 = Đăng ký, 2 = Quên mật khẩu
  bool _rememberMe = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedUserCredentials();
  }

  Future<void> _loadSavedUserCredentials() async {
    final saved = await LocalStorageService.instance.loadUserCredentials();
    if (mounted) {
      _rememberMe = saved['rememberMe'] as bool? ?? true;
      if (saved['username'] != null && (saved['username'] as String).isNotEmpty) {
        _loginUserCtrl.text = saved['username'] as String;
      }
      if (saved['password'] != null && (saved['password'] as String).isNotEmpty) {
        _loginPassCtrl.text = saved['password'] as String;
      }
      setState(() {});
    }
  }

  // Controllers cho Đăng nhập
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _obscureLoginPass = true;

  // Controllers cho Đăng ký (Tuyệt đối không thu thập họ tên, SĐT, địa chỉ)
  final _regUserCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  bool _obscureRegPass = true;
  bool _obscureRegConfirm = true;

  // Controllers cho Quên mật khẩu (Xác thực OTP)
  final _forgotIdentifierCtrl = TextEditingController();
  final _forgotOtpCtrl = TextEditingController();
  final _forgotNewPassCtrl = TextEditingController();
  final _forgotConfirmPassCtrl = TextEditingController();
  bool _obscureForgotNewPass = true;
  bool _obscureForgotConfirm = true;
  bool _isOtpSent = false;
  String? _forgotTargetEmail;
  String? _demoOtpHint;

  // Trạng thái tài khoản bị khóa và khiếu nại mở khóa
  bool _isLockedAccount = false;
  String _lockedUsername = '';
  String _lockedReason = '';
  final _appealReasonCtrl = TextEditingController();

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _forgotIdentifierCtrl.dispose();
    _forgotOtpCtrl.dispose();
    _forgotNewPassCtrl.dispose();
    _forgotConfirmPassCtrl.dispose();
    _appealReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLockedAccount = false;
    });
    final user = _loginUserCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng điền đầy đủ tài khoản và mật khẩu.');
      return;
    }

    final error = await widget.viewModel.loginWithCredentials(
      username: user,
      password: pass,
      rememberMe: _rememberMe,
    );
    if (error != null) {
      if (error.startsWith('TÀI_KHOẢN_BỊ_KHÓA:')) {
        setState(() {
          _isLockedAccount = true;
          _lockedUsername = user;
          _lockedReason = error.replaceFirst('TÀI_KHOẢN_BỊ_KHÓA:', '').trim();
          _errorMessage = null;
        });
      } else {
        setState(() => _errorMessage = error);
      }
    } else {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Đăng nhập thành công! Chào mừng ${widget.viewModel.currentUserName}.'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLockedAccount = false;
      _isGoogleLoading = true;
    });

    try {
      String? error = await widget.viewModel.loginWithGoogle();
      if (!mounted) return;

      // Nếu Supabase Google Provider chưa bật trên Dashboard (external.google == false),
      // mở hộp thoại Chọn / Nhập tài khoản Google trực tiếp ngay trong ứng dụng
      if (error == 'GOOGLE_ACCOUNT_CHOOSER_REQUIRED') {
        setState(() => _isGoogleLoading = false);
        final selectedAccount = await _showGoogleAccountChooserDialog();
        if (!mounted) return;
        if (selectedAccount == null) {
          // Người dùng đóng hộp thoại chọn tài khoản Google
          return;
        }
        setState(() => _isGoogleLoading = true);
        error = await widget.viewModel.loginWithGoogleAccount(
          email: selectedAccount['email']!,
          displayName: selectedAccount['displayName'],
        );
        if (!mounted) return;
      }

      if (error != null) {
        if (error.startsWith('TÀI_KHOẢN_BỊ_KHÓA:')) {
          final lockedUser = UserAccountService.instance.accounts
                  .where((a) => a.isLocked)
                  .lastOrNull
                  ?.username ??
              widget.viewModel.currentUsername ??
              'Tài khoản Google';
          setState(() {
            _isLockedAccount = true;
            _lockedUsername = lockedUser;
            _lockedReason = error!.replaceFirst('TÀI_KHOẢN_BỊ_KHÓA:', '').trim();
            _errorMessage = null;
          });
        } else {
          setState(() => _errorMessage = error);
        }
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text('Đăng nhập thành công! Chào mừng ${widget.viewModel.currentUserName}.'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Giao diện Google Account Chooser (tương tự Shopee `accounts.google.com/v3/signin/accountchooser`)
  /// Hiển thị danh sách tài khoản Google hiện có kèm tùy chọn "Use another account / Sử dụng một tài khoản khác"
  Future<Map<String, String>?> _showGoogleAccountChooserDialog() async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String? dialogError;

    final existingGoogleAccounts = UserAccountService.instance.accounts
        .where(
          (a) =>
              a.emailOrPhone != null &&
              a.emailOrPhone!.trim().contains('@'),
        )
        .toList();

    bool showAddAccountForm = existingGoogleAccounts.isEmpty;

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: [G] Sign in with Google (giống Shopee Google Chooser)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                        child: Row(
                          children: [
                            _buildGoogleLogo(),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3C4043),
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: Color(0xFF5F6368),
                              ),
                              onPressed: () => Navigator.pop(dialogCtx),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE0E0E0)),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Biểu tượng ứng dụng
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Choose an account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF202124),
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF202124),
                                ),
                                children: [
                                  TextSpan(text: 'to continue to '),
                                  TextSpan(
                                    text: 'Trợ lý Cứu hộ AI',
                                    style: TextStyle(
                                      color: Color(0xFF1A73E8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Danh sách tài khoản Google hiện có (giống Shopee)
                            if (existingGoogleAccounts.isNotEmpty) ...[
                              ...existingGoogleAccounts.take(4).map((acc) {
                                final mail = acc.emailOrPhone!.trim();
                                final name = acc.fullName.trim().isNotEmpty
                                    ? acc.fullName.trim()
                                    : acc.username;
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.pop(dialogCtx, {
                                        'email': mail,
                                        'displayName': name,
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: const Color(
                                                0xFF1A73E8,
                                              ),
                                              child: Text(
                                                mail[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF3C4043),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    mail,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      color: Color(0xFF5F6368),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFE8EAED),
                                    ),
                                  ],
                                );
                              }),
                            ],

                            // Hàng "Use another account / Sử dụng một tài khoản khác"
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  showAddAccountForm = !showAddAccountForm;
                                  dialogError = null;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 36,
                                      child: Icon(
                                        Icons.account_circle_outlined,
                                        size: 24,
                                        color: Color(0xFF5F6368),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Use another account (Sử dụng tài khoản khác)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF3C4043),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE8EAED)),

                            // Biểu mẫu nhập tài khoản Gmail mới khi bấm "Use another account"
                            if (showAddAccountForm) ...[
                              const SizedBox(height: 16),
                              if (dialogError != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    dialogError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFD93025),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email hoặc Gmail',
                                  hintText: 'nguyenvana@gmail.com',
                                  prefixIcon: const Icon(
                                    Icons.mail_outline_rounded,
                                    size: 20,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nameCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Tên hiển thị Google (Tùy chọn)',
                                  hintText: 'Nguyễn Văn A',
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final mail = emailCtrl.text
                                        .trim()
                                        .toLowerCase();
                                    if (mail.isEmpty ||
                                        !mail.contains('@') ||
                                        !mail.contains('.')) {
                                      setDialogState(() {
                                        dialogError =
                                            'Vui lòng nhập địa chỉ Gmail hợp lệ (ví dụ: tenban@gmail.com).';
                                      });
                                      return;
                                    }
                                    final disp =
                                        nameCtrl.text.trim().isNotEmpty
                                        ? nameCtrl.text.trim()
                                        : mail.split('@').first;
                                    Navigator.pop(dialogCtx, {
                                      'email': mail,
                                      'displayName': disp,
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A73E8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tiếp tục (Next)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            const Text(
                              'Trước khi sử dụng ứng dụng này, bạn có thể xem Chính sách quyền riêng tư và Điều khoản dịch vụ của Trợ lý Cứu hộ AI.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5F6368),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildGoogleLogo() {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: const Size(18, 18),
        painter: const _GoogleLogoPainter(),
      ),
    );
  }

  void _handleSubmitUnlockAppeal() {
    final reason = _appealReasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập lý do muốn mở khóa tài khoản.');
      return;
    }

    UserAccountService.instance.submitUnlockAppeal(
      username: _lockedUsername,
      reason: reason,
    );

    setState(() {
      _isLockedAccount = false;
      _appealReasonCtrl.clear();
      _errorMessage = null;
      _successMessage = 'Đã gửi yêu cầu gỡ khóa tài khoản @$_lockedUsername tới Quản trị viên! Vui lòng chờ phê duyệt.';
    });
  }

  void _handleRegister() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    final user = _regUserCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    final confirm = _regConfirmPassCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng điền tên tài khoản và mật khẩu.');
      return;
    }

    if (pass != confirm) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không trùng khớp.');
      return;
    }

    final error = widget.viewModel.registerUser(
      username: user,
      password: pass,
      emailOrPhone: email.isNotEmpty ? email : null,
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Đăng ký tài khoản thành công! Dữ liệu cá nhân đã được liên kết.'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleRequestOtp() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    final id = _forgotIdentifierCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên tài khoản hoặc email của bạn.');
      return;
    }

    final res = widget.viewModel.requestPasswordResetOtp(id);
    if (res['success'] != true) {
      setState(() => _errorMessage = res['message'] as String? ?? 'Gửi OTP thất bại.');
    } else {
      setState(() {
        _isOtpSent = true;
        _forgotTargetEmail = res['targetEmail'] as String?;
        _demoOtpHint = res['otp'] as String?;
        _successMessage = 'Mã OTP 6 số đã được gửi đến $_forgotTargetEmail (Mã demo: $_demoOtpHint).';
      });
    }
  }

  void _handleVerifyAndResetPassword() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    final id = _forgotIdentifierCtrl.text.trim();
    final otp = _forgotOtpCtrl.text.trim();
    final newPass = _forgotNewPassCtrl.text.trim();
    final confirm = _forgotConfirmPassCtrl.text.trim();

    if (otp.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã OTP và mật khẩu mới.');
      return;
    }
    if (newPass != confirm) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không trùng khớp.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }

    final error = widget.viewModel.verifyAndResetPassword(
      identifier: id,
      otp: otp,
      newPassword: newPass,
    );

    if (error != null) {
      setState(() => _errorMessage = error);
    } else {
      setState(() {
        _activeTab = 0;
        _loginUserCtrl.text = id;
        _loginPassCtrl.text = newPass;
        _isOtpSent = false;
        _errorMessage = null;
        _successMessage = 'Đổi mật khẩu thành công! Bạn có thể bấm Đăng nhập ngay.';
        _forgotOtpCtrl.clear();
        _forgotNewPassCtrl.clear();
        _forgotConfirmPassCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Đổi mật khẩu thành công!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _activeTab = index;
          _errorMessage = null;
          _successMessage = null;
        }),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 470),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tiêu đề & nút đóng
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _activeTab == 2 ? Icons.lock_reset_rounded : Icons.account_circle_rounded,
                      color: const Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeTab == 0
                              ? 'Đăng nhập người dùng'
                              : (_activeTab == 1 ? 'Đăng ký tài khoản mới' : 'Khôi phục mật khẩu'),
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D2B6B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _activeTab == 2
                              ? 'Xác thực OTP qua Email để đặt lại mật khẩu mới'
                              : 'Lưu trữ dữ liệu lịch sử phân tích khi đổi thiết bị',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ℹ️ BẢNG LƯU Ý
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đăng ký tài khoản nếu muốn lưu dữ liệu cá nhân',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF166534),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab chuyển đổi Đăng nhập / Đăng ký / Quên MK
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Đăng nhập'),
                    _buildTabButton(1, 'Đăng ký mới'),
                    _buildTabButton(2, 'Quên MK'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Báo lỗi nếu có
              if (_errorMessage != null) ...[
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
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Báo thành công nếu có
              if (_successMessage != null) ...[
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
                          _successMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ===============================================================
              // NỘI DUNG TAB 0: ĐĂNG NHẬP
              // ===============================================================
              if (_activeTab == 0) ...[
                if (_isLockedAccount) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lock_person_rounded, color: Color(0xFFDC2626), size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tài khoản của bạn đã bị khóa',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lý do: $_lockedReason',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Gửi yêu cầu mở khóa tài khoản:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _appealReasonCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Nhập lý do hoặc giải trình bạn muốn mở khóa...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isLockedAccount = false),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _handleSubmitUnlockAppeal,
                              icon: const Icon(Icons.send_rounded, size: 14),
                              label: const Text('Gửi yêu cầu gỡ khóa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _loginUserCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên tài khoản',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPassCtrl,
                  obscureText: _obscureLoginPass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureLoginPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscureLoginPass = !_obscureLoginPass),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ghi nhớ đăng nhập',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _activeTab = 2;
                        _errorMessage = null;
                        _successMessage = null;
                        if (_loginUserCtrl.text.isNotEmpty) {
                          _forgotIdentifierCtrl.text = _loginUserCtrl.text;
                        }
                      }),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đăng nhập', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 14),
                // Đường phân cách "hoặc"
                Row(
                  children: const [
                    Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'hoặc',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                  ],
                ),
                const SizedBox(height: 14),
                // Nút Đăng nhập bằng Google
                OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGoogleLogo(),
                            const SizedBox(width: 10),
                            const Text(
                              'Đăng nhập bằng Google',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _activeTab = 1;
                    _errorMessage = null;
                    _successMessage = null;
                  }),
                  child: const Text(
                    'Chưa có tài khoản? Bấm vào đây để đăng ký',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF2563EB)),
                  ),
                ),
              ],

              // ===============================================================
              // NỘI DUNG TAB 1: ĐĂNG KÝ
              // ===============================================================
              if (_activeTab == 1) ...[
                // Banner nhấn mạnh không thu thập danh tính cá nhân
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bảo mật danh tính: Hệ thống tuyệt đối không yêu cầu họ tên, SĐT hay địa chỉ cư trú của bạn.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _regUserCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tên tài khoản (ít nhất 3 ký tự)',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _regEmailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email (Tùy chọn - Dùng khi cần nhận OTP đổi mật khẩu)',
                    hintText: 'Để trống nếu không có nhu cầu khôi phục',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _regPassCtrl,
                  obscureText: _obscureRegPass,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRegPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _regConfirmPassCtrl,
                  obscureText: _obscureRegConfirm,
                  decoration: InputDecoration(
                    labelText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureRegConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscureRegConfirm = !_obscureRegConfirm),
                    ),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tạo tài khoản & Đăng nhập ngay', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() {
                    _activeTab = 0;
                    _errorMessage = null;
                    _successMessage = null;
                  }),
                  child: const Text(
                    'Đã có tài khoản? Bấm vào đây để đăng nhập',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF2563EB)),
                  ),
                ),
              ],

              // ===============================================================
              // NỘI DUNG TAB 2: QUÊN MẬT KHẨU (XÁC THỰC OTP QUA EMAIL)
              // ===============================================================
              if (_activeTab == 2) ...[
                if (!_isOtpSent) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.mark_email_unread_outlined, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nhập tên tài khoản hoặc email để nhận mã OTP 6 chữ số khôi phục mật khẩu.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _forgotIdentifierCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên tài khoản hoặc Email',
                      hintText: 'Nhập tên tài khoản hoặc email đã đăng ký',
                      prefixIcon: const Icon(Icons.account_circle_outlined, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _handleRequestOtp,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Gửi mã OTP qua Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mã OTP đã gửi đến: ${_forgotTargetEmail ?? ""}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                              ),
                            ),
                          ],
                        ),
                        if (_demoOtpHint != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              '🔑 Mã OTP xác thực thử nghiệm: $_demoOtpHint',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _forgotOtpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mã xác thực OTP (6 chữ số)',
                      prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _forgotNewPassCtrl,
                    obscureText: _obscureForgotNewPass,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureForgotNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _obscureForgotNewPass = !_obscureForgotNewPass),
                      ),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _forgotConfirmPassCtrl,
                    obscureText: _obscureForgotConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận lại mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureForgotConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                        onPressed: () => setState(() => _obscureForgotConfirm = !_obscureForgotConfirm),
                      ),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleVerifyAndResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xác nhận & Cập nhật mật khẩu mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isOtpSent = false),
                        child: const Text('Gửi lại mã OTP khác', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _activeTab = 0;
                          _errorMessage = null;
                          _successMessage = null;
                        }),
                        child: const Text('Quay lại Đăng nhập', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                ],
              ],

              const Divider(height: 24),
              // Nút tiếp tục với vai trò khách
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tiếp tục với vai trò Khách (Không đăng nhập)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Thanh ngang chữ G
    final barRect = Rect.fromLTWH(
      center.dx - 1,
      center.dy - strokeWidth / 2,
      radius - strokeWidth / 2 + 1,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);

    final arcRect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Vòm xanh lam (trên cùng bên phải)
    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.785, 0.785, false, arcPaint);

    // Vòm xanh lá (phía dưới)
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.0, 1.85, false, arcPaint);

    // Vòm vàng (dưới cùng bên trái)
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 1.85, 1.45, false, arcPaint);

    // Vòm đỏ (trên cùng)
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, 3.3, 2.2, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

