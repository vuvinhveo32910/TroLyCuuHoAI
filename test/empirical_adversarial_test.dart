// File: test/empirical_adversarial_test.dart
// Dedicated Adversarial Verification & Stress Harness for teamwork_challenger_1

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:do_an_cntt_11/core/auth/google_auth_service.dart';
import 'package:do_an_cntt_11/core/config/google_auth_config.dart';
import 'package:do_an_cntt_11/core/email/email_config_service.dart';
import 'package:do_an_cntt_11/core/storage/local_storage_service.dart';
import 'package:do_an_cntt_11/core/user_management/user_account_service.dart';
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

  group('CHALLENGE 1: Edge Conditions', () {
    test('1.1 User dismisses Google sign-in (isCancelled)', () async {
      final vm = UserViewModel();
      final mockAuth = MockGoogleAuthService(shouldCancel: true);

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);

      expect(error, isNotNull);
      expect(error, contains('hủy'));
      expect(vm.isUserLoggedIn, isFalse);
      expect(vm.currentUser, isNull);
      expect(vm.currentUsername, isNull);
    });

    test(
      '1.2 User account locked by administrator (isLocked == true)',
      () async {
        final service = UserAccountService.instance;
        final uniqueId =
            'gid_locked_adv_${DateTime.now().microsecondsSinceEpoch}';
        final uniqueEmail =
            'locked.adv.${DateTime.now().microsecondsSinceEpoch}@gmail.com';

        // Provision account
        final user = await service.signInWithGoogleAsync(
          googleId: uniqueId,
          email: uniqueEmail,
          displayName: 'Tài khoản thử nghiệm khóa',
        );

        // Lock account
        await service.blockUser(
          username: user.username,
          reason: 'Khóa do vi phạm điều khoản bảo mật.',
        );

        final vm = UserViewModel();
        final mockAuth = MockGoogleAuthService(
          mockEmail: uniqueEmail,
          mockId: uniqueId,
        );

        // Attempt Google sign-in
        final googleErr = await vm.loginWithGoogle(
          authServiceOverride: mockAuth,
        );
        expect(googleErr, isNotNull);
        expect(googleErr, startsWith('TÀI_KHOẢN_BỊ_KHÓA:'));
        expect(googleErr, contains('Khóa do vi phạm'));
        expect(vm.isUserLoggedIn, isFalse);
        expect(vm.currentUser, isNull);

        // Check session was NOT persisted
        final stored = await LocalStorageService.instance.loadUserCredentials();
        expect(stored['isLoggedIn'], isFalse);
      },
    );

    test('1.3 Display name with emojis / unicode / special characters', () async {
      final vm = UserViewModel();
      const specialName =
          r'🚑 Bác Sĩ Cứu Hộ @#$% & <Unicode: 🏥 Đỗ Hữu Bình> 🌟';
      final mockAuth = MockGoogleAuthService(
        mockEmail:
            'unicode.medic.${DateTime.now().microsecondsSinceEpoch}@gmail.com',
        mockDisplayName: specialName,
        mockId: 'gid_unicode_special',
      );

      final error = await vm.loginWithGoogle(authServiceOverride: mockAuth);
      expect(error, isNull);
      expect(vm.isUserLoggedIn, isTrue);
      expect(vm.currentUser?.fullName, equals(specialName));
    });

    test('1.4 Whitespace and empty inputs in manual registration (R2)', () {
      final vm = UserViewModel();

      // Empty username
      expect(
        vm.registerUser(username: '', password: 'validPassword123'),
        isNotNull,
      );

      // Whitespace-only username
      expect(
        vm.registerUser(username: '   ', password: 'validPassword123'),
        isNotNull,
      );

      // Short username (< 3 chars)
      final shortUserErr = vm.registerUser(
        username: 'ab',
        password: 'validPassword123',
      );
      expect(
        shortUserErr,
        isNotNull,
        reason: 'Username with < 3 chars must be rejected',
      );

      // Short password (< 6 chars)
      final shortPassErr = vm.registerUser(
        username: 'valid_user_name',
        password: '12345',
      );
      expect(
        shortPassErr,
        isNotNull,
        reason: 'Password with < 6 chars must be rejected',
      );
    });

    test('1.5 Duplicate username registration rejection & account takeover prevention', () {
      final vm = UserViewModel();
      final originalUname =
          'victim_user_${DateTime.now().microsecondsSinceEpoch}';

      // Original user registers
      final regErr = vm.registerUser(
        username: originalUname,
        password: 'originalPassword123',
      );
      expect(regErr, isNull);
      expect(vm.currentUsername, equals(originalUname));

      // Attacker attempts to register same username with different password
      final attackerVm = UserViewModel();
      final dupErr = attackerVm.registerUser(
        username: originalUname,
        password: 'attackerPassword999',
      );

      // Must return an error and MUST NOT allow account takeover
      expect(
        dupErr,
        isNotNull,
        reason: 'Duplicate username registration must return an error',
      );
      expect(dupErr, contains('đã tồn tại'));
      expect(attackerVm.isUserLoggedIn, isFalse);
    });
  });

  group('CHALLENGE 2: Admin Portal Isolation', () {
    test('2.1 Admin login view source code strictly excludes Google OAuth hooks or buttons', () {
      final adminLoginFile = File(
        'lib/features/admin/views/admin_login_view.dart',
      );
      expect(adminLoginFile.existsSync(), isTrue);

      final content = adminLoginFile.readAsStringSync();

      // Check strictly that NO Google login button or hook is present
      expect(content.contains('GoogleAuthService'), isFalse);
      expect(content.contains('loginWithGoogle'), isFalse);
      expect(content.contains('Đăng nhập bằng Google'), isFalse);
      expect(content.contains('googleId'), isFalse);
      expect(content.contains('GoogleAuthConfig'), isFalse);
    });

    test('2.2 Entire admin feature directory excludes Google auth imports', () {
      final adminDir = Directory('lib/features/admin');
      expect(adminDir.existsSync(), isTrue);

      final dartFiles = adminDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(
          text.contains('google_auth_service.dart'),
          isFalse,
          reason: 'File ${file.path} must not import google_auth_service.dart',
        );
      }
    });
  });

  group('CHALLENGE 3: OTP Password Reset Lifecycle for Google Accounts (R3)', () {
    test('3.1 Requesting OTP via linked Gmail address', () async {
      final vm = UserViewModel();
      final gmail =
          'linked.google.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Google User R3',
        mockId: 'gid_r3_gmail',
      );

      await vm.loginWithGoogle(authServiceOverride: mockAuth);

      final res = vm.requestPasswordResetOtp(gmail);
      expect(res['success'], isTrue);
      expect(res['targetEmail'], equals(gmail));
      expect(res['otp'], isNotNull);
      expect(RegExp(r'^\d{6}$').hasMatch(res['otp'] as String), isTrue);
    });

    test('3.2 Requesting OTP via username of Google-linked account', () async {
      final vm = UserViewModel();
      final gmail =
          'uname.resolved.${DateTime.now().microsecondsSinceEpoch}@gmail.com';
      final mockAuth = MockGoogleAuthService(
        mockEmail: gmail,
        mockDisplayName: 'Google Resolved User',
        mockId: 'gid_r3_uname',
      );

      await vm.loginWithGoogle(authServiceOverride: mockAuth);
      final assignedUname = vm.currentUsername!;

      final res = vm.requestPasswordResetOtp(assignedUname);
      expect(res['success'], isTrue);
      expect(res['targetEmail'], equals(gmail));
    });

    test(
      '3.3 Expiration behavior: OTP strictly rejected after 5 minutes',
      () async {
        final service = EmailConfigService.instance;
        expect(service.config.otpExpiryMinutes, equals(5));

        // Simulate expired OTP by setting negative expiry minutes
        await service.updateConfig(
          service.config.copyWith(otpExpiryMinutes: -1),
        );

        final dispatch = service.generateAndDispatchOtp(
          identifier: 'expired_otp_user',
          targetEmail: 'expired@gmail.com',
        );
        final otp = dispatch['otp'] as String;

        final verify = service.verifyOtp(
          identifier: 'expired_otp_user',
          otpInput: otp,
        );

        expect(verify['valid'], isFalse);
        expect(verify['message'], contains('hết hạn'));
      },
    );

    test('3.4 Rejection of invalid codes and prevention of token reuse (replay attacks)', () {
      final service = EmailConfigService.instance;
      final dispatch = service.generateAndDispatchOtp(
        identifier: 'token_reuse_user',
        targetEmail: 'reuse@gmail.com',
      );
      final validOtp = dispatch['otp'] as String;

      // Rejection of invalid codes
      final badCode1 = service.verifyOtp(
        identifier: 'token_reuse_user',
        otpInput: '000000',
      );
      expect(badCode1['valid'], isFalse);

      final badCode2 = service.verifyOtp(
        identifier: 'token_reuse_user',
        otpInput: 'ABCDEF',
      );
      expect(badCode2['valid'], isFalse);

      // Successful verification
      final goodVerify = service.verifyOtp(
        identifier: 'token_reuse_user',
        otpInput: validOtp,
      );
      expect(goodVerify['valid'], isTrue);

      // Consume OTP (token consumption)
      service.consumeOtp('token_reuse_user');

      // Attempt token reuse (replay)
      final replayVerify = service.verifyOtp(
        identifier: 'token_reuse_user',
        otpInput: validOtp,
      );
      expect(replayVerify['valid'], isFalse);
    });
  });
}
