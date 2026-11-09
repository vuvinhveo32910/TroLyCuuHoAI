import 'package:flutter/material.dart';

import '../../viewmodels/user_viewmodel.dart';

class UserProfileModalDialog extends StatefulWidget {
  final UserViewModel viewModel;

  const UserProfileModalDialog({super.key, required this.viewModel});

  @override
  State<UserProfileModalDialog> createState() => _UserProfileModalDialogState();
}

class _UserProfileModalDialogState extends State<UserProfileModalDialog> {
  // Chỉ số thể chất & tài khoản
  String? _gender; // 'male', 'female', 'other'
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _otherNotesCtrl;

  // Thông tin y tế cốt lõi
  String? _bloodType; // 'A', 'B', 'AB', 'O'
  String? _rhFactor; // 'Rh+', 'Rh-'
  late Set<String> _selectedAllergies;
  late Set<String> _selectedConditions;

  // Đổi mật khẩu
  bool _isChangePasswordExpanded = false;
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureOldPass = true;
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  String? _passwordError;
  String? _passwordSuccess;

  // Danh sách gợi ý dị ứng chuẩn
  static const List<String> kCommonAllergies = [
    'Cồn y tế (Alcohol)',
    'Kháng sinh Penicillin',
    'Povidone Iodine (Betadine)',
    'Aspirin / NSAID',
  ];

  // Danh sách bệnh lý nền chuẩn
  static const Map<String, String> kCommonConditions = {
    'diabetes': 'Đái tháo đường (Tiểu đường) – Vết thương chậm lành',
    'hemophilia': 'Máu khó đông (Hemophilia) – Báo động khi rách da',
    'cardiovascular': 'Bệnh tim mạch / Huyết áp – Nguy cơ sốc chấn thương',
  };

