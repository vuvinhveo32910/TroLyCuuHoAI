// File: test/google_auth_and_otp_test.dart
// ---------------------------------------------------------------------------
// Comprehensive 4-Tier Automated Test Suite for Google Auth, Manual
// Registration, and Gmail OTP Password Reset (Requirements R1, R2, R3, R4)
// Authoritative Matrix: TEST_INFRA.md
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:do_an_cntt_11/core/auth/google_auth_service.dart';
import 'package:do_an_cntt_11/core/config/google_auth_config.dart';
import 'package:do_an_cntt_11/core/email/email_config_service.dart';
import 'package:do_an_cntt_11/core/storage/local_storage_service.dart';
import 'package:do_an_cntt_11/core/user_management/user_account_service.dart';
import 'package:do_an_cntt_11/features/admin/viewmodels/admin_viewmodel.dart';
import 'package:do_an_cntt_11/features/admin/views/admin_login_view.dart';
import 'package:do_an_cntt_11/features/user/models/user_account_model.dart';
import 'package:do_an_cntt_11/features/user/viewmodels/user_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleAuthConfig.setMockOverride(null);
    EmailConfigService.instance.resetToDefaults();
  });

  tearDown(() {
    GoogleAuthConfig.setMockOverride(null);
    EmailConfigService.instance.resetToDefaults();
  });

  // =========================================================================
  // TIER 1: FEATURE COVERAGE (>= 5 tests per feature)
  // =========================================================================

  group('Tier 1 - Feature 1: Google Login (F1)', () {
    test(
      'F1.1: Mock Google Sign-In succeeds and populates user session',
      () async {
        final vm = UserViewModel();
        final mockAuth = MockGoogleAuthService(
          mockEmail: 'rescuer.tier1@gmail.com',
          mockDisplayName: 'Bác Sĩ Cứu Hộ T1',
          mockId: 'google_id_f1_1',
        );

        final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);

        expect(error, isNull);
        expect(vm.isUserLoggedIn, isTrue);
        expect(vm.currentUser, isNotNull);
        expect(vm.currentUser?.emailOrPhone, equals('rescuer.tier1@gmail.com'));
        expect(vm.currentUser?.fullName, equals('Bác Sĩ Cứu Hộ T1'));
        expect(vm.currentUsername, isNotNull);
      },
    );

    test(
      'F1.2: Google Sign-In auto-provisions new account for unregistered email',
      () async {
        final service = UserAccountService.instance;
        final uniqueId = 'gid_${DateTime.now().microsecondsSinceEpoch}';
        final uniqueEmail = 'new.user.$uniqueId@gmail.com';

        final user = await service.signInWithGoogleAsync(
          googleId: uniqueId,
          email: uniqueEmail,
          displayName: 'Người Dùng Mới',
        );

        expect(user.emailOrPhone, equals(uniqueEmail));
        expect(user.authProvider, equals('google'));
        expect(user.googleId, equals(uniqueId));
        expect(user.isGoogleLinked, isTrue);
        expect(user.password, equals(''));
        expect(service.findByUsername(user.username), isNotNull);
      },
    );

    test('F1.3: Google Sign-In persists credentials and session to LocalStorageService', () async {
      final vm = UserViewModel();
      final mockAuth = MockGoogleAuthService(
        mockEmail: 'session.persist@gmail.com',
        mockDisplayName: 'Người Dùng Phiên',
        mockId: 'gid_persist_123',
      );

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(error, isNull);

      final stored = await LocalStorageService.instance.loadUserCredentials();
      expect(stored['isLoggedIn'], isTrue);
      expect(stored['rememberMe'], isTrue);
      expect(stored['username'], equals(vm.currentUsername));
    });

    test('F1.4: UserAccountModel contains Google attributes with backward compatibility', () {
      final googleUser = UserAccountModel(
        username: 'google_user_f14',
        password: '',
        fullName: 'Google User Attributes',
        createdAt: DateTime.now(),
        emailOrPhone: 'user.f14@gmail.com',
        authProvider: 'google',
        googleId: 'gid_f14_attrs',
        isGoogleLinked: true,
      );

      expect(googleUser.authProvider, equals('google'));
      expect(googleUser.googleId, equals('gid_f14_attrs'));
      expect(googleUser.isGoogleLinked, isTrue);

      final map = googleUser.toMap();
      expect(map['auth_provider'], equals('google'));
      expect(map['google_id'], equals('gid_f14_attrs'));
      expect(map['is_google_linked'], isTrue);

      final restored = UserAccountModel.fromMap(map);
      expect(restored.authProvider, equals('google'));
      expect(restored.isGoogleLinked, isTrue);
      expect(restored.googleId, equals('gid_f14_attrs'));
    });

    test(
      'F1.5: Google user logout clears session and returns app to guest mode',
      () async {
        final vm = UserViewModel();
        final mockAuth = MockGoogleAuthService(
          mockEmail: 'logout.test@gmail.com',
          mockDisplayName: 'Đăng Xuất Test',
          mockId: 'gid_logout_123',
        );

        await vm.loginWithGoogle(authServiceOverride: mockAuth);
        expect(vm.isUserLoggedIn, isTrue);

        await vm.logoutUser();
        expect(vm.isUserLoggedIn, isFalse);
        expect(vm.currentUser, isNull);
        expect(vm.currentUsername, isNull);

        final stored = await LocalStorageService.instance.loadUserCredentials();
        expect(stored['isLoggedIn'], isFalse);
      },
    );
  });

  group('Tier 1 - Feature 2: Manual Registration (F2)', () {
    test('F2.1: Manual registration with all valid fields succeeds', () {
      final vm = UserViewModel();
      final uname = 'manual_full_${DateTime.now().microsecondsSinceEpoch}';

      final error = vm.registerUser(
        username: uname,
        password: 'password123',
        emailOrPhone: '$uname@rescue.vn',
      );

      expect(error, isNull);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUsername, equals(uname));
      expect(vm.currentUser?.emailOrPhone, equals('$uname@rescue.vn'));
    });

    test('F2.2: Manual registration without optional email succeeds (Zero-Knowledge)', () {
      final vm = UserViewModel();
      final uname = 'manual_noemail_${DateTime.now().microsecondsSinceEpoch}';

      final error = vm.registerUser(
        username: uname,
        password: 'password123',
        emailOrPhone: null,
      );

      expect(error, isNull);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUser?.emailOrPhone, isNull);
    });

    test('F2.3: Manual registration sets authProvider = manual and isGoogleLinked = false', () {
      final vm = UserViewModel();
      final uname = 'manual_prov_${DateTime.now().microsecondsSinceEpoch}';

      vm.registerUser(username: uname, password: 'password123');

      final user = vm.currentUser!;
      expect(user.authProvider, equals('manual'));
      expect(user.isGoogleLinked, isFalse);
      expect(user.googleId, isNull);
    });

    test(
      'F2.4: Manual registration with duplicate username returns error string',
      () {
        final vm = UserViewModel();
        final uname = 'dup_user_${DateTime.now().microsecondsSinceEpoch}';

        final err1 = vm.registerUser(username: uname, password: 'password123');
        expect(err1, isNull);

        final err2 = vm.registerUser(username: uname, password: 'password456');
        expect(err2, isNotNull);
        expect(err2, contains('đã tồn tại'));
      },
    );

    test('F2.5: Newly registered manual user can log out and log in with credentials', () async {
      final vm = UserViewModel();
      final uname = 'manual_relogin_${DateTime.now().microsecondsSinceEpoch}';

      vm.registerUser(username: uname, password: 'secretPassword888');
      await vm.logoutUser();
      expect(vm.isUserLoggedIn, isFalse);

      final loginErr = await vm.loginWithCredentials(
        username: uname,
        password: 'secretPassword888',
      );
      expect(loginErr, isNull);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUsername, equals(uname));
    });
  });

  group('Tier 1 - Feature 3: OTP Dispatch to Gmail (F3)', () {
    test('F3.1: OTP dispatch succeeds for Google account given linked Gmail address', () async {
      final vm = UserViewModel();
      final gmail =
          'otp.direct.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Google User OTP 1',
        mockId: 'gid_otp_f31',
      );

      await vm.loginWithGoogle(authServiceOverride: mockAuth);

      final result = vm.requestPasswordResetOtp(gmail);
      expect(result['success'], isTrue);
      expect(result['targetEmail'], equals(gmail));
      expect(result['otp'], isNotNull);
      expect((result['otp'] as String).length, equals(6));
    });

    test('F3.2: OTP dispatch given Google username resolves linked Gmail accurately', () async {
      final vm = UserViewModel();
      final gmail =
          'resolve.gmail.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Google User Resolve',
        mockId: 'gid_otp_f32',
      );

      await vm.loginWithGoogle(authServiceOverride: mockAuth);
      final uname = vm.currentUsername!;

      final result = vm.requestPasswordResetOtp(uname);
      expect(result['success'], isTrue);
      expect(result['targetEmail'], equals(gmail));
    });

    test('F3.3: Generated OTP is exactly 6 digits with 5-minute expiry', () {
      final service = EmailConfigService.instance;
      final result = service.generateAndDispatchOtp(
        identifier: 'tester_format',
        targetEmail: 'format.test@gmail.com',
      );

      expect(result['success'], isTrue);
      final otp = result['otp'] as String;
      expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);
      expect(service.config.otpExpiryMinutes, equals(5));
    });

    test(
      'F3.4: OTP dispatch records entry into EmailConfigService audit log',
      () {
        final service = EmailConfigService.instance;
        final initialCount = service.dispatchLogs.length;

        service.generateAndDispatchOtp(
          identifier: 'audit_test_user',
          targetEmail: 'audit.recipient@gmail.com',
        );

        expect(service.dispatchLogs.length, equals(initialCount + 1));
        final lastLog = service.dispatchLogs.last;
        expect(lastLog.recipient, equals('audit.recipient@gmail.com'));
        expect(lastLog.isSuccess, isTrue);
      },
    );

    test('F3.5: OTP dispatch fails gracefully when account has no associated email', () {
      final vm = UserViewModel();
      final uname = 'no_email_user_${DateTime.now().microsecondsSinceEpoch}';

      vm.registerUser(
        username: uname,
        password: 'password123',
        emailOrPhone: null,
      );

      final result = vm.requestPasswordResetOtp(uname);
      expect(result['success'], isFalse);
      expect(result['message'], contains('chưa thiết lập email'));
    });
  });

  group('Tier 1 - Feature 4: OTP Verification & Password Reset (F4)', () {
    test('F4.1: Valid OTP verification succeeds via EmailConfigService', () {
      final service = EmailConfigService.instance;
      final dispatch = service.generateAndDispatchOtp(
        identifier: 'verify_user_f41',
        targetEmail: 'verify.f41@gmail.com',
      );

      final otp = dispatch['otp'] as String;
      final verify = service.verifyOtp(
        identifier: 'verify_user_f41',
        otpInput: otp,
      );

      expect(verify['valid'], isTrue);
      expect(verify['record'], isNotNull);
    });

    test('F4.2: Google account password reset succeeds without requiring old password', () async {
      final service = UserAccountService.instance;
      final user = await service.signInWithGoogleAsync(
        googleId: 'gid_nopass_${DateTime.now().microsecondsSinceEpoch}',
        email:
            'nopass.google.${DateTime.now().microsecondsSinceEpoch}@gmail.com',
      );

      expect(user.password, equals(''));

      final err = await service.resetPasswordAsync(
        usernameOrEmail: user.username,
        newPassword: 'BrandNewGooglePass123',
      );

      expect(err, isNull);
      final refreshed = service.findByUsername(user.username);
      expect(refreshed?.password, equals('BrandNewGooglePass123'));
    });

    test('F4.3: OTP consumption prevents replay attacks', () {
      final service = EmailConfigService.instance;
      final dispatch = service.generateAndDispatchOtp(
        identifier: 'replay_user',
        targetEmail: 'replay@gmail.com',
      );
      final otp = dispatch['otp'] as String;

      final v1 = service.verifyOtp(identifier: 'replay_user', otpInput: otp);
      expect(v1['valid'], isTrue);

      service.consumeOtp('replay_user');

      final v2 = service.verifyOtp(identifier: 'replay_user', otpInput: otp);
      expect(v2['valid'], isFalse);
    });

    test('F4.4: Hybrid login: Google user can log in with manual credentials after OTP reset', () async {
      final vm = UserViewModel();
      final gmail =
          'hybrid.login.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Hybrid User',
        mockId: 'gid_hybrid_44',
      );

      await vm.loginWithGoogle(authServiceOverride: mockAuth);
      final uname = vm.currentUsername!;

      final otpResult = vm.requestPasswordResetOtp(uname);
      final otp = otpResult['otp'] as String;

      final resetErr = vm.verifyAndResetPassword(
        identifier: uname,
        otp: otp,
        newPassword: 'HybridSecretPass999',
      );
      expect(resetErr, isNull);

      await vm.logoutUser();
      expect(vm.isUserLoggedIn, isFalse);

      final loginErr = await vm.loginWithCredentials(
        username: uname,
        password: 'HybridSecretPass999',
      );
      expect(loginErr, isNull);
      expect(vm.isUserLoggedIn, isTrue);
    });

    test('F4.5: Consecutive incorrect OTP codes are rejected prior to correct submission', () {
      final service = EmailConfigService.instance;
      final dispatch = service.generateAndDispatchOtp(
        identifier: 'consec_user',
        targetEmail: 'consec@gmail.com',
      );
      final correctOtp = dispatch['otp'] as String;

      expect(
        service.verifyOtp(
          identifier: 'consec_user',
          otpInput: '000000',
        )['valid'],
        isFalse,
      );
      expect(
        service.verifyOtp(
          identifier: 'consec_user',
          otpInput: '111111',
        )['valid'],
        isFalse,
      );
      expect(
        service.verifyOtp(
          identifier: 'consec_user',
          otpInput: '999999',
        )['valid'],
        isFalse,
      );

      expect(
        service.verifyOtp(
          identifier: 'consec_user',
          otpInput: correctOtp,
        )['valid'],
        isTrue,
      );
    });
  });

  // =========================================================================
  // TIER 2: BOUNDARY & CORNER CASES (>= 5 tests per feature)
  // =========================================================================

  group('Tier 2 - Boundary 1: Google Login Edge Cases (B1)', () {
    test('B1.1: User cancels Google OAuth popup gracefully', () async {
      final vm = UserViewModel();
      final mockAuth = MockGoogleAuthService(shouldCancel: true);

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);

      expect(error, contains('bị hủy'));
      expect(vm.isUserLoggedIn, isFalse);
      expect(vm.currentUser, isNull);
    });

    test('B1.2: Network error during Google sign-in is handled without unhandled exception', () async {
      final vm = UserViewModel();
      final mockAuth = MockGoogleAuthService(
        shouldFail: true,
        failureMessage: 'Máy chủ Google không phản hồi. Lỗi mạng (Timeout).',
      );

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);

      expect(error, contains('Lỗi mạng'));
      expect(vm.isUserLoggedIn, isFalse);
    });

    test('B1.3: Google login blocked if account is locked by admin', () async {
      final service = UserAccountService.instance;
      final uniqueId = 'gid_locked_${DateTime.now().microsecondsSinceEpoch}';
      final uniqueEmail =
          'locked.google.${DateTime.now().microsecondsSinceEpoch}@gmail.com';

      // 1. Create account
      final user = await service.signInWithGoogleAsync(
        googleId: uniqueId,
        email: uniqueEmail,
      );

      // 2. Lock account using blockUser
      await service.blockUser(
        username: user.username,
        reason: 'Vi phạm điều khoản dịch vụ cấp độ 2.',
      );

      // 3. Attempt Google login
      final vm = UserViewModel();
      final mockAuth = MockGoogleAuthService(
        mockEmail: uniqueEmail,
        mockId: uniqueId,
      );

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(error, contains('TÀI_KHOẢN_BỊ_KHÓA'));
      expect(vm.isUserLoggedIn, isFalse);
    });

    test('B1.4: Special unicode characters and emojis in Google profile name handled safely', () async {
      final vm = UserViewModel();
      const complexName = 'BS. Lê Vũ Trường Sơn 🩺 (Cứu Hộ Đêm) 🌟';
      final mockAuth = MockGoogleAuthService(
        mockEmail:
            'unicode.test.${DateTime.now().microsecondsSinceEpoch}@gmail.com',
        mockDisplayName: complexName,
        mockId: 'gid_unicode_123',
      );

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(error, isNull);
      expect(vm.currentUser?.fullName, equals(complexName));
    });

    test(
      'B1.5: Google Client ID configuration and mock mode fallback (R4)',
      () {
        GoogleAuthConfig.setMockOverride(true);
        expect(GoogleAuthConfig.isMockMode, isTrue);
        expect(GoogleAuthConfig.defaultMockEmail, contains('@gmail.com'));
        expect(GoogleAuthConfig.defaultMockDisplayName.isNotEmpty, isTrue);
        GoogleAuthConfig.setMockOverride(null);
        expect(
          GoogleAuthConfig.clientId,
          equals(GoogleAuthConfig.defaultClientId),
        );
      },
    );
  });

  group('Tier 2 - Boundary 2: Manual Registration Boundaries (B2)', () {
    test('B2.1: Empty username or password returns validation error', () {
      final vm = UserViewModel();
      expect(vm.registerUser(username: '', password: 'password123'), isNotNull);
      expect(vm.registerUser(username: 'valid_user', password: ''), isNotNull);
    });

    test('B2.2: Username with fewer than 3 characters is rejected', () {
      final vm = UserViewModel();
      final err = vm.registerUser(username: 'ab', password: 'password123');
      expect(err, contains('ít nhất 3 ký tự'));
    });

    test('B2.3: Password with fewer than 6 characters is rejected', () {
      final vm = UserViewModel();
      final err = vm.registerUser(
        username: 'valid_user_len',
        password: '12345',
      );
      expect(err, contains('ít nhất 6 ký tự'));
    });

    test('B2.4: Username with leading/trailing whitespace is sanitized', () {
      final vm = UserViewModel();
      final base = 'user_trim_${DateTime.now().microsecondsSinceEpoch}';
      final err = vm.registerUser(
        username: '  $base  ',
        password: 'password123',
      );
      expect(err, isNull);
      expect(vm.currentUsername, equals(base));
    });

    test('B2.5: Optional email with whitespace is trimmed properly', () {
      final vm = UserViewModel();
      final uname = 'user_email_trim_${DateTime.now().microsecondsSinceEpoch}';
      final err = vm.registerUser(
        username: uname,
        password: 'password123',
        emailOrPhone: '  trimmed.email@rescue.vn  ',
      );
      expect(err, isNull);
      expect(vm.currentUser?.emailOrPhone, equals('trimmed.email@rescue.vn'));
    });
  });

  group('Tier 2 - Boundary 3: OTP Dispatch Boundaries (B3)', () {
    test('B3.1: Non-existent identifier returns account not found error', () {
      final vm = UserViewModel();
      final result = vm.requestPasswordResetOtp('non_existent_account_xyz_999');
      expect(result['success'], isFalse);
      expect(result['message'], contains('Không tìm thấy tài khoản'));
    });

    test(
      'B3.2: Empty or pure whitespace identifier returns validation error',
      () {
        final vm = UserViewModel();
        final result = vm.requestPasswordResetOtp('     ');
        expect(result['success'], isFalse);
        expect(result['message'], contains('Vui lòng nhập'));
      },
    );

    test(
      'B3.3: Case-insensitive email lookup resolves target account correctly',
      () async {
        final vm = UserViewModel();
        final rawEmail =
            'Case.Sensitive.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
        final mockAuth = MockGoogleAuthService(
          mockEmail: rawEmail,
          mockDisplayName: 'Case User',
          mockId: 'gid_case_123',
        );

        await vm.loginWithGoogle(authServiceOverride: mockAuth);

        final result = vm.requestPasswordResetOtp(rawEmail.toUpperCase());
        expect(result['success'], isTrue);
        expect(
          result['targetEmail']?.toString().toLowerCase(),
          equals(rawEmail.toLowerCase()),
        );
      },
    );

    test('B3.4: Rapid repeated OTP requests refresh token and overwrite active OTP', () {
      final service = EmailConfigService.instance;
      final d1 = service.generateAndDispatchOtp(
        identifier: 'rapid_user',
        targetEmail: 'rapid@gmail.com',
      );
      final otp1 = d1['otp'] as String;

      final d2 = service.generateAndDispatchOtp(
        identifier: 'rapid_user',
        targetEmail: 'rapid@gmail.com',
      );
      final otp2 = d2['otp'] as String;

      expect(
        service.verifyOtp(identifier: 'rapid_user', otpInput: otp1)['valid'],
        isFalse,
      );
      expect(
        service.verifyOtp(identifier: 'rapid_user', otpInput: otp2)['valid'],
        isTrue,
      );
    });

    test('B3.5: OTP dispatch fails gracefully when email service is administratively disabled', () async {
      final service = EmailConfigService.instance;
      await service.updateConfig(service.config.copyWith(isEnabled: false));

      final result = service.generateAndDispatchOtp(
        identifier: 'disabled_svc_user',
        targetEmail: 'disabled@gmail.com',
      );

      expect(result['success'], isFalse);
      expect(result['message'], contains('vô hiệu hóa'));
    });
  });

  group('Tier 2 - Boundary 4: OTP Verify & Reset Boundaries (B4)', () {
    test('B4.1: Expired OTP verification fails', () async {
      final service = EmailConfigService.instance;
      // Configure negative expiry so generated OTP is immediately expired
      await service.updateConfig(service.config.copyWith(otpExpiryMinutes: -1));

      final dispatch = service.generateAndDispatchOtp(
        identifier: 'expired_user',
        targetEmail: 'expired@gmail.com',
      );
      final otp = dispatch['otp'] as String;

      final verify = service.verifyOtp(
        identifier: 'expired_user',
        otpInput: otp,
      );
      expect(verify['valid'], isFalse);
      expect(verify['message'], contains('hết hạn'));
    });

    test('B4.2: Incorrect OTP code fails verification', () {
      final service = EmailConfigService.instance;
      service.generateAndDispatchOtp(
        identifier: 'wrong_otp_user',
        targetEmail: 'wrong@gmail.com',
      );

      final verify = service.verifyOtp(
        identifier: 'wrong_otp_user',
        otpInput: '000000',
      );
      expect(verify['valid'], isFalse);
      expect(verify['message'], contains('không chính xác'));
    });

    test('B4.3: OTP input containing non-digits is rejected', () {
      final service = EmailConfigService.instance;
      service.generateAndDispatchOtp(
        identifier: 'alpha_otp_user',
        targetEmail: 'alpha@gmail.com',
      );

      final verify = service.verifyOtp(
        identifier: 'alpha_otp_user',
        otpInput: '12AB56',
      );
      expect(verify['valid'], isFalse);
    });

    test(
      'B4.4: Password reset rejects new password shorter than 6 characters',
      () async {
        final vm = UserViewModel();
        final err = vm.verifyAndResetPassword(
          identifier: 'any_identifier',
          otp: '123456',
          newPassword: '123',
        );
        expect(err, contains('ít nhất 6 ký tự'));
      },
    );

    test(
      'B4.5: Password reset without existing OTP dispatch returns error',
      () {
        final vm = UserViewModel();
        final err = vm.verifyAndResetPassword(
          identifier: 'never_dispatched_user',
          otp: '123456',
          newPassword: 'ValidNewPassword123',
        );
        expect(err, contains('không hợp lệ hoặc đã hết hạn'));
      },
    );
  });

  // =========================================================================
  // TIER 3: CROSS-FEATURE COMBINATIONS (Pairwise Integration)
  // =========================================================================

  group('Tier 3: Cross-Feature Combinations (C3)', () {
    test('C3.1: Account Linking: Manual registration then Google login with same email links existing account', () async {
      final service = UserAccountService.instance;
      final sharedEmail =
          'shared.link.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final initialUname =
          'manual_before_google_${DateTime.now().microsecondsSinceEpoch}';

      // Step 1: Register manual account
      await service.registerAsync(
        username: initialUname,
        password: 'initialPassword123',
        emailOrPhone: sharedEmail,
      );
      final initialAccount = service.findByUsername(initialUname)!;
      expect(initialAccount.authProvider, equals('manual'));
      expect(initialAccount.isGoogleLinked, isFalse);

      // Step 2: Sign in with Google using matching email
      final googleId = 'gid_linked_${DateTime.now().microsecondsSinceEpoch}';
      final linkedAccount = await service.signInWithGoogleAsync(
        googleId: googleId,
        email: sharedEmail,
        displayName: 'Linked From Google',
      );

      // Step 3: Verify single reconciled account
      expect(linkedAccount.username, equals(initialUname));
      expect(linkedAccount.emailOrPhone, equals(sharedEmail));
      expect(linkedAccount.isGoogleLinked, isTrue);
      expect(linkedAccount.googleId, equals(googleId));
      expect(linkedAccount.authProvider, equals('google'));
    });

    test('C3.2: Hybrid Recovery Flow: Google sign-in -> Gmail OTP reset -> Manual credential authentication', () async {
      final vm = UserViewModel();
      final gmail =
          'hybrid.recovery.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Hybrid Recovery User',
        mockId: 'gid_recov_32',
      );

      // 1. Google sign-in
      await vm.loginWithGoogle(authServiceOverride: mockAuth);
      final uname = vm.currentUsername!;
      expect(vm.isUserLoggedIn, isTrue);

      // 2. Request OTP to Gmail
      final req = vm.requestPasswordResetOtp(gmail);
      expect(req['success'], isTrue);
      final otp = req['otp'] as String;

      // 3. Reset password
      const newSecret = 'BrandNewHybridSecret2026';
      final resetErr = vm.verifyAndResetPassword(
        identifier: gmail,
        otp: otp,
        newPassword: newSecret,
      );
      expect(resetErr, isNull);

      // 4. Logout and authenticate with new credentials
      await vm.logoutUser();
      expect(vm.isUserLoggedIn, isFalse);

      final loginErr = await vm.loginWithCredentials(
        username: uname,
        password: newSecret,
      );
      expect(loginErr, isNull);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUsername, equals(uname));
    });

    test('C3.3: Session Handover: Manual user active -> Logout -> Google user login', () async {
      final vm = UserViewModel();
      final manualUname =
          'session_manual_${DateTime.now().microsecondsSinceEpoch}';
      vm.registerUser(username: manualUname, password: 'password123');
      expect(vm.currentUsername, equals(manualUname));

      await vm.logoutUser();
      expect(vm.isUserLoggedIn, isFalse);

      final mockAuth = MockGoogleAuthService(
        mockEmail: 'next.google@gmail.com',
        mockDisplayName: 'Kế Thừa Google',
        mockId: 'gid_next_33',
      );
      await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUser?.emailOrPhone, equals('next.google@gmail.com'));
      expect(vm.currentUsername, isNot(equals(manualUname)));
    });

    testWidgets(
      'C3.4: Admin Portal Isolation: DangNhapQuanTriView strictly excludes Google login',
      (tester) async {
        final adminVm = AdminViewModel();
        await tester.pumpWidget(
          ChangeNotifierProvider<AdminViewModel>.value(
            value: adminVm,
            child: const MaterialApp(
              home: Scaffold(body: DangNhapQuanTriView()),
            ),
          ),
        );

        // Verify no Google button or text exists on admin portal
        expect(find.textContaining('Google'), findsNothing);
        expect(find.textContaining('Đăng nhập bằng Google'), findsNothing);
        expect(find.byIcon(Icons.g_mobiledata), findsNothing);
      },
    );

    test('C3.5: Locked user cross-authentication rejection', () async {
      final service = UserAccountService.instance;
      final uname = 'locked_cross_${DateTime.now().microsecondsSinceEpoch}';
      final email = '$uname@gmail.com';

      // Register manual user with email
      await service.registerAsync(
        username: uname,
        password: 'password123',
        emailOrPhone: email,
      );

      // Lock account using blockUser
      await service.blockUser(username: uname, reason: 'Nghi ngờ gian lận.');

      final vm = UserViewModel();

      // Attempt 1: Manual login rejected
      final manualErr = await vm.loginWithCredentials(
        username: uname,
        password: 'password123',
      );
      expect(manualErr, contains('TÀI_KHOẢN_BỊ_KHÓA'));

      // Attempt 2: Google login rejected
      final mockAuth = MockGoogleAuthService(
        mockEmail: email,
        mockId: 'gid_locked_cross',
      );
      final googleErr = await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(googleErr, contains('TÀI_KHOẢN_BỊ_KHÓA'));
    });
  });

  // =========================================================================
  // TIER 4: REAL-WORLD APPLICATION SCENARIOS (Realistic User Journeys)
  // =========================================================================

  group('Tier 4: Real-World Application Scenarios (S4)', () {
    test(
      'S4.1: First-time Google user journey with simulated page refresh',
      () async {
        final vm1 = UserViewModel();
        final freshEmail =
            'visitor.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
        final mockAuth = MockGoogleAuthService(
          mockEmail: freshEmail,
          mockDisplayName: 'Du Khách Mới',
          mockId: 'gid_s41_visitor',
        );

        // Step 1: User arrives as guest
        expect(vm1.isUserLoggedIn, isFalse);

        // Step 2: Clicks Google Login
        final err = await vm1.loginWithGoogle(authServiceOverride: mockAuth);
        expect(err, isNull);
        expect(vm1.isUserLoggedIn, isTrue);
        final assignedUsername = vm1.currentUsername!;

        // Step 3: Simulated browser refresh / app restart
        final vm2 = UserViewModel();
        expect(vm2.isUserLoggedIn, isFalse);

        await vm2.restoreSavedUserSession();
        expect(vm2.isUserLoggedIn, isTrue);
        expect(vm2.currentUsername, equals(assignedUsername));
      },
    );

    test('S4.2: Manual user forgets credentials, recovers via Gmail OTP and updates medical profile', () async {
      final vm = UserViewModel();
      final recoveryEmail =
          'rescue.medic.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final uname = 'medic_${DateTime.now().microsecondsSinceEpoch}';

      // 1. Initial registration
      vm.registerUser(
        username: uname,
        password: 'oldForgottenPassword123',
        emailOrPhone: recoveryEmail,
      );
      await vm.logoutUser();

      // 2. Forget password flow
      final otpDispatch = vm.requestPasswordResetOtp(recoveryEmail);
      expect(otpDispatch['success'], isTrue);
      final otp = otpDispatch['otp'] as String;

      // 3. Reset password
      const newSecret = 'SuperSecureMedicPass2026';
      final resetErr = vm.verifyAndResetPassword(
        identifier: recoveryEmail,
        otp: otp,
        newPassword: newSecret,
      );
      expect(resetErr, isNull);

      // 4. Log in with new credentials
      final loginErr = await vm.loginWithCredentials(
        username: uname,
        password: newSecret,
      );
      expect(loginErr, isNull);
      expect(vm.isUserLoggedIn, isTrue);

      // 5. Update medical profile
      final updatedProfile = vm.currentUser!.copyWith(
        bloodType: 'O',
        rhFactor: '+',
      );
      await UserAccountService.instance.updateProfile(updatedProfile);
      final refreshed = UserAccountService.instance.findByUsername(uname);
      expect(refreshed?.bloodType, equals('O'));
      expect(refreshed?.rhFactor, equals('+'));
    });

    test(
      'S4.3: Guest escalates to Google account to preserve session state',
      () async {
        final vm = UserViewModel();
        expect(vm.isUserLoggedIn, isFalse);
        expect(vm.currentScreenIndex, equals(0));

        // Guest navigates to feature screen
        vm.setScreenIndex(1);
        expect(vm.currentScreenIndex, equals(1));

        // Guest chooses to authenticate with Google
        final mockAuth = MockGoogleAuthService(
          mockEmail: 'escalate.guest@gmail.com',
          mockDisplayName: 'Khách Chuyển Đổi',
          mockId: 'gid_s43_guest',
        );
        await vm.loginWithGoogle(authServiceOverride: mockAuth);

        // Screen position remains intact, user identity updated
        expect(vm.currentScreenIndex, equals(1));
        expect(vm.isUserLoggedIn, isTrue);
        expect(vm.currentUser?.fullName, equals('Khách Chuyển Đổi'));
      },
    );

    test('S4.4: Zero-config evaluator tests full auth and OTP lifecycle on localhost without Google credentials', () async {
      // Evaluator tests auth with configured defaultClientId and mock override
      GoogleAuthConfig.setMockOverride(true);
      expect(GoogleAuthConfig.isMockMode, isTrue);
      expect(
        GoogleAuthConfig.clientId,
        equals(GoogleAuthConfig.defaultClientId),
      );

      // Mock service seamlessly provisions test user
      final service = MockGoogleAuthService();
      final authResult = await service.signIn();
      expect(authResult.isSuccess, isTrue);
      expect(authResult.email, equals(GoogleAuthConfig.defaultMockEmail));

      final vm = UserViewModel();
      final err = await vm.loginWithGoogle(authServiceOverride: service);
      expect(err, isNull);
      expect(vm.isUserLoggedIn, isTrue);

      // Dispatches OTP without external network failure
      final otpRes = vm.requestPasswordResetOtp(
        GoogleAuthConfig.defaultMockEmail,
      );
      expect(otpRes['success'], isTrue);

      // Completes password reset
      final resetErr = vm.verifyAndResetPassword(
        identifier: GoogleAuthConfig.defaultMockEmail,
        otp: otpRes['otp'] as String,
        newPassword: 'ZeroConfigEvaluationPass123',
      );
      expect(resetErr, isNull);
      GoogleAuthConfig.setMockOverride(null);
    });
  });
}
