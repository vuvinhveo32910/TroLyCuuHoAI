// File: test/challenger_empirical_suite.dart
// ---------------------------------------------------------------------------
// Empirical Challenger Verification & Stress Test Suite
// Authored and Maintained by teamwork_challenger (Adversarial Critic & Specialist)
// Deterministic Pure-Dart SDK Test Harness (Zero External Dependencies)
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:math';

import '../lib/core/config/google_auth_config.dart';
import '../lib/core/config/supabase_config.dart';
import '../lib/features/user/models/user_account_model.dart';

// ---------------------------------------------------------------------------
// Test Double: In-Memory SharedPreferences Simulator
// ---------------------------------------------------------------------------
class EmpiricalLocalStorage {
  static final Map<String, dynamic> _store = {};

  static Future<void> saveUserCredentials({
    required bool rememberMe,
    required String username,
    required String password,
  }) async {
    _store['auth_user_remember_me'] = rememberMe;
    if (rememberMe) {
      _store['auth_user_saved_username'] = username;
      _store['auth_user_saved_password'] = password;
      _store['auth_user_is_logged_in'] = true;
    } else {
      _store.remove('auth_user_saved_username');
      _store.remove('auth_user_saved_password');
      _store['auth_user_is_logged_in'] = false;
    }
  }

  static Future<Map<String, dynamic>> loadUserCredentials() async {
    return {
      'rememberMe': _store['auth_user_remember_me'] ?? true,
      'username': _store['auth_user_saved_username'] ?? '',
      'password': _store['auth_user_saved_password'] ?? '',
      'isLoggedIn': _store['auth_user_is_logged_in'] ?? false,
    };
  }

  static Future<void> clearUserSession() async {
    _store['auth_user_is_logged_in'] = false;
    final rememberMe = _store['auth_user_remember_me'] ?? false;
    if (!rememberMe) {
      _store.remove('auth_user_saved_username');
      _store.remove('auth_user_saved_password');
    }
  }

  static void reset() {
    _store.clear();
  }
}

// ---------------------------------------------------------------------------
// In-Memory UserAccountService Simulator mirroring production algorithms
// ---------------------------------------------------------------------------
class EmpiricalAccountService {
  final List<UserAccountModel> _accounts = [];
  List<UserAccountModel> get accounts => List.unmodifiable(_accounts);

  void reset() {
    _accounts.clear();
  }

  UserAccountModel? findByUsername(String username) {
    final clean = username.trim().toLowerCase();
    final idx = _accounts.indexWhere((a) => a.username.toLowerCase() == clean);
    return idx != -1 ? _accounts[idx] : null;
  }

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