  @override
  void initState() {
    super.initState();
    final user = widget.viewModel.currentUser;
    _gender = user?.gender;
    _weightCtrl = TextEditingController(text: user?.weightKg != null ? user!.weightKg.toString() : '');
    _heightCtrl = TextEditingController(text: user?.heightCm != null ? user!.heightCm.toString() : '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _otherNotesCtrl = TextEditingController(text: user?.otherNotes ?? '');
    _bloodType = user?.bloodType;
    _rhFactor = user?.rhFactor;
    _selectedAllergies = Set<String>.from(user?.allergies ?? []);
    _selectedConditions = Set<String>.from(user?.medicalConditions ?? []);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _emailCtrl.dispose();
    _otherNotesCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  String? _getBmiSummary() {
    final h = double.tryParse(_heightCtrl.text.trim());
    final w = double.tryParse(_weightCtrl.text.trim());
    if (h == null || h <= 0 || w == null || w <= 0) return null;
    final hm = h / 100.0;
    final bmi = w / (hm * hm);
    String cat = 'Bình thường';
    if (bmi < 18.5) {
      cat = 'Thiếu cân / Gầy';
    } else if (bmi >= 25 && bmi < 30) {
      cat = 'Thừa cân';
    } else if (bmi >= 30) {
      cat = 'Béo phì';
    }
    return 'BMI: ${bmi.toStringAsFixed(1)} • $cat';
  }

  void _saveProfile() {
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    final email = _emailCtrl.text.trim();
    final notes = _otherNotesCtrl.text.trim();

    final err = widget.viewModel.updateUserProfile(
      gender: _gender,
      weightKg: w,
      heightCm: h,
      bloodType: _bloodType,
      rhFactor: _rhFactor,
      allergies: _selectedAllergies.toList(),
      medicalConditions: _selectedConditions.toList(),
      otherNotes: notes.isNotEmpty ? notes : null,
      email: email.isNotEmpty ? email : null,
    );

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFDC2626)),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Đã cập nhật Hồ sơ y tế & thể chất thành công!'),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleChangePassword() {
    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });

    final oldP = _oldPassCtrl.text.trim();
    final newP = _newPassCtrl.text.trim();
    final confP = _confirmPassCtrl.text.trim();

    if (oldP.isEmpty || newP.isEmpty || confP.isEmpty) {
      setState(() => _passwordError = 'Vui lòng điền đầy đủ mật khẩu cũ và mật khẩu mới.');
      return;
    }
    if (newP != confP) {
      setState(() => _passwordError = 'Mật khẩu xác nhận không trùng khớp.');
      return;
    }
    if (newP.length < 6) {
      setState(() => _passwordError = 'Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }

    final error = widget.viewModel.changeUserPassword(
      oldPassword: oldP,
      newPassword: newP,
    );

    if (error != null) {
      setState(() => _passwordError = error);
    } else {
      setState(() {
        _passwordSuccess = 'Đổi mật khẩu thành công!';
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _isChangePasswordExpanded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu tài khoản thành công!'),
          backgroundColor: Color(0xFF16A34A),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    final bmiInfo = _getBmiSummary();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề & Nút đóng
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin cá nhân & Hồ sơ y tế',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tài khoản: @${user?.username ?? ""} • Tự động cá nhân hóa Rule Engine',
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
            const SizedBox(height: 12),

            // NÚT CAM KẾT BẢO MẬT & QUYỀN RIÊNG TƯ (CLICKABLE)
            InkWell(
              onTap: () => _showPrivacyCommitmentDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ứng dụng không thu thập tên, SĐT, địa chỉ. Dữ liệu chỉ dùng để tối ưu sơ cứu chính xác hơn.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF16A34A), size: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // NỘI DUNG CUỘN CÁC MỤC HỒ SƠ
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================================================
                    // PHẦN 1: CHỈ SỐ THỂ CHẤT & TÀI KHOẢN
                    // =========================================================
                    const Text(
                      '1. Chỉ số thể chất & Email khôi phục',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0D2B6B)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Email khôi phục (Tùy chọn)',
                        hintText: 'Nhập email nếu muốn nhận OTP khi quên mật khẩu',
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Giới tính
                    Row(
                      children: [
                        const Text('Giới tính:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        const SizedBox(width: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildChoiceChip('Nam', _gender == 'male', () => setState(() => _gender = 'male')),
                            _buildChoiceChip('Nữ', _gender == 'female', () => setState(() => _gender = 'female')),
                            _buildChoiceChip('Khác', _gender == 'other', () => setState(() => _gender = 'other')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Hàng Cân nặng & Chiều cao
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Cân nặng (kg)',
                              prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _heightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Chiều cao (cm)',
                              prefixIcon: const Icon(Icons.height_rounded, size: 18),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (bmiInfo != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bmiInfo,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                        ),
                      ),
                    ],
                    const Divider(height: 26),

                    // =========================================================
                    // PHẦN 2: THÔNG TIN Y TẾ CỐT LÕI (RULE ENGINE)
                    // =========================================================
                    const Text(
                      '2. Nhóm máu & Tiền sử Y tế cốt lõi',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0D2B6B)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Thông tin này được Rule Engine dùng để phát hiện nguy cơ máu khó đông, vết thương lâu lành do tiểu đường hoặc dị ứng cồn.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),

                    // Nhóm máu & Rh
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Nhóm máu:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: ['A', 'B', 'AB', 'O'].map((bt) {
                            return _buildChoiceChip(bt, _bloodType == bt, () {
                              setState(() => _bloodType = _bloodType == bt ? null : bt);
                            });
                          }).toList(),
                        ),
                        const SizedBox(width: 12),
                        const Text('Rh:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                        const SizedBox(width: 6),
                        Wrap(
                          spacing: 6,
                          children: ['Rh+', 'Rh-'].map((rh) {
                            return _buildChoiceChip(rh, _rhFactor == rh, () {
                              setState(() => _rhFactor = _rhFactor == rh ? null : rh);
                            });
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bệnh lý nền nguy hiểm
                    const Text(
                      'Bệnh lý nền nguy hiểm (Chọn nếu có):',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    ...kCommonConditions.entries.map((entry) {
                      final isChecked = _selectedConditions.contains(entry.key);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedConditions.remove(entry.key);
                            } else {
                              _selectedConditions.add(entry.key);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20,
                                color: isChecked ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                    color: isChecked ? const Color(0xFFB91C1C) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Tiền sử dị ứng thuốc & hóa chất
                    const Text(
                      'Tiền sử dị ứng thuốc / hóa chất:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: kCommonAllergies.map((allergy) {
                        final isSel = _selectedAllergies.contains(allergy);
                        return FilterChip(
                          label: Text(allergy, style: TextStyle(fontSize: 11.5, color: isSel ? const Color(0xFF1E40AF) : const Color(0xFF475569))),
                          selected: isSel,
                          selectedColor: const Color(0xFFDBEAFE),
                          checkmarkColor: const Color(0xFF2563EB),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedAllergies.add(allergy);
                              } else {
                                _selectedAllergies.remove(allergy);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Ghi chú y tế khác
                    TextField(
                      controller: _otherNotesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú y tế khác (Ví dụ: thuốc đang dùng...)',
                        hintText: 'Không bắt buộc...',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Divider(height: 26),

                    // =========================================================
                    // PHẦN 3: ĐỔI MẬT KHẨU TÀI KHOẢN
                    // =========================================================
                    InkWell(
                      onTap: () => setState(() => _isChangePasswordExpanded = !_isChangePasswordExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_reset_rounded, size: 18, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text(
                                  'Đổi mật khẩu tài khoản',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                            Icon(
                              _isChangePasswordExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isChangePasswordExpanded) ...[
                      const SizedBox(height: 8),
                      if (_passwordError != null) ...[
                        Text(_passwordError!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                        const SizedBox(height: 6),
                      ],
                      if (_passwordSuccess != null) ...[
                        Text(_passwordSuccess!, style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A))),
                        const SizedBox(height: 6),
                      ],
                      TextField(
                        controller: _oldPassCtrl,
                        obscureText: _obscureOldPass,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu hiện tại',
                          prefixIcon: const Icon(Icons.key_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOldPass ? Icons.visibility_off : Icons.visibility, size: 16),
                            onPressed: () => setState(() => _obscureOldPass = !_obscureOldPass),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _newPassCtrl,
                        obscureText: _obscureNewPass,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility, size: 16),
                            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirmPass,
                        decoration: InputDecoration(
                          labelText: 'Nhập lại mật khẩu mới',
                          prefixIcon: const Icon(Icons.lock_reset_outlined, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, size: 16),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2B6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cập nhật mật khẩu mới'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // NÚT HÀNH ĐỘNG DƯỚI CÙNG
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Đóng'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Lưu hồ sơ sức khỏe', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// POPUP / DIALOG CAM KẾT BẢO MẬT & QUYỀN RIÊNG TƯ DỮ LIỆU Y TẾ
/// ============================================================================
void _showPrivacyCommitmentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cam kết Quyền riêng tư & Bảo mật Y tế',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0D2B6B)),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Đoạn tuyên bố cốt lõi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Text(
                'Ứng dụng hoàn toàn không thu thập bất cứ dữ liệu danh tính cá nhân nào từ người dùng (như họ tên thật, số điện thoại, số CCCD hay địa chỉ cư trú). Toàn bộ thông tin về chỉ số thể chất, nhóm máu, tiền sử dị ứng và bệnh lý nền chỉ được lưu trữ cục bộ trên thiết bị của bạn nhằm phục vụ mục đích duy nhất: Giúp Rule Engine tính toán và đưa ra kết quả chỉ dẫn sơ cứu chính xác, an toàn và kịp thời nhất khi bạn gặp sự cố thương tích.',
                style: TextStyle(fontSize: 13, color: Color(0xFF166534), height: 1.45, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Các nguyên tắc bảo vệ bạn:',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            _buildPrivacyPrincipleRow(
              icon: Icons.no_accounts_rounded,
              title: 'Ẩn danh tuyệt đối',
              desc: 'Không yêu cầu họ tên, CCCD/CMND hay vị trí cụ thể của bạn. Tài khoản định danh thuần túy qua username ngẫu nhiên.',
            ),
            const SizedBox(height: 8),
            _buildPrivacyPrincipleRow(
              icon: Icons.memory_rounded,
              title: 'Lưu trữ Cục bộ / In-Memory',
              desc: 'Chỉ số thể chất và tiền sử bệnh lý không được gửi tới bên thứ ba hay mạng quảng cáo, chỉ sử dụng trực tiếp trên phiên làm việc.',
            ),
            const SizedBox(height: 8),
            _buildPrivacyPrincipleRow(
              icon: Icons.emergency_rounded,
              title: 'Cứu hộ cá nhân hóa chính xác',
              desc: 'Tự động kích hoạt cảnh báo nguy kịch 115 khi người bệnh Máu khó đông (Hemophilia) bị rách da, hoặc cảnh báo nguy cơ hoại tử với bệnh Tiểu đường.',
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Tôi đã hiểu & Yên tâm sử dụng', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Widget _buildPrivacyPrincipleRow({required IconData icon, required String title, required String desc}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35)),
          ],
        ),
      ),
    ],
  );
}
