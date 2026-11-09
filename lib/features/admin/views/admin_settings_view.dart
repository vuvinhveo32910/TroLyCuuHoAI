import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/email/email_config_service.dart';
import '../../../core/gemini/gemini_config_model.dart';
import '../../../core/gemini/gemini_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/url_launcher_helper.dart';
import '../viewmodels/admin_viewmodel.dart';
import 'widgets/admin_pagination_footer.dart';

// =============================================================================
// 6. VIEW CẤU HÌNH HỆ THỐNG (Settings & Google Gemini API)
// =============================================================================
class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  late TextEditingController _apiKeyController;
  late TextEditingController _promptController;
  late TextEditingController _maxTokensController;
  late bool _geminiEnabled;
  bool _obscureApiKey = true;

  bool _isTestingGemini = false;
  bool _isPingingSupabase = false;
  String? _supabasePingMessage;
  bool? _supabasePingSuccess;

  Future<void> _pingSupabase() async {
    setState(() {
      _isPingingSupabase = true;
      _supabasePingMessage = null;
    });

    final res = await SupabaseService.instance.pingConnection();

    if (mounted) {
      setState(() {
        _isPingingSupabase = false;
        _supabasePingSuccess = res['success'] == true;
        _supabasePingMessage = res['message'] as String?;
      });
    }
  }
  GeminiTestResult? _geminiTestResult;

  // Phân trang nhật ký gửi Email (5 dòng / trang)
  int _currentEmailLogPage = 1;
  static const int _emailLogPageSize = 5;

  // Cấu hình dịch vụ Email & Khôi phục mật khẩu (Supabase Cloud)
  late TextEditingController _smtpHostController;
  late TextEditingController _smtpPortController;
  late TextEditingController _senderEmailController;
  late TextEditingController _senderNameController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _otpExpiryController;
  late TextEditingController _emailSubjectController;
  late bool _emailEnabled;
  bool _obscureSmtpPassword = true;

  @override
  void initState() {
    super.initState();
    final config = GeminiService.instance.config;
    _apiKeyController = TextEditingController(text: config.apiKey);
    _promptController = TextEditingController(text: config.systemInstruction);
    _maxTokensController = TextEditingController(text: config.maxTokens.toString());
    _geminiEnabled = config.isEnabled;

    final emailCfg = EmailConfigService.instance.config;
    _smtpHostController = TextEditingController(text: emailCfg.smtpHost);
    _smtpPortController = TextEditingController(text: emailCfg.smtpPort.toString());
    _senderEmailController = TextEditingController(text: emailCfg.senderEmail);
    _senderNameController = TextEditingController(text: emailCfg.senderName);
    _smtpPasswordController = TextEditingController(text: emailCfg.smtpPassword);
    _otpExpiryController = TextEditingController(text: emailCfg.otpExpiryMinutes.toString());
    _emailSubjectController = TextEditingController(text: emailCfg.emailSubject);
    _emailEnabled = emailCfg.isEnabled;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _promptController.dispose();
    _maxTokensController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _senderEmailController.dispose();
    _senderNameController.dispose();
    _smtpPasswordController.dispose();
    _otpExpiryController.dispose();
    _emailSubjectController.dispose();
    super.dispose();
  }

  Future<void> _pasteApiKeyFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _apiKeyController.text = data.text!.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã dán API Key từ bộ nhớ tạm thành công!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bộ nhớ tạm (Clipboard) không có văn bản!'),
            backgroundColor: Color(0xFFF59E0B),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _resetSystemPromptToStandard() {
    setState(() {
      _promptController.text = defaultWoundCareSystemInstruction;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã khôi phục System Prompt chuẩn y khoa cho 4 nhóm vết thương!'),
          backgroundColor: Color(0xFF2563EB),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testGeminiConnection(AdminViewModel viewModel) async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập API Key trước khi kiểm tra kết nối!'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isTestingGemini = true;
      _geminiTestResult = null;
    });

    final result = await viewModel.testGeminiConnection(
      apiKey: apiKey,
      model: 'gemini-3.8-flash',
    );

    if (!mounted) return;
    setState(() {
      _isTestingGemini = false;
      _geminiTestResult = result;
    });
  }

  void _saveGeminiConfiguration(AdminViewModel viewModel) {
    final maxTok = int.tryParse(_maxTokensController.text.trim()) ?? 1024;
    final newConfig = GeminiConfigModel(
      isEnabled: _geminiEnabled,
      apiKey: _apiKeyController.text.trim(),
      selectedModel: 'gemini-3.8-flash',
      systemInstruction: _promptController.text.trim().isEmpty
          ? defaultWoundCareSystemInstruction
          : _promptController.text.trim(),
      temperature: 0.4,
      maxTokens: maxTok,
    );

    viewModel.updateGeminiConfig(newConfig);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã lưu cấu hình Google Gemini API thành công!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _saveEmailConfiguration() {
    final port = int.tryParse(_smtpPortController.text.trim()) ?? 587;
    final expiry = int.tryParse(_otpExpiryController.text.trim()) ?? 5;

    final updated = EmailConfigModel(
      isEnabled: _emailEnabled,
      smtpHost: _smtpHostController.text.trim().isEmpty
          ? 'smtp.gmail.com'
          : _smtpHostController.text.trim(),
      smtpPort: port,
      senderEmail: _senderEmailController.text.trim().isEmpty
          ? 'cuuho.ai.system@gmail.com'
          : _senderEmailController.text.trim(),
      senderName: _senderNameController.text.trim().isEmpty
          ? 'Trợ lý Cứu hộ AI'
          : _senderNameController.text.trim(),
      smtpPassword: _smtpPasswordController.text.trim(),
      otpExpiryMinutes: expiry,
      emailSubject: _emailSubjectController.text.trim().isEmpty
          ? '[Trợ lý Cứu hộ AI] Mã OTP khôi phục mật khẩu của bạn'
          : _emailSubjectController.text.trim(),
    );

    EmailConfigService.instance.updateConfig(updated);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã lưu cấu hình dịch vụ Email (SMTP & OTP) lên Supabase!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resetEmailConfigToDefault() {
    EmailConfigService.instance.resetToDefaults();
    final cfg = EmailConfigService.instance.config;
    setState(() {
      _smtpHostController.text = cfg.smtpHost;
      _smtpPortController.text = cfg.smtpPort.toString();
      _senderEmailController.text = cfg.senderEmail;
      _senderNameController.text = cfg.senderName;
      _smtpPasswordController.text = cfg.smtpPassword;
      _otpExpiryController.text = cfg.otpExpiryMinutes.toString();
      _emailSubjectController.text = cfg.emailSubject;
      _emailEnabled = cfg.isEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã khôi phục cấu hình Email & OTP chuẩn mặc định!'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTestEmailDialog() {
    final testCtrl = TextEditingController(text: 'bacsi.cuuho@gmail.com');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.send_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 10),
            Text('Gửi Email thử nghiệm', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kiểm tra định tuyến gửi email với cấu hình SMTP hiện tại.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: testCtrl,
              decoration: InputDecoration(
                labelText: 'Địa chỉ Email người nhận thử nghiệm',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
              final email = testCtrl.text.trim();
              if (email.isEmpty) return;
              EmailConfigService.instance.sendTestEmail(testRecipient: email);
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã phát lệnh gửi email thử nghiệm tới "$email"! Xem nhật ký bên dưới.'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cấu hình hệ thống & Trợ lý AI',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2B6B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quản lý các thiết lập vận hành của Google Gemini API cho ChatBox sơ cứu và dịch vụ Email khôi phục mật khẩu',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // ===================================================================
          // ===================================================================
          // CARD: CƠ SỞ DỮ LIỆU SUPABASE CLOUD (POSTGRESQL & REST API)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6EE7B7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0810B981),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Icon(Icons.storage_rounded, color: Color(0xFF059669), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Cơ sở dữ liệu Supabase Cloud',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Text(
                                  'Sẵn sàng kết nối',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Lưu trữ đồng bộ đám mây cho tài khoản, bài viết sơ cứu, lịch sử quét và phản hồi AI.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Project Endpoint:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        SupabaseConfig.url,
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Publishable Key:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        '${SupabaseConfig.anonKey.substring(0, math.min(24, SupabaseConfig.anonKey.length))}••••••••••••••••',
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                if (_supabasePingMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _supabasePingSuccess == true ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _supabasePingSuccess == true ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _supabasePingSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _supabasePingSuccess == true ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _supabasePingMessage!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _supabasePingSuccess == true ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isPingingSupabase ? null : _pingSupabase,
                      icon: _isPingingSupabase
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                            )
                          : const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF059669)),
                      label: Text(_isPingingSupabase ? 'Đang kiểm tra...' : 'Kiểm tra kết nối Supabase'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => UrlLauncherHelper.launchWebUrl(
                        context,
                        'https://supabase.com/dashboard/project/oageskffhndqypwuuaij',
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Mở Supabase Dashboard'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // CARD 1: CẤU HÌNH CHATBOX GOOGLE GEMINI API
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x082563EB),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '1. Cấu hình ChatBox Gemini',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D2B6B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _geminiEnabled && _apiKeyController.text.trim().isNotEmpty
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _geminiEnabled && _apiKeyController.text.trim().isNotEmpty
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  _geminiEnabled && _apiKeyController.text.trim().isNotEmpty
                                      ? 'Đang hoạt động'
                                      : (_geminiEnabled ? 'Chờ API Key' : 'Đã tắt'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _geminiEnabled && _apiKeyController.text.trim().isNotEmpty
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gọi trực tiếp Gemini API để giải đáp thắc mắc và tư vấn sơ cứu chuyên sâu theo ngôn ngữ tự nhiên.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _geminiEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (val) {
                        setState(() {
                          _geminiEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 28),

                // 4.1 Khóa Gemini API Key
                Row(
                  children: [
                    const Text(
                      'Khóa API Key của Google Gemini:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => UrlLauncherHelper.launchWebUrl(
                        context,
                        'https://aistudio.google.com/app/apikey',
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Lấy API Key miễn phí tại Google AI Studio',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF2563EB)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          hintText: 'Dán khóa API Key của bạn (Bắt đầu bằng AIzaSy...)',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF64748B), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureApiKey = !_obscureApiKey;
                              });
                            },
                            tooltip: _obscureApiKey ? 'Hiện khóa API' : 'Ẩn khóa API',
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _pasteApiKeyFromClipboard,
                      icon: const Icon(Icons.paste_rounded, size: 17),
                      label: const Text('Dán từ Clipboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF1E293B),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2.2 Thông tin mô hình Gemini & Nhiệt độ y khoa chuẩn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 20, color: Color(0xFF2563EB)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mô hình AI: Google Gemini Flash (Mới nhất)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hệ thống tự động sử dụng phiên bản Flash mới nhất với nhiệt độ 0.4 (chuẩn độ chính xác y khoa).',
                              style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4.3 System Instruction (Prompt định hướng y tế cho 4 loại vết thương)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lời nhắc hệ thống (System Prompt) cho vết thương:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    TextButton.icon(
                      onPressed: _resetSystemPromptToStandard,
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Khôi phục mẫu chuẩn y tế', style: TextStyle(fontSize: 12.5)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _promptController,
                  maxLines: 7,
                  minLines: 4,
                  style: const TextStyle(fontSize: 12.5, fontFamily: 'monospace', height: 1.4, color: Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Nhập lời nhắc định hướng phản hồi của Gemini...',
                    isDense: true,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mẫu prompt này được thiết kế để Gemini bám sát 4 phạm trù: Trầy xước, Vết cắt/rách, Bỏng, Bầm tím, tự động cảnh báo khẩn cấp đi viện khi nguy kịch và nhắc nhở tiêm uốn ván.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Hiển thị kết quả Test Connection nếu có
                if (_geminiTestResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _geminiTestResult!.isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _geminiTestResult!.isSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _geminiTestResult!.isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _geminiTestResult!.isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _geminiTestResult!.isSuccess ? 'Kiểm tra thành công!' : 'Kiểm tra thất bại:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _geminiTestResult!.isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _geminiTestResult!.message,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _geminiTestResult!.isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4.4 Các nút hành động: Kiểm tra kết nối & Lưu cấu hình
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTestingGemini ? null : () => _testGeminiConnection(viewModel),
                      icon: _isTestingGemini
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                            )
                          : const Icon(Icons.network_check_rounded, size: 18),
                      label: Text(_isTestingGemini ? 'Đang kiểm tra...' : 'Kiểm tra kết nối Gemini'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _saveGeminiConfiguration(viewModel),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Lưu cấu hình Gemini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===================================================================
          // CARD 2: CẤU HÌNH DỊCH VỤ GỬI EMAIL KHÔI PHỤC MẬT KHẨU (SMTP / OTP)
          // ===================================================================
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x082563EB),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDBEAFE)),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '2. Cấu hình Gửi Email Khôi phục Mật khẩu (SMTP & OTP)',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D2B6B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _emailEnabled
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _emailEnabled
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  _emailEnabled ? 'Đang hoạt động' : 'Tạm dừng',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _emailEnabled
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Quản lý thông số máy chủ SMTP và thời hạn mã OTP khi người dùng yêu cầu khôi phục mật khẩu (Đồng bộ Supabase Cloud).',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _emailEnabled,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (val) {
                        setState(() {
                          _emailEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
                const Divider(height: 28),

                // Lưu ý về lưu trên Supabase
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đồng bộ Supabase: Mọi cấu hình được lưu trữ vĩnh viễn trên bảng "system_configurations" của Supabase. Khi người dùng yêu cầu khôi phục mật khẩu, hệ thống tự động áp dụng thông số này.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Hàng 1: Máy chủ SMTP & Cổng SMTP
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Flex(
                      direction: isNarrow ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isNarrow ? 0 : 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Máy chủ SMTP (Host):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _smtpHostController,
                                decoration: InputDecoration(
                                  hintText: 'smtp.gmail.com',
                                  prefixIcon: const Icon(Icons.dns_rounded, size: 18),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 14),
                        if (isNarrow) const SizedBox(height: 12),
                        Expanded(
                          flex: isNarrow ? 0 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cổng SMTP (Port):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _smtpPortController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '587',
                                  prefixIcon: const Icon(Icons.numbers_rounded, size: 18),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Hàng 2: Email người gửi & Tên hiển thị
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Flex(
                      direction: isNarrow ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email gửi đi (Sender Email):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _senderEmailController,
                                decoration: InputDecoration(
                                  hintText: 'cuuho.ai.system@gmail.com',
                                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 14),
                        if (isNarrow) const SizedBox(height: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tên người gửi (Sender Name):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _senderNameController,
                                decoration: InputDecoration(
                                  hintText: 'Trợ lý Cứu hộ AI',
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Hàng 3: Mật khẩu ứng dụng SMTP & Thời hạn OTP
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Flex(
                      direction: isNarrow ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isNarrow ? 0 : 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mật khẩu ứng dụng SMTP (App Password):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _smtpPasswordController,
                                obscureText: _obscureSmtpPassword,
                                decoration: InputDecoration(
                                  hintText: 'Nhập mật khẩu ứng dụng Gmail...',
                                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureSmtpPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscureSmtpPassword = !_obscureSmtpPassword),
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 14),
                        if (isNarrow) const SizedBox(height: 12),
                        Expanded(
                          flex: isNarrow ? 0 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Thời hạn OTP (Phút):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _otpExpiryController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '5',
                                  prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                                  suffixText: 'phút',
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Hàng 4: Tiêu đề email
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tiêu đề Email thông báo OTP:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailSubjectController,
                      decoration: InputDecoration(
                        hintText: '[Trợ lý Cứu hộ AI] Mã OTP khôi phục mật khẩu của bạn',
                        prefixIcon: const Icon(Icons.subject_rounded, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Các nút hành động
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _resetEmailConfigToDefault,
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Khôi phục mặc định'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showTestEmailDialog,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Gửi email thử nghiệm (Test Dispatch)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveEmailConfiguration,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Lưu cấu hình Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // =============================================================
                // TIỂU MỤC 3.1: NHẬT KÝ GỬI MÃ OTP TRONG PHIÊN (IN-MEMORY LOGS)
                // =============================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 20, color: Color(0xFF0D2B6B)),
                        const SizedBox(width: 8),
                        const Text(
                          'Nhật ký gửi OTP trong phiên làm việc',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0D2B6B)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${EmailConfigService.instance.dispatchLogs.length} lượt',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    if (EmailConfigService.instance.dispatchLogs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            EmailConfigService.instance.clearLogs();
                            _currentEmailLogPage = 1;
                          });
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFFDC2626)),
                        label: const Text('Xóa nhật ký', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (EmailConfigService.instance.dispatchLogs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF94A3B8)),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có yêu cầu gửi OTP nào trong phiên làm việc hiện tại.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Khi người dùng bấm "Quên mật khẩu" bên giao diện ứng dụng, mã OTP sẽ được ghi nhận tức thì tại đây.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                else () {
                  final allLogs = EmailConfigService.instance.dispatchLogs;
                  final totalLogPages = (allLogs.length / _emailLogPageSize).ceil().clamp(1, 999);
                  final safePage = _currentEmailLogPage.clamp(1, totalLogPages);
                  final startLogIdx = (safePage - 1) * _emailLogPageSize;
                  final paginatedLogs = startLogIdx >= allLogs.length
                      ? <EmailDispatchLog>[]
                      : allLogs.sublist(startLogIdx, math.min(startLogIdx + _emailLogPageSize, allLogs.length));

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedLogs.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final log = paginatedLogs[idx];
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.email_outlined, color: Color(0xFF16A34A), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          log.recipient,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: Text(
                                            'OTP: ${log.otpCode}',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      log.details,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      },
                        ),
                      ),
                      if (allLogs.length > _emailLogPageSize) ...[
                        const SizedBox(height: 12),
                        buildAdminPaginationFooter(
                          currentPage: safePage,
                          totalPages: totalLogPages,
                          totalItems: allLogs.length,
                          pageSize: _emailLogPageSize,
                          itemLabel: 'nhật ký gửi mail',
                          onPageSelected: (page) => setState(() => _currentEmailLogPage = page),
                          onPrevious: () => setState(() {
                            if (_currentEmailLogPage > 1) _currentEmailLogPage--;
                          }),
                          onNext: () => setState(() {
                            if (_currentEmailLogPage < totalLogPages) _currentEmailLogPage++;
                          }),
                          isMobile: isMobile,
                        ),
                      ],
                    ],
                  );
                }(),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


}


