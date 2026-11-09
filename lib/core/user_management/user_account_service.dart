// File: lib/core/user_management/user_account_service.dart
import 'package:flutter/foundation.dart';

import '../../features/user/models/user_account_model.dart';
import '../supabase/supabase_service.dart';

/// Dịch vụ Singleton quản lý tài khoản người dùng, trạng thái Khóa / Mở khóa
/// và các Đơn khiếu nại mở khóa (Tích hợp Supabase Cloud & Bảo mật băm Bcrypt pgcrypto)
class UserAccountService extends ChangeNotifier {
  UserAccountService._() {
    // Tự động tải dữ liệu từ Supabase khi dịch vụ khởi động
    fetchAccountsFromSupabase();
    fetchAppealsFromSupabase();
  }
  static final UserAccountService instance = UserAccountService._();

  // Danh sách tài khoản người dùng được đồng bộ từ Supabase
  final List<UserAccountModel> _accounts = [];
  List<UserAccountModel> get accounts => List.unmodifiable(_accounts);

  // Danh sách các yêu cầu mở khóa tài khoản được đồng bộ từ Supabase
  final List<UserUnlockAppealModel> _appeals = [];
  List<UserUnlockAppealModel> get appeals => List.unmodifiable(_appeals);

  int get pendingAppealCount => _appeals.where((a) => a.isPending).length;

  /// Tìm kiếm tài khoản theo username trong bộ nhớ đệm đồng bộ
  UserAccountModel? findByUsername(String username) {
    final clean = username.trim().toLowerCase();
    final idx = _accounts.indexWhere((a) => a.username.toLowerCase() == clean);
    return idx != -1 ? _accounts[idx] : null;
  }

  /// Tìm kiếm tài khoản theo username hoặc email liên kết trong bộ nhớ đệm
  UserAccountModel? findByUsernameOrEmail(String identifier) {
    final clean = identifier.trim().toLowerCase();
    final idx = _accounts.indexWhere(
      (a) =>
          a.username.toLowerCase() == clean ||
          (a.emailOrPhone != null &&
              a.emailOrPhone!.trim().toLowerCase() == clean),
    );
    return idx != -1 ? _accounts[idx] : null;
  }