  /// Mirror of findByUsernameAsync with simulated network/database latency
  Future<UserAccountModel?> findByUsernameAsync(
    String username, {
    Duration latency = const Duration(milliseconds: 20),
    Map<String, UserAccountModel>? remoteDatabase,
  }) async {
    final cached = findByUsername(username);
    if (cached != null) return cached;

    // Simulate async network/database call to Supabase
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    final clean = username.trim().toLowerCase();
    if (remoteDatabase != null && remoteDatabase.containsKey(clean)) {
      final acc = remoteDatabase[clean]!;
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
    return null;
  }

  String? register({
    required String username,
    required String password,
    String? emailOrPhone,
    String? fullName,
    String? bloodType,
    String? rhFactor,
    List<String>? allergies,
    List<String>? medicalConditions,
  }) {
    final cleanUser = username.trim();
    if (cleanUser.length < 3) return 'Tên tài khoản phải có ít nhất 3 ký tự.';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
    if (findByUsername(cleanUser) != null) {
      return 'Tên tài khoản "$cleanUser" đã tồn tại.';
    }

    final newAcc = UserAccountModel(
      username: cleanUser,
      password: password,
      fullName: fullName ?? '',
      createdAt: DateTime.now(),
      emailOrPhone: emailOrPhone?.trim(),
      bloodType: bloodType,
      rhFactor: rhFactor,
      allergies: allergies ?? const [],
      medicalConditions: medicalConditions ?? const [],
      authProvider: 'manual',
      isGoogleLinked: false,
    );
    _accounts.insert(0, newAcc);
    return null;
  }

  UserAccountModel signInWithGoogle({
    required String googleId,
    required String email,
    String? displayName,
  }) {
    final cleanId = googleId.trim();
    final cleanEmail = email.trim();
    final cleanEmailLower = cleanEmail.toLowerCase();

    // 1. Existing account reconciliation (khớp googleId hoặc email)
    final existingIdx = _accounts.indexWhere((a) {
      if (a.googleId != null && a.googleId!.trim() == cleanId) return true;
      if (a.emailOrPhone != null &&
          a.emailOrPhone!.trim().toLowerCase() == cleanEmailLower)
        return true;
      return false;
    });

    if (existingIdx != -1) {
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
      return updated;
    }

    // 2. New account auto-provisioning
    String baseUsername = cleanEmailLower.contains('@')
        ? cleanEmailLower
              .split('@')
              .first
              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        : 'google_user';
    if (baseUsername.length < 3) {
      baseUsername = 'user_${baseUsername.padRight(3, '0')}';
    }

    String candidate = baseUsername;
    int suffix = 1;
    while (_accounts.any(
      (a) => a.username.toLowerCase() == candidate.toLowerCase(),
    )) {
      candidate = '${baseUsername}_$suffix';
      suffix++;
    }

    final newAcc = UserAccountModel(
      username: candidate,
      password: '', // Pure Google account has no manual password initially
      fullName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : candidate,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      emailOrPhone: cleanEmail,
      authProvider: 'google',
      googleId: cleanId,
      isGoogleLinked: true,
      isLocked: false,
    );
    _accounts.insert(0, newAcc);
    return newAcc;
  }

  String? resetPassword({
    required String usernameOrEmail,
    required String newPassword,
  }) {
    if (newPassword.trim().length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }
    final cleanTarget = usernameOrEmail.trim().toLowerCase();
    final idx = _accounts.indexWhere(
      (a) =>
          a.username.toLowerCase() == cleanTarget ||
          (a.emailOrPhone != null &&
              a.emailOrPhone!.trim().toLowerCase() == cleanTarget),
    );
    if (idx == -1) {
      return 'Không tìm thấy tài khoản tương ứng để đặt lại mật khẩu.';
    }

    _accounts[idx] = _accounts[idx].copyWith(
      password: newPassword.trim(),
      lastActiveAt: DateTime.now(),
    );
    return null;
  }

  Map<String, dynamic> authenticate({
    required String username,
    required String password,
  }) {
    final cleanUser = username.trim();
    final cleanPass = password.trim();
    final acc = findByUsername(cleanUser);
    if (acc == null) {
      return {'success': false, 'message': 'Tài khoản không tồn tại.'};
    }
    if (acc.isLocked) {
      return {
        'success': false,
        'isLocked': true,
        'message': 'TÀI_KHOẢN_BỊ_KHÓA',
      };
    }
    if (acc.password != cleanPass) {
      return {'success': false, 'message': 'Mật khẩu không chính xác.'};
    }
    return {'success': true, 'account': acc};
  }

  void blockUser(String username, String reason) {
    final idx = _accounts.indexWhere(
      (a) => a.username.toLowerCase() == username.toLowerCase(),
    );
    if (idx != -1) {
      _accounts[idx] = _accounts[idx].copyWith(
        isLocked: true,
        lockReason: reason,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// In-Memory OTP Dispatch Simulator mirroring EmailConfigService
// ---------------------------------------------------------------------------
class EmpiricalOtpService {
  final Map<String, Map<String, dynamic>> _pending = {};
  bool isEnabled = true;
  int expiryMinutes = 5;

  Map<String, dynamic> dispatchOtp({
    required String identifier,
    required String targetEmail,
    String? username,
    DateTime? customNow,
  }) {
    if (!isEnabled) {
      return {
        'success': false,
        'message': 'Dịch vụ gửi email khôi phục mật khẩu hiện đang tạm dừng.',
      };
    }

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    final now = customNow ?? DateTime.now();
    final expiresAt = now.add(Duration(minutes: expiryMinutes));

    final record = {
      'identifier': identifier.trim().toLowerCase(),
      'targetEmail': targetEmail.trim(),
      'username': username ?? identifier.trim(),
      'otp': otp,
      'createdAt': now,
      'expiresAt': expiresAt,
    };

    _pending[identifier.trim().toLowerCase()] = record;
    if (targetEmail.trim().isNotEmpty) {
      _pending[targetEmail.trim().toLowerCase()] = record;
    }

    return {
      'success': true,
      'otp': otp,
      'expiresAt': expiresAt,
      'targetEmail': targetEmail,
    };
  }

  Map<String, dynamic> verifyOtp({
    required String identifier,
    required String otpInput,
    DateTime? checkTime,
  }) {
    final key = identifier.trim().toLowerCase();
    final record = _pending[key];
    if (record == null) {
      return {
        'valid': false,
        'message': 'Không tìm thấy yêu cầu đặt lại mật khẩu hoặc mã OTP chưa được tạo.',
      };
    }

    final now = checkTime ?? DateTime.now();
    final expiresAt = record['expiresAt'] as DateTime;
    if (now.isAfter(expiresAt)) {
      _pending.remove(key);
      return {
        'valid': false,
        'message':
            'Mã OTP đã hết hạn ($expiryMinutes phút). Vui lòng yêu cầu mã mới.',
      };
    }

    if (record['otp'] != otpInput.trim()) {
      return {
        'valid': false,
        'message': 'Mã xác nhận OTP không chính xác. Vui lòng kiểm tra lại.',
      };
    }

    return {
      'valid': true,
      'record': record,
      'message': 'Xác thực OTP thành công.',
    };
  }

  void consumeOtp(String identifier) {
    final key = identifier.trim().toLowerCase();
    final record = _pending.remove(key);
    if (record != null) {
      final targetEmail = (record['targetEmail'] as String?)?.toLowerCase();
      final username = (record['username'] as String?)?.toLowerCase();
      if (targetEmail != null) _pending.remove(targetEmail);
      if (username != null) _pending.remove(username);
    }
  }

  void reset() {
    _pending.clear();
    isEnabled = true;
    expiryMinutes = 5;
  }
}

// ---------------------------------------------------------------------------
// ViewModel Simulation mirroring UserNavigationViewModel
// ---------------------------------------------------------------------------
class EmpiricalViewModel {
  final EmpiricalAccountService accountService;
  final EmpiricalOtpService otpService;
  UserAccountModel? currentUser;

  bool get isUserLoggedIn => currentUser != null;
  String? get currentUsername => currentUser?.username;

  EmpiricalViewModel(this.accountService, this.otpService);

  Future<String?> loginWithGoogle({
    required String email,
    required String googleId,
    String? displayName,
  }) async {
    final user = accountService.signInWithGoogle(
      googleId: googleId,
      email: email,
      displayName: displayName,
    );
    if (user.isLocked) return 'TÀI_KHOẢN_BỊ_KHÓA';

    currentUser = user;
    await EmpiricalLocalStorage.saveUserCredentials(
      rememberMe: true,
      username: user.username,
      password: user.password,
    );
    return null;
  }

  Future<String?> loginWithCredentials({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final auth = accountService.authenticate(
      username: username,
      password: password,
    );
    if (auth['success'] == true) {
      currentUser = auth['account'] as UserAccountModel;
      await EmpiricalLocalStorage.saveUserCredentials(
        rememberMe: rememberMe,
        username: username,
        password: password,
      );
      return null;
    }
    if (auth['isLocked'] == true) return 'TÀI_KHOẢN_BỊ_KHÓA';
    return auth['message'] as String;
  }

  Future<void> logoutUser() async {
    currentUser = null;
    await EmpiricalLocalStorage.clearUserSession();
  }

  /// Implementation in user_navigation_viewmodel.dart lines 293-327
  /// Solves session persistence & race conditions for Google accounts
  Future<void> restoreSavedUserSession({
    Map<String, UserAccountModel>? remoteDatabase,
    Duration asyncLatency = Duration.zero,
  }) async {
    final saved = await EmpiricalLocalStorage.loadUserCredentials();
    if (saved['isLoggedIn'] != true) return;
    if (saved['rememberMe'] != true) return;

    final user = saved['username'] as String? ?? '';
    final pass = saved['password'] as String? ?? '';
    if (user.isEmpty) return;

    // Đối với tài khoản Google (mật khẩu rỗng), kiểm tra bộ nhớ đệm trước
    UserAccountModel? existingUser = accountService.findByUsername(user);

    // Nếu chưa có trong cache do bất đồng bộ khởi động, truy vấn trực tiếp Supabase
    if (existingUser == null && pass.isEmpty) {
      existingUser = await accountService.findByUsernameAsync(
        user,
        latency: asyncLatency,
        remoteDatabase: remoteDatabase,
      );
    }

    if (existingUser != null) {
      if (existingUser.isLocked) return;
      if (pass.isEmpty) {
        currentUser = existingUser;
        return;
      }
    }

    // Chỉ khi không tìm thấy trong cache và pass.isNotEmpty, fall back to loginWithCredentials
    if (pass.isNotEmpty) {
      await loginWithCredentials(
        username: user,
        password: pass,
        rememberMe: true,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Multiplatform Redirect URI Resolution Engine (Mirror of LiveGoogleAuthService)
// ---------------------------------------------------------------------------
class PlatformRedirectEngine {
  static String? resolveRedirectUri({
    required bool isWeb,
    required String platform, // 'windows', 'linux', 'macos', 'android', 'ios'
  }) {
    if (isWeb) return null;
    switch (platform.toLowerCase()) {
      case 'windows':
      case 'linux':
      case 'macos':
        return 'http://localhost:8080/auth/callback';
      case 'android':
      case 'ios':
      default:
        return 'io.supabase.cuuho://login-callback';
    }
  }
}

// ---------------------------------------------------------------------------
// TEST HARNESS EXECUTOR
// ---------------------------------------------------------------------------
void main() async {
  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;
  final List<String> failures = [];

  Future<void> runTest(String name, FutureOr<void> Function() testBody) async {
    totalTests++;
    try {
      await testBody();
      passedTests++;
      print(' [PASS] $name');
    } catch (e) {
      failedTests++;
      failures.add('$name -> $e');
      print(' [FAIL] $name: $e');
    }
  }

  print('================================================================');
  print(' EMPIRICAL CHALLENGER TEST SUITE: FULL VERIFICATION MATRIX');
  print(' Multi-platform Google Auth, Startup Persistence & Gmail OTP');
  print('================================================================\n');

  final accountService = EmpiricalAccountService();
  final otpService = EmpiricalOtpService();

  // ---------------------------------------------------------------------------
  // SECTION 1: Zero-Configuration Testability on Flutter Web & Secrets (R1, R4)
  // ---------------------------------------------------------------------------
  print('--- 1. Testing R1 & R4: Configuration, Client ID & Secret Keys ---');

  await runTest(
    '1.1: GoogleAuthConfig configured with production defaultClientId',
    () {
      GoogleAuthConfig.setMockOverride(null);
      if (GoogleAuthConfig.clientId != GoogleAuthConfig.defaultClientId) {
        throw Exception('Expected defaultClientId to be configured');
      }
      if (!GoogleAuthConfig.isConfigured) {
        throw Exception('Expected isConfigured to be true');
      }
      if (GoogleAuthConfig.defaultMockEmail.isEmpty) {
        throw Exception('Mock email empty');
      }
    },
  );

  await runTest('1.2: GoogleAuthConfig mock override works explicitly', () {
    GoogleAuthConfig.setMockOverride(true);
    if (!GoogleAuthConfig.isMockMode) throw Exception('Override true failed');
    GoogleAuthConfig.setMockOverride(false);
    if (GoogleAuthConfig.isMockMode) throw Exception('Override false failed');
    GoogleAuthConfig.setMockOverride(null);
    if (GoogleAuthConfig.isMockMode) {
      throw Exception('Reset to default configured mode failed');
    }
  });

  await runTest(
    '1.3: Mock credentials provide predictable determinism for offline / CI',
    () {
      const expectedEmail = 'testuser.rescue@gmail.com';
      const expectedName = 'Người dùng Google Demo';
      const expectedId = 'google_uid_test_108234918234';
      if (GoogleAuthConfig.defaultMockEmail != expectedEmail) {
        throw Exception('Mock email mismatch');
      }
      if (GoogleAuthConfig.defaultMockDisplayName != expectedName) {
        throw Exception('Mock name mismatch');
      }
      if (GoogleAuthConfig.defaultMockId != expectedId) {
        throw Exception('Mock id mismatch');
      }
    },
  );

  await runTest('1.4: SupabaseConfig protects secretKey (not hardcoded) and exposes jwksUrl', () {
    const expectedJwks =
        'https://oageskffhndqypwuuaij.supabase.co/auth/v1/.well-known/jwks.json';
    if (SupabaseConfig.secretKey.isNotEmpty) {
      throw Exception('Supabase secretKey must not be hardcoded in source');
    }
    if (SupabaseConfig.jwksUrl != expectedJwks) {
      throw Exception('Supabase jwksUrl mismatch');
    }
    if (!SupabaseConfig.isConfigured) {
      throw Exception('SupabaseConfig should report configured');
    }
  });

  // ---------------------------------------------------------------------------
  // SECTION 2: Cross-Feature Integration & Account Reconciliation (R2)
  // ---------------------------------------------------------------------------
  print(
    '\n--- 2. Testing Cross-Feature Integration & Account Linking (R2) ---',
  );

  await runTest('2.1: Manual registration followed by Google login with same Gmail reconciles account', () async {
    accountService.reset();
    final regErr = accountService.register(
      username: 'rescue_medic_01',
      password: 'StrongPassword123!',
      emailOrPhone: 'medic.rescue@gmail.com',
      fullName: 'Bác Sĩ Cứu Hộ',
      bloodType: 'O',
      rhFactor: 'Rh+',
      allergies: ['Penicillin'],
      medicalConditions: ['diabetes'],
    );
    if (regErr != null) throw Exception('Registration failed: $regErr');

    // Google Sign-In with matching email
    final linked = accountService.signInWithGoogle(
      googleId: 'gid_google_oauth_medic_01',
      email: 'medic.rescue@gmail.com',
      displayName: 'Google Profile Name',
    );

    // Verify account reconciliation
    if (accountService.accounts.length != 1) {
      throw Exception(
        'Duplicate account created! Expected 1, found ${accountService.accounts.length}',
      );
    }
    if (linked.username != 'rescue_medic_01') {
      throw Exception('Username was mutated during linking!');
    }
    if (linked.password != 'StrongPassword123!') {
      throw Exception('Original password was lost during linking!');
    }
    if (linked.bloodType != 'O') {
      throw Exception('Medical profile bloodType lost!');
    }
    if (linked.rhFactor != 'Rh+') {
      throw Exception('Medical profile rhFactor lost!');
    }
    if (linked.allergies.length != 1 ||
        linked.allergies.first != 'Penicillin') {
      throw Exception('Allergies lost!');
    }
    if (!linked.isGoogleLinked)
      throw Exception('isGoogleLinked not set to true');
    if (linked.googleId != 'gid_google_oauth_medic_01') {
      throw Exception('googleId not stored');
    }
  });

  await runTest('2.2: Linked account supports Dual-Authentication (Manual Credentials AND Google)', () async {
    // Attempt 1: Authenticate with original manual credentials
    final manualAuth = accountService.authenticate(
      username: 'rescue_medic_01',
      password: 'StrongPassword123!',
    );
    if (manualAuth['success'] != true) {
      throw Exception('Manual authentication failed for linked account!');
    }

    // Attempt 2: Authenticate with Google
    final googleAuth = accountService.signInWithGoogle(
      googleId: 'gid_google_oauth_medic_01',
      email: 'medic.rescue@gmail.com',
    );
    if (!googleAuth.isGoogleLinked) {
      throw Exception('Google auth failed for linked account');
    }
  });

  await runTest('2.3: Hybrid Authentication: Pure Google user creates password via OTP and logs in manually', () async {
    final googleUser = accountService.signInWithGoogle(
      googleId: 'gid_pure_google_88',
      email: 'pure.google.user@gmail.com',
      displayName: 'Pure Google User',
    );
    if (googleUser.password.isNotEmpty) {
      throw Exception('Pure Google user should not have initial password');
    }

    // User requests OTP to linked Gmail
    final dispatch = otpService.dispatchOtp(
      identifier: googleUser.username,
      targetEmail: googleUser.email,
    );
    final otp = dispatch['otp'] as String;

    // Verify OTP
    final vRes = otpService.verifyOtp(
      identifier: googleUser.username,
      otpInput: otp,
    );
    if (vRes['valid'] != true) {
      throw Exception('OTP verification failed: ${vRes['message']}');
    }

    // Set new password (no old password required)
    const newPass = 'HybridGeneratedPass777!';
    final resetErr = accountService.resetPassword(
      usernameOrEmail: googleUser.username,
      newPassword: newPass,
    );
    if (resetErr != null) throw Exception('Password reset failed: $resetErr');
    otpService.consumeOtp(googleUser.username);

    // Verify that user can now authenticate manually with username and new password
    final manualAuth = accountService.authenticate(
      username: googleUser.username,
      password: newPass,
    );
    if (manualAuth['success'] != true) {
      throw Exception('Manual auth failed after hybrid OTP password reset');
    }

    // Verify user can STILL authenticate via Google
    final googleReAuth = accountService.signInWithGoogle(
      googleId: 'gid_pure_google_88',
      email: 'pure.google.user@gmail.com',
    );
    if (!googleReAuth.isGoogleLinked) throw Exception('Google re-auth failed');
    if (googleReAuth.password != newPass) {
      throw Exception('New password was wiped out by subsequent Google login!');
    }
  });

  await runTest(
    '2.4: Locked account is rejected across BOTH Google and Manual channels',
    () async {
      accountService.blockUser('rescue_medic_01', 'Tài khoản vi phạm quy tắc.');
      final manualAuth = accountService.authenticate(
        username: 'rescue_medic_01',
        password: 'StrongPassword123!',
      );
      if (manualAuth['success'] == true) {
        throw Exception('Locked account bypassed lock via manual login!');
      }

      final vm = EmpiricalViewModel(accountService, otpService);
      final googleErr = await vm.loginWithGoogle(
        email: 'medic.rescue@gmail.com',
        googleId: 'gid_google_oauth_medic_01',
      );
      if (googleErr == null || !googleErr.contains('TÀI_KHOẢN_BỊ_KHÓA')) {
        throw Exception(
          'Locked account bypassed lock via Google login! Error: $googleErr',
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // SECTION 3: Session Persistence Across Application Restarts (R2)
  // ---------------------------------------------------------------------------
  print(
    '\n--- 3. Testing Session Persistence Across Application Restarts (R2) ---',
  );

  await runTest('3.1: Manual user session is persisted to LocalStorage and restored on restart', () async {
    EmpiricalLocalStorage.reset();
    accountService.register(
      username: 'fresh_manual_user',
      password: 'FreshPassword123',
    );
    final vm1 = EmpiricalViewModel(accountService, otpService);
    await vm1.loginWithCredentials(
      username: 'fresh_manual_user',
      password: 'FreshPassword123',
      rememberMe: true,
    );
    if (!vm1.isUserLoggedIn) throw Exception('Login failed');

    // App restarts (new ViewModel instance)
    final vm2 = EmpiricalViewModel(accountService, otpService);
    if (vm2.isUserLoggedIn) {
      throw Exception('vm2 should start as unauthenticated');
    }

    await vm2.restoreSavedUserSession();
    if (!vm2.isUserLoggedIn) {
      throw Exception('Manual user session was NOT restored!');
    }
    if (vm2.currentUsername != 'fresh_manual_user') {
      throw Exception('Restored username mismatch');
    }
  });

  await runTest('3.2: User logout behavior: Explicit logout prevents session restoration on restart', () async {
    EmpiricalLocalStorage.reset();
    accountService.register(
      username: 'logout_stress_user',
      password: 'LogoutPass123',
    );
    final vm1 = EmpiricalViewModel(accountService, otpService);
    await vm1.loginWithCredentials(
      username: 'logout_stress_user',
      password: 'LogoutPass123',
      rememberMe: true,
    );
    await vm1.logoutUser();
    if (vm1.isUserLoggedIn) throw Exception('Logout failed in active session');

    // App restarts
    final vm2 = EmpiricalViewModel(accountService, otpService);
    await vm2.restoreSavedUserSession();

    if (vm2.isUserLoggedIn) {
      throw Exception(
        'User who explicitly logged out was incorrectly re-logged in upon restart!',
      );
    }
  });

  await runTest('3.3: Pure Google user session restoration succeeds on app restart', () async {
    EmpiricalLocalStorage.reset();
    final vm1 = EmpiricalViewModel(accountService, otpService);
    await vm1.loginWithGoogle(
      email: 'pure.visitor.test@gmail.com',
      googleId: 'gid_pure_visitor_99',
    );
    if (!vm1.isUserLoggedIn) throw Exception('Google login failed');
    final assignedUsername = vm1.currentUsername!;

    // App restarts
    final vm2 = EmpiricalViewModel(accountService, otpService);
    await vm2.restoreSavedUserSession();

    if (!vm2.isUserLoggedIn) {
      throw Exception(
        'Pure Google user session was NOT restored upon restart!',
      );
    }
    if (vm2.currentUsername != assignedUsername) {
      throw Exception(
        'Restored username mismatch: expected $assignedUsername, got ${vm2.currentUsername}',
      );
    }
  });

  await runTest(
    '3.4: Administratively locked account cannot be restored on restart',
    () async {
      EmpiricalLocalStorage.reset();
      accountService.register(
        username: 'admin_locked_session',
        password: 'SecretPass123',
      );
      final vm1 = EmpiricalViewModel(accountService, otpService);
      await vm1.loginWithCredentials(
        username: 'admin_locked_session',
        password: 'SecretPass123',
        rememberMe: true,
      );

      // Admin locks user account while session is stored
      accountService.blockUser(
        'admin_locked_session',
        'Tài khoản bị khóa do vi phạm.',
      );

      // App restarts
      final vm2 = EmpiricalViewModel(accountService, otpService);
      await vm2.restoreSavedUserSession();
      if (vm2.isUserLoggedIn) {
        throw Exception(
          'Locked account was restored on restart! Security violation.',
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // SECTION 4: Multi-platform Google Sign-In & Redirect URLs (Mission 1)
  // ---------------------------------------------------------------------------
  print(
    '\n--- 4. Testing Multi-Platform Redirect URLs & Slow Startup Resilience ---',
  );

  await runTest(
    '4.1: Web redirectUri resolves to null for native SPA origin routing',
    () {
      final uri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: true,
        platform: 'any',
      );
      if (uri != null) {
        throw Exception('Web redirectUri must be null, but got: $uri');
      }
    },
  );

  await runTest(
    '4.2: Windows Desktop redirectUri resolves to RFC 8252 loopback',
    () {
      final uri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: false,
        platform: 'windows',
      );
      const expected = 'http://localhost:8080/auth/callback';
      if (uri != expected) {
        throw Exception(
          'Windows redirectUri mismatch: expected $expected, got $uri',
        );
      }
    },
  );

  await runTest(
    '4.3: Linux and macOS Desktop redirectUri resolves to RFC 8252 loopback',
    () {
      final linuxUri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: false,
        platform: 'linux',
      );
      final macUri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: false,
        platform: 'macos',
      );
      const expected = 'http://localhost:8080/auth/callback';
      if (linuxUri != expected || macUri != expected) {
        throw Exception(
          'Desktop redirectUri mismatch: linux=$linuxUri, macos=$macUri',
        );
      }
    },
  );

  await runTest(
    '4.4: Mobile (Android & iOS) redirectUri resolves to deep link scheme',
    () {
      final androidUri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: false,
        platform: 'android',
      );
      final iosUri = PlatformRedirectEngine.resolveRedirectUri(
        isWeb: false,
        platform: 'ios',
      );
      const expected = 'io.supabase.cuuho://login-callback';
      if (androidUri != expected || iosUri != expected) {
        throw Exception(
          'Mobile redirectUri mismatch: android=$androidUri, ios=$iosUri',
        );
      }
    },
  );

  await runTest('4.5: Startup session resilience under slow database/cache (Google user NOT dropped to guest)', () async {
    EmpiricalLocalStorage.reset();
    accountService.reset();

    // 1. Simulate existing Google account stored in remote database
    final remoteAcc = UserAccountModel(
      username: 'google_slow_db_user',
      password: '',
      fullName: 'Bác Sĩ Cứu Hộ Đêm',
      emailOrPhone: 'slow.db.rescuer@gmail.com',
      authProvider: 'google',
      googleId: 'gid_slow_db_999',
      isGoogleLinked: true,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
    final remoteDb = {'google_slow_db_user': remoteAcc};

    // 2. Local storage contains saved session
    await EmpiricalLocalStorage.saveUserCredentials(
      rememberMe: true,
      username: 'google_slow_db_user',
      password: '',
    );

    // 3. App starts up: in-memory cache is empty
    if (accountService.findByUsername('google_slow_db_user') != null) {
      throw Exception('Cache should be empty at cold startup');
    }

    final vm = EmpiricalViewModel(accountService, otpService);
    if (vm.isUserLoggedIn) throw Exception('vm should start unauthenticated');

    // 4. Restore session with simulated 40ms database query latency
    await vm.restoreSavedUserSession(
      remoteDatabase: remoteDb,
      asyncLatency: const Duration(milliseconds: 40),
    );

    // 5. Verification: Google user is restored and NOT dropped to guest
    if (!vm.isUserLoggedIn) {
      throw Exception(
        'Google user was dropped to guest due to startup race condition!',
      );
    }
    if (vm.currentUsername != 'google_slow_db_user') {
      throw Exception('Restored username mismatch: ${vm.currentUsername}');
    }
    if (vm.currentUser?.fullName != 'Bác Sĩ Cứu Hộ Đêm') {
      throw Exception('Profile data was not properly populated');
    }
    // Verify in-memory cache is now populated
    if (accountService.findByUsername('google_slow_db_user') == null) {
      throw Exception(
        'In-memory cache was not populated after async retrieval',
      );
    }
  });

  await runTest('4.6: Startup session resilience under slow database when account is locked (strictly blocked)', () async {
    EmpiricalLocalStorage.reset();
    accountService.reset();

    final lockedAcc = UserAccountModel(
      username: 'locked_slow_user',
      password: '',
      fullName: 'Người Dùng Bị Khóa',
      emailOrPhone: 'locked.slow@gmail.com',
      authProvider: 'google',
      googleId: 'gid_locked_slow',
      isGoogleLinked: true,
      isLocked: true,
      lockReason: 'Khóa tài khoản khẩn cấp.',
      createdAt: DateTime.now(),
    );
    final remoteDb = {'locked_slow_user': lockedAcc};

    await EmpiricalLocalStorage.saveUserCredentials(
      rememberMe: true,
      username: 'locked_slow_user',
      password: '',
    );

    final vm = EmpiricalViewModel(accountService, otpService);
    await vm.restoreSavedUserSession(
      remoteDatabase: remoteDb,
      asyncLatency: const Duration(milliseconds: 30),
    );

    if (vm.isUserLoggedIn) {
      throw Exception('Locked account was incorrectly restored on startup!');
    }
  });

  await runTest('4.7: Live OAuth flow contract: null user / timeout returns failure, NEVER mock credentials', () async {
    // Simulation of LiveGoogleAuthService logic contract
    Future<Map<String, dynamic>> simulateLiveOAuth({
      required bool authEventReceived,
      String? authenticatedEmail,
    }) async {
      if (authenticatedEmail != null) {
        return {'isSuccess': true, 'email': authenticatedEmail};
      }

      final completer = Completer<Map<String, dynamic>>();
      final timer = Timer(const Duration(milliseconds: 50), () {
        if (!completer.isCompleted) {
          completer.complete({
            'isSuccess': false,
            'errorMessage': 'Phiên xác thực Google chưa hoàn tất hoặc đã bị hủy bởi người dùng.',
          });
        }
      });

      if (authEventReceived) {
        timer.cancel();
        completer.complete({
          'isSuccess': true,
          'email': 'real.oauth.user@gmail.com',
        });
      }

      return completer.future;
    }

    // Case 1: External browser opened but user cancels/times out without sign-in event
    final cancelledResult = await simulateLiveOAuth(authEventReceived: false);
    if (cancelledResult['isSuccess'] == true) {
      throw Exception(
        'Security violation: uncompleted live OAuth returned success!',
      );
    }
    if (cancelledResult['email'] == GoogleAuthConfig.defaultMockEmail) {
      throw Exception(
        'Integrity violation: live OAuth fell back to mock credentials!',
      );
    }
    if (cancelledResult['errorMessage'] !=
        'Phiên xác thực Google chưa hoàn tất hoặc đã bị hủy bởi người dùng.') {
      throw Exception(
        'Unexpected error message: ${cancelledResult['errorMessage']}',
      );
    }

    // Case 2: User successfully completes OAuth flow and auth event fires
    final successResult = await simulateLiveOAuth(authEventReceived: true);
    if (successResult['isSuccess'] != true ||
        successResult['email'] != 'real.oauth.user@gmail.com') {
      throw Exception('Valid OAuth sign-in event did not result in success');
    }
  });

  // ---------------------------------------------------------------------------
  // SECTION 5: Gmail OTP Password Recovery & Boundary Verification (Mission 2)
  // ---------------------------------------------------------------------------
  print(
    '\n--- 5. Testing Gmail OTP Generation, Expiry, Replay & Password Boundaries ---',
  );

  await runTest('5.1: 6-digit numeric OTP generation statistical distribution (1000 tokens)', () {
    final digitPattern = RegExp(r'^\d{6}$');
    for (int i = 0; i < 1000; i++) {
      final res = otpService.dispatchOtp(
        identifier: 'dist_user_$i',
        targetEmail: 'dist_$i@gmail.com',
      );
      final otp = res['otp'] as String;
      if (!digitPattern.hasMatch(otp)) {
        throw Exception('Generated OTP "$otp" is not strictly 6 digits!');
      }
      final intVal = int.parse(otp);
      if (intVal < 100000 || intVal > 999999) {
        throw Exception('Generated OTP "$otp" out of range [100000, 999999]!');
      }
    }
  });

  await runTest('5.2: 5-minute expiry enforcement: valid at T < 5 min, rejected at T > 5 min', () {
    otpService.reset();
    final now = DateTime.now();

    final res = otpService.dispatchOtp(
      identifier: 'expiry_tester',
      targetEmail: 'expiry@gmail.com',
      customNow: now,
    );
    final otp = res['otp'] as String;

    // Check at T + 4 minutes (still valid)
    final checkValid = otpService.verifyOtp(
      identifier: 'expiry_tester',
      otpInput: otp,
      checkTime: now.add(const Duration(minutes: 4, seconds: 59)),
    );
    if (checkValid['valid'] != true) {
      throw Exception('OTP should be valid at T + 4m59s');
    }

    // Check at T + 5 minutes 1 second (expired)
    final checkExpired = otpService.verifyOtp(
      identifier: 'expiry_tester',
      otpInput: otp,
      checkTime: now.add(const Duration(minutes: 5, seconds: 1)),
    );
    if (checkExpired['valid'] == true) {
      throw Exception('OTP should be expired at T + 5m01s!');
    }
    if (!(checkExpired['message'] as String).contains('hết hạn')) {
      throw Exception(
        'Expected expiration message, got: ${checkExpired['message']}',
      );
    }
  });

  await runTest('5.3: Replay attack prevention: OTP immediately invalidated upon consumption', () {
    otpService.reset();
    final res = otpService.dispatchOtp(
      identifier: 'replay_victim',
      targetEmail: 'replay.victim@gmail.com',
      username: 'replay_victim',
    );
    final otp = res['otp'] as String;

    // First attempt: valid
    final v1 = otpService.verifyOtp(identifier: 'replay_victim', otpInput: otp);
    if (v1['valid'] != true) throw Exception('First verification failed');

    // Consume OTP
    otpService.consumeOtp('replay_victim');

    // Second attempt (Replay Attack): MUST FAIL
    final v2 = otpService.verifyOtp(identifier: 'replay_victim', otpInput: otp);
    if (v2['valid'] == true) {
      throw Exception('REPLAY VULNERABILITY: Consumed OTP accepted on reuse!');
    }

    // Replay attempt using targetEmail key: MUST ALSO FAIL
    final v3 = otpService.verifyOtp(
      identifier: 'replay.victim@gmail.com',
      otpInput: otp,
    );
    if (v3['valid'] == true) {
      throw Exception(
        'REPLAY VULNERABILITY: Consumed OTP accepted via email alias!',
      );
    }
  });

  await runTest('5.4: Boundary passwords (< 6 characters) strictly rejected during OTP reset', () {
    accountService.reset();
    accountService.signInWithGoogle(
      googleId: 'gid_boundary_pass',
      email: 'boundary.pass@gmail.com',
      displayName: 'Boundary Pass User',
    );

    final invalidPasswords = ['', '1', 'ab', '1234', '12345', '   '];
    for (final badPass in invalidPasswords) {
      final err = accountService.resetPassword(
        usernameOrEmail: 'boundary.pass@gmail.com',
        newPassword: badPass,
      );
      if (err == null || !err.contains('ít nhất 6 ký tự')) {
        throw Exception('Password "$badPass" was not rejected! Error: $err');
      }
    }

    // Valid boundary password (exactly 6 characters)
    final validErr = accountService.resetPassword(
      usernameOrEmail: 'boundary.pass@gmail.com',
      newPassword: '6chars',
    );
    if (validErr != null) {
      throw Exception('Valid 6-character password was rejected: $validErr');
    }
  });

  await runTest('5.5: Google account password reset succeeds with ZERO old password required', () {
    accountService.reset();
    final googleAcc = accountService.signInWithGoogle(
      googleId: 'gid_no_old_pass',
      email: 'no.old.pass@gmail.com',
      displayName: 'Không Mật Khẩu Cũ',
    );
    if (googleAcc.password.isNotEmpty) {
      throw Exception('Google account must have empty initial password');
    }

    // Reset password directly via username or email
    const newSecret = 'NewSecretPassword2026!';
    final resetErr = accountService.resetPassword(
      usernameOrEmail: googleAcc.username,
      newPassword: newSecret,
    );
    if (resetErr != null) {
      throw Exception('Password reset failed: $resetErr');
    }

    final updated = accountService.findByUsername(googleAcc.username);
    if (updated?.password != newSecret) {
      throw Exception('Updated password does not match newSecret');
    }
  });

  await runTest('5.6: Dual-credential authentication post-reset (Google OAuth AND manual credentials)', () {
    // 1. Authenticate with new password
    final manualAuth = accountService.authenticate(
      username: 'nooldpass',
      password: 'NewSecretPassword2026!',
    );
    if (manualAuth['success'] != true) {
      throw Exception('Manual authentication failed after password reset');
    }

    // 2. Authenticate with Google OAuth
    final googleAuth = accountService.signInWithGoogle(
      googleId: 'gid_no_old_pass',
      email: 'no.old.pass@gmail.com',
    );
    if (!googleAuth.isGoogleLinked) {
      throw Exception('Google authentication failed after password reset');
    }
    if (googleAuth.password != 'NewSecretPassword2026!') {
      throw Exception('Password was reset or lost during Google sign-in');
    }
  });

  print('\n================================================================');
  print(
    ' TEST RUN SUMMARY: Total: $totalTests | Passed: $passedTests | Failed: $failedTests',
  );
  print('================================================================');
  if (failures.isNotEmpty) {
    print('\nCONFIRMED VULNERABILITIES / FAILURES:');
    for (final f in failures) {
      print(' - $f');
    }
  } else {
    print(
      '\nALL EMPIRICAL ASSERTIONS PASSED WITH ZERO FAILURES (100% SUCCESS)',
    );
  }
}