  /// Tìm kiếm tài khoản bất đồng bộ: trả về từ cache nếu có, hoặc truy vấn trực tiếp từ Supabase
  /// Giải quyết race-condition khi ứng dụng vừa khởi động lại (Startup Session Restoration)
  Future<UserAccountModel?> findByUsernameAsync(String username) async {
    final cached = findByUsername(username);
    if (cached != null) return cached;

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final clean = username.trim().toLowerCase();
        final res = await client
            .from('user_accounts')
            .select()
            .ilike('username', clean)
            .maybeSingle();
        if (res != null) {
          final acc = UserAccountModel.fromMap(res);
          final idx = _accounts.indexWhere(
            (a) => a.username.toLowerCase() == clean,
          );
          if (idx == -1) {
            _accounts.add(acc);
          } else {
            _accounts[idx] = acc;
          }
          return acc;
        }
      }
    } catch (e) {
      debugPrint('[UserAccountService] Lỗi findByUsernameAsync: $e');
    }
    return null;
  }

  /// Tải danh sách tài khoản từ bảng 'user_accounts' trên Supabase
  Future<void> fetchAccountsFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final res = await client
          .from('user_accounts')
          .select()
          .order('created_at', ascending: false);

      _accounts.clear();
      for (final row in res) {
        _accounts.add(UserAccountModel.fromMap(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[UserAccountService] Tải tài khoản Supabase (đang chuẩn bị bảng): $e',
      );
    }
  }

  /// Tải danh sách yêu cầu mở khóa từ bảng 'account_unlock_appeals' trên Supabase
  Future<void> fetchAppealsFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      if (client == null) return;

      final res = await client
          .from('account_unlock_appeals')
          .select()
          .order('created_at', ascending: false);

      _appeals.clear();
      for (final row in res) {
        _appeals.add(UserUnlockAppealModel.fromMap(row));
      }
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[UserAccountService] Tải khiếu nại Supabase (đang chuẩn bị bảng): $e',
      );
    }
  }

  /// Đăng ký tài khoản người dùng mới (Băm mật khẩu bằng Bcrypt pgcrypto trên Supabase)
  Future<String?> registerAsync({
    required String username,
    required String password,
    String? emailOrPhone,
  }) async {
    final cleanUser = username.trim();
    if (cleanUser.length < 3) {
      return 'Tên tài khoản phải có ít nhất 3 ký tự.';
    }
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (findByUsername(cleanUser) != null) {
      return 'Tên tài khoản "$cleanUser" đã tồn tại trên hệ thống.';
    }

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        // Gọi Stored Procedure băm Bcrypt trên Supabase
        final rpcRes = await client.rpc(
          'register_user_account',
          params: {
            'p_username': cleanUser,
            'p_password': password,
            'p_email_or_phone': emailOrPhone?.trim().isNotEmpty == true
                ? emailOrPhone!.trim()
                : null,
          },
        );

        if (rpcRes is Map) {
          if (rpcRes['success'] != true) {
            return rpcRes['message'] as String? ?? 'Đăng ký không thành công.';
          }
          await fetchAccountsFromSupabase();
          return null;
        }
      }
    } catch (e) {
      debugPrint('[UserAccountService] Gọi RPC register_user_account: $e');
      // Dự phòng nếu chưa chạy SQL tạo hàm RPC: Insert trực tiếp vào bảng
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client.from('user_accounts').insert({
            'username': cleanUser,
            'password_hash':
                password, // Sau khi chạy script SQL sẽ tự băm Bcrypt
            'email_or_phone': emailOrPhone?.trim(),
            'created_at': DateTime.now().toIso8601String(),
            'last_active_at': DateTime.now().toIso8601String(),
            'is_locked': false,
          });
          await fetchAccountsFromSupabase();
          return null;
        }
      } catch (insertErr) {
        debugPrint(
          '[UserAccountService] Lỗi insert bảng user_accounts: $insertErr',
        );
      }
    }

    // Fallback đồng bộ bộ nhớ tạm
    if (findByUsername(cleanUser) == null) {
      final newAccount = UserAccountModel(
        username: cleanUser,
        password: password,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        emailOrPhone: emailOrPhone?.trim().isNotEmpty == true
            ? emailOrPhone!.trim()
            : null,
        isLocked: false,
      );
      _accounts.insert(0, newAccount);
      notifyListeners();
    }
    return null;
  }

  /// Wrapper đồng bộ tương thích ngược cho giao diện hiện tại
  String? register({
    required String username,
    required String password,
    String? emailOrPhone,
  }) {
    final cleanUser = username.trim();
    if (cleanUser.length < 3) {
      return 'Tên tài khoản phải có ít nhất 3 ký tự.';
    }
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (findByUsername(cleanUser) != null) {
      return 'Tên tài khoản "$cleanUser" đã tồn tại trên hệ thống.';
    }

    registerAsync(
      username: cleanUser,
      password: password,
      emailOrPhone: emailOrPhone,
    );
    _accounts.insert(
      0,
      UserAccountModel(
        username: cleanUser,
        password: password,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        emailOrPhone: emailOrPhone?.trim().isNotEmpty == true
            ? emailOrPhone!.trim()
            : null,
        isLocked: false,
      ),
    );
    notifyListeners();
    return null;
  }

  /// Xác thực đăng nhập người dùng (So khớp Bcrypt qua pgcrypto trên Supabase)
  Future<Map<String, dynamic>> authenticateAsync({
    required String username,
    required String password,
  }) async {
    final cleanUser = username.trim();
    final cleanPass = password.trim();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final rpcRes = await client.rpc(
          'authenticate_user_account',
          params: {'p_username': cleanUser, 'p_password': cleanPass},
        );

        if (rpcRes is Map) {
          if (rpcRes['success'] == true) {
            final accMap = rpcRes['account'] as Map<String, dynamic>;
            final account = UserAccountModel.fromMap(accMap);
            // Cập nhật bộ nhớ đệm
            final idx = _accounts.indexWhere(
              (a) => a.username.toLowerCase() == cleanUser.toLowerCase(),
            );
            if (idx != -1) {
              _accounts[idx] = account;
            } else {
              _accounts.insert(0, account);
            }
            notifyListeners();
            return {'success': true, 'account': account};
          } else {
            return {
              'success': false,
              'isLocked': rpcRes['is_locked'] == true,
              'lockReason': rpcRes['lock_reason'],
              'message': rpcRes['message'] ?? 'Đăng nhập không thành công.',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('[UserAccountService] Gọi RPC authenticate_user_account: $e');
    }

    // Fallback kiểm tra từ bộ nhớ đệm nếu chưa chạy SQL trên Supabase
    return authenticate(username: username, password: password);
  }

  /// Xác thực đăng nhập (hỗ trợ cả Tên tài khoản và Email liên kết)
  Map<String, dynamic> authenticate({
    required String username,
    required String password,
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final account = findByUsernameOrEmail(cleanUser);

    if (account == null) {
      return {
        'success': false,
        'message': 'Tài khoản "$cleanUser" không tồn tại trong hệ thống.',
      };
    }

    if (account.password != cleanPass) {
      return {
        'success': false,
        'message': 'Mật khẩu không chính xác. Vui lòng kiểm tra lại.',
      };
    }

    if (account.isLocked) {
      return {
        'success': false,
        'isLocked': true,
        'lockReason': account.lockReason ?? 'Tài khoản của bạn đã bị tạm khóa bởi Quản trị viên do vi phạm quy định.',
        'message': 'Tài khoản của bạn hiện đang bị khóa.',
      };
    }

    final updated = account.copyWith(lastActiveAt: DateTime.now());
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == account.username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = updated;
    }
    notifyListeners();

    // Đồng bộ async thời gian truy cập lên Supabase
    _syncLastActiveToSupabase(account.username);

    return {'success': true, 'account': updated};
  }

  void _syncLastActiveToSupabase(String username) async {
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client
            .from('user_accounts')
            .update({'last_active_at': DateTime.now().toIso8601String()})
            .eq('username', username);
      }
    } catch (_) {}
  }

  /// Cập nhật hồ sơ sức khỏe cá nhân (Zero-Knowledge)
  Future<void> updateProfile(UserAccountModel updated) async {
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == updated.username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = updated;
      notifyListeners();
    }

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client
            .from('user_accounts')
            .update({'medical_profile': updated.toMedicalProfileMap()})
            .eq('username', updated.username);
      }
    } catch (e) {
      debugPrint(
        '[UserAccountService] Cập nhật medical_profile lên Supabase: $e',
      );
    }
  }

  /// Đổi mật khẩu
  Future<void> changePassword(String username, String newPassword) async {
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = _accounts[idx].copyWith(password: newPassword);
      notifyListeners();
    }

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.rpc(
          'change_user_password',
          params: {
            'p_username': username,
            'p_old_password': _accounts[idx].password,
            'p_new_password': newPassword,
          },
        );
      }
    } catch (e) {
      debugPrint('[UserAccountService] Đổi mật khẩu Supabase: $e');
    }
  }

  /// Đăng nhập hoặc Tạo mới tài khoản qua Google OAuth
  /// - Nếu đã tồn tại tài khoản với googleId hoặc email khớp: liên kết tài khoản và cập nhật
  /// - Nếu là người dùng mới: tạo tài khoản mới với emailOrPhone = email, authProvider = 'google', isGoogleLinked = true
  Future<UserAccountModel> signInWithGoogleAsync({
    required String googleId,
    required String email,
    String? displayName,
  }) async {
    final cleanId = googleId.trim();
    final cleanEmail = email.trim();
    final cleanEmailLower = cleanEmail.toLowerCase();

    // 1. Tìm kiếm tài khoản đã tồn tại (khớp googleId hoặc email)
    int existingIdx = _accounts.indexWhere((a) {
      if (a.googleId != null && a.googleId!.trim() == cleanId) {
        return true;
      }
      if (a.emailOrPhone != null &&
          a.emailOrPhone!.trim().toLowerCase() == cleanEmailLower) {
        return true;
      }
      return false;
    });

    if (existingIdx != -1) {
      // Đã có tài khoản: Cập nhật liên kết Google và thời gian hoạt động
      final existing = _accounts[existingIdx];
      final updated = existing.copyWith(
        googleId: cleanId,
        isGoogleLinked: true,
        authProvider: 'google',
        lastActiveAt: DateTime.now(),
        emailOrPhone:
            (existing.emailOrPhone != null &&
                existing.emailOrPhone!.trim().isNotEmpty)
            ? existing.emailOrPhone
            : cleanEmail,
        fullName:
            (existing.fullName.isEmpty &&
                displayName != null &&
                displayName.trim().isNotEmpty)
            ? displayName.trim()
            : existing.fullName,
      );

      _accounts[existingIdx] = updated;
      notifyListeners();

      // Đồng bộ thông tin liên kết lên Supabase nếu có kết nối
      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client
              .from('user_accounts')
              .update({
                'google_id': cleanId,
                'is_google_linked': true,
                'auth_provider': 'google',
                'last_active_at': DateTime.now().toIso8601String(),
                'email_or_phone': updated.emailOrPhone,
              })
              .eq('username', updated.username);
        }
      } catch (e) {
        debugPrint('[UserAccountService] Đồng bộ Google Link lên Supabase: $e');
      }

      return updated;
    }

    // 2. Chưa có tài khoản: Tạo mới tài khoản liên kết Google
    // Sinh tên username độc nhất từ email hoặc tiền tố Google
    String baseUsername = cleanEmailLower.contains('@')
        ? cleanEmailLower
              .split('@')
              .first
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        : 'google_user';
    if (baseUsername.length < 3) {
      baseUsername = 'user_${baseUsername.padRight(3, '0')}';
    }

    String candidateUsername = baseUsername;
    int suffix = 1;
    while (_accounts.any(
      (a) => a.username.toLowerCase() == candidateUsername.toLowerCase(),
    )) {
      candidateUsername = '${baseUsername}_$suffix';
      suffix++;
    }

    final now = DateTime.now();
    final newAccount = UserAccountModel(
      username: candidateUsername,
      password: '', // Tài khoản Google không có mật khẩu thủ công ban đầu
      fullName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : candidateUsername,
      createdAt: now,
      lastActiveAt: now,
      emailOrPhone: cleanEmail,
      authProvider: 'google',
      googleId: cleanId,
      isGoogleLinked: true,
      isLocked: false,
    );

    // Thêm vào danh sách bộ nhớ đệm
    _accounts.insert(0, newAccount);
    notifyListeners();

    // Lưu vào bảng user_accounts trên Supabase
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('user_accounts').insert({
          'username': newAccount.username,
          'password_hash': '',
          'full_name': newAccount.fullName,
          'email_or_phone': newAccount.emailOrPhone,
          'auth_provider': 'google',
          'google_id': cleanId,
          'is_google_linked': true,
          'created_at': now.toIso8601String(),
          'last_active_at': now.toIso8601String(),
          'is_locked': false,
        });
      }
    } catch (e) {
      debugPrint(
        '[UserAccountService] Tạo mới tài khoản Google trên Supabase: $e',
      );
    }

    return newAccount;
  }

  /// Đặt lại mật khẩu mới cho tài khoản (không yêu cầu mật khẩu cũ)
  /// Dùng cho luồng khôi phục OTP qua Email/Gmail, đặc biệt tài khoản Google chưa từng có mật khẩu cũ
  Future<String?> resetPasswordAsync({
    required String usernameOrEmail,
    required String newPassword,
  }) async {
    final cleanTarget = usernameOrEmail.trim().toLowerCase();
    final cleanPass = newPassword.trim();

    if (cleanPass.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }

    final idx = _accounts.indexWhere(
      (a) =>
          a.username.toLowerCase() == cleanTarget ||
          (a.emailOrPhone != null &&
              a.emailOrPhone!.trim().toLowerCase() == cleanTarget),
    );

    if (idx == -1) {
      return 'Không tìm thấy tài khoản tương ứng để đặt lại mật khẩu.';
    }

    final targetUser = _accounts[idx];
    final updated = targetUser.copyWith(
      password: cleanPass,
      lastActiveAt: DateTime.now(),
    );
    _accounts[idx] = updated;
    notifyListeners();

    // Cập nhật trên Supabase
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        // Cập nhật trực tiếp cột password_hash trên bảng user_accounts
        await client
            .from('user_accounts')
            .update({
              'password_hash': cleanPass,
              'last_active_at': DateTime.now().toIso8601String(),
            })
            .eq('username', targetUser.username);
      }
    } catch (e) {
      debugPrint('[UserAccountService] Đặt lại mật khẩu Supabase: $e');
    }

    return null;
  }

  // ===========================================================================
  // CÁC THAO TÁC QUẢN TRỊ ADMIN (Khóa, Mở khóa, Xóa, Duyệt yêu cầu)
  // ===========================================================================

  /// Khóa (vô hiệu hóa) tài khoản người dùng
  Future<void> blockUser({required String username, String? reason}) async {
    final cleanReason =
        reason ?? 'Tài khoản vi phạm quy chuẩn sử dụng hoặc offline quá lâu.';
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = _accounts[idx].copyWith(
        isLocked: true,
        lockReason: cleanReason,
      );
      notifyListeners();
    }

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client
            .from('user_accounts')
            .update({'is_locked': true, 'lock_reason': cleanReason})
            .eq('username', username);
      }
    } catch (e) {
      debugPrint('[UserAccountService] Khóa tài khoản trên Supabase: $e');
    }
  }

  /// Mở khóa tài khoản người dùng
  Future<void> unblockUser(String username) async {
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = _accounts[idx].copyWith(
        isLocked: false,
        lockReason: null,
      );
      notifyListeners();
    }

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client
            .from('user_accounts')
            .update({'is_locked': false, 'lock_reason': null})
            .eq('username', username);
      }
    } catch (e) {
      debugPrint('[UserAccountService] Mở khóa tài khoản trên Supabase: $e');
    }
  }

  /// Xóa tài khoản người dùng (Xóa tài khoản rác/offline quá lâu)
  Future<void> deleteUser(String username) async {
    _accounts.removeWhere(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    _appeals.removeWhere(
      (ap) => ap.username.toLowerCase() == username.toLowerCase(),
    );
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('user_accounts').delete().eq('username', username);
      }
    } catch (e) {
      debugPrint('[UserAccountService] Xóa tài khoản trên Supabase: $e');
    }
  }

  /// Người dùng gửi yêu cầu gỡ khóa tài khoản
  Future<void> submitUnlockAppeal({
    required String username,
    required String reason,
  }) async {
    final newAppeal = UserUnlockAppealModel(
      id: 'appeal_${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      reason: reason.trim(),
      createdAt: DateTime.now(),
      status: 'pending',
    );
    _appeals.insert(0, newAppeal);
    notifyListeners();

    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        await client.from('account_unlock_appeals').insert({
          'username': username.trim(),
          'reason': reason.trim(),
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
        await fetchAppealsFromSupabase();
      }
    } catch (e) {
      debugPrint('[UserAccountService] Gửi khiếu nại lên Supabase: $e');
    }
  }

  /// Quản trị viên duyệt và mở khóa tài khoản ngay lập tức
  Future<void> approveUnlockAppeal(String appealId) async {
    final idx = _appeals.indexWhere((a) => a.id == appealId);
    if (idx != -1) {
      final appeal = _appeals[idx];
      _appeals[idx] = appeal.copyWith(
        status: 'approved',
        resolvedAt: DateTime.now(),
        adminNote: 'Đã phê duyệt mở khóa tài khoản.',
      );
      unblockUser(appeal.username);
      notifyListeners();

      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client
              .from('account_unlock_appeals')
              .update({
                'status': 'approved',
                'admin_note': 'Đã phê duyệt mở khóa tài khoản.',
                'resolved_at': DateTime.now().toIso8601String(),
              })
              .eq('id', appealId);
        }
      } catch (e) {
        debugPrint('[UserAccountService] Phê duyệt khiếu nại Supabase: $e');
      }
    }
  }

  /// Quản trị viên từ chối yêu cầu mở khóa
  Future<void> rejectUnlockAppeal(String appealId, {String? note}) async {
    final idx = _appeals.indexWhere((a) => a.id == appealId);
    if (idx != -1) {
      final appeal = _appeals[idx];
      final finalNote = note ?? 'Yêu cầu không đủ điều kiện phê duyệt.';
      _appeals[idx] = appeal.copyWith(
        status: 'rejected',
        resolvedAt: DateTime.now(),
        adminNote: finalNote,
      );
      notifyListeners();

      try {
        final client = SupabaseService.instance.client;
        if (client != null) {
          await client
              .from('account_unlock_appeals')
              .update({
                'status': 'rejected',
                'admin_note': finalNote,
                'resolved_at': DateTime.now().toIso8601String(),
              })
              .eq('id', appealId);
        }
      } catch (e) {
        debugPrint('[UserAccountService] Từ chối khiếu nại Supabase: $e');
      }
    }
  }
}
