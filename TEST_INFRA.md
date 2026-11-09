# Test Infrastructure & Specification Matrix: Google Auth, Manual Registration & OTP Reset

**Version**: 1.0.0  
**Target Platform**: Flutter Web & Mobile (Cross-Platform)  
**Authoritative Scope**: Requirement R1, R2, R3, R4 & Acceptance Criteria (PROJECT.md / ORIGINAL_REQUEST.md)  
**Test Suite File**: `test/google_auth_and_otp_test.dart`  

---

## 1. Overview & Testing Strategy

This document establishes the opaque-box and requirement-driven testing infrastructure for the Google Authentication, Manual Registration, and Gmail OTP Password Reset features. The testing architecture follows a strict **4-Tier Verification Methodology**, ensuring that:
1. Every business feature is exercised with >= 5 independent test cases.
2. Boundary conditions, error channels, and invalid input combinations are verified.
3. Cross-feature pairwise interactions and state transitions (e.g. Account linking, Password handover) behave deterministically.
4. End-to-end real-world user journeys on Flutter Web operate reliably without network flakiness.

All tests utilize standard Flutter testing harnesses (`flutter_test`, `package:provider`, `shared_preferences`) and execute hermetically in CI/CD and local environments via:
```powershell
& "D:\fluter\flutter\bin\flutter.bat" test test/google_auth_and_otp_test.dart
```

---

## 2. The 4-Tier Test Matrix

### Tier 1: Feature Coverage (>= 5 tests per feature)
Covers the primary happy path and fundamental behaviors of each individual feature contract.

| Feature ID | Feature Description | Test Case ID | Test Case Name | Objective / Observable Assertion |
|---|---|---|---|---|
| **F1** | **Google Login** | F1.1 | `test_google_login_mock_success` | Verifies `MockGoogleAuthService` completes sign-in, returns valid `GoogleAuthResult`, sets `_currentUser`, and transitions state to logged in. |
| | | F1.2 | `test_google_login_auto_provisions_account` | Verifies that a first-time Google sign-in automatically registers and provisions a user record with `isGoogleLinked = true`. |
| | | F1.3 | `test_google_login_session_persisted` | Verifies that Google credentials/session are written to `LocalStorageService` (`auth_user_is_logged_in == true`). |
| | | F1.4 | `test_google_login_model_attributes` | Asserts that the authenticated `UserAccountModel` contains `authProvider == 'google'`, `isGoogleLinked == true`, and linked email. |
| | | F1.5 | `test_google_sign_out_clears_session` | Verifies that invoking `logoutUser()` resets `_currentUser` to `null` and returns the app to Guest mode. |
| **F2** | **Manual Registration** | F2.1 | `test_manual_registration_with_all_fields` | Verifies manual registration with username, password, and optional email succeeds and activates user session. |
| | | F2.2 | `test_manual_registration_without_email` | Verifies manual registration without email succeeds (respects Zero-Knowledge optionality). |
| | | F2.3 | `test_manual_registration_sets_manual_provider` | Asserts created account has `authProvider == 'manual'` and `isGoogleLinked == false`. |
| | | F2.4 | `test_manual_registration_duplicate_username_fails` | Verifies attempting to register an existing username returns an informative error string. |
| | | F2.5 | `test_manual_registration_direct_login_capability` | Verifies newly registered manual account can immediately authenticate via `loginWithCredentials()`. |
| **F3** | **OTP Dispatch to Gmail** | F3.1 | `test_otp_dispatch_to_linked_gmail` | Verifies OTP request for Google-linked account dispatches 6-digit OTP to the linked Gmail address. |
| | | F3.2 | `test_otp_dispatch_by_username_resolves_gmail` | Verifies entering username of Google account correctly resolves its linked Gmail for OTP dispatch. |
| | | F3.3 | `test_otp_format_and_expiry_window` | Asserts generated OTP is exactly 6 numeric digits and expiration is configured for 5 minutes. |
| | | F3.4 | `test_otp_dispatch_records_audit_log` | Verifies `EmailConfigService` logs the dispatch event with timestamp, recipient, and status. |
| | | F3.5 | `test_otp_dispatch_fails_gracefully_when_no_email` | Verifies requesting OTP for manual account with no registered email returns explicit failure message. |
| **F4** | **OTP Verify & Reset** | F4.1 | `test_otp_verification_success` | Verifies entering the valid OTP code verifies successfully against `EmailConfigService`. |
| | | F4.2 | `test_google_account_password_reset_without_old_pass` | Verifies Google accounts (which lack prior passwords) can successfully establish a password via `resetPasswordAsync`. |
| | | F4.3 | `test_otp_consumption_prevents_replay` | Verifies that `consumeOtp()` invalidates the token so it cannot be reused. |
| | | F4.4 | `test_hybrid_login_after_otp_password_reset` | Verifies that after setting password via OTP, user can log in with new password manually. |
| | | F4.5 | `test_consecutive_failed_otp_attempts_rejected` | Asserts that wrong OTP codes are consistently rejected prior to correct submission. |

---

### Tier 2: Boundary & Corner Cases (>= 5 tests per feature)
Stress tests boundary conditions, invalid inputs, edge states, and error cascading.

| Feature ID | Category | Test Case ID | Test Case Name | Boundary / Stress Condition | Expected System Behavior |
|---|---|---|---|---|---|
| **B1** | **Google Login Edge Cases** | B1.1 | `test_google_login_cancelled_by_user` | User dismisses Google OAuth popup (`isCancelled: true`). | Graceful exit, user remains guest, error message indicates cancellation without crash. |
| | | B1.2 | `test_google_login_network_error_handled` | Google API throws network or connection timeout. | Returns descriptive error string, app state remains intact. |
| | | B1.3 | `test_google_login_locked_account` | Google account has been administratively locked (`isLocked == true`). | Authentication blocked, displays lockout reason and appeal guidance. |
| | | B1.4 | `test_google_login_special_characters_in_name` | Google profile has unicode/emoji/apostrophes in display name. | Handled cleanly with 100% UTF-8 fidelity. |
| | | B1.5 | `test_google_config_unconfigured_defaults_to_mock` | `--dart-define=GOOGLE_CLIENT_ID` unset or placeholder. | Automatically engages `MockGoogleAuthService` without runtime exception (R4). |
| **B2** | **Manual Registration Boundaries** | B2.1 | `test_manual_reg_empty_fields` | Empty username or empty password. | Validation returns error: "Vui lòng điền đầy đủ...". |
| | | B2.2 | `test_manual_reg_password_mismatch` | Password and confirm password do not match. | Validation rejects with "Mật khẩu xác nhận không trùng khớp". |
| | | B2.3 | `test_manual_reg_short_username` | Username has 2 characters (< 3 min boundary). | Service rejects with minimum length error. |
| | | B2.4 | `test_manual_reg_short_password` | Password has 5 characters (< 6 min boundary). | Service rejects with minimum length error. |
| | | B2.5 | `test_manual_reg_malformed_email` | Optional email contains invalid format (e.g. `user@@domain`). | Sanitized or validated without breaking registration flow. |
| **B3** | **OTP Dispatch Boundaries** | B3.1 | `test_otp_nonexistent_identifier` | Identifier not found in database or cache. | Returns error "Tài khoản không tồn tại trên hệ thống". |
| | | B3.2 | `test_otp_whitespace_only_identifier` | Input is empty string or pure whitespace. | Returns error without attempting dispatch. |
| | | B3.3 | `test_otp_case_insensitive_email_lookup` | Input email entered in mixed case (`TeSt.UsEr@GmAiL.cOm`). | Correctly resolves account regardless of casing. |
| | | B3.4 | `test_otp_rapid_repeated_dispatch` | Requesting OTP multiple times rapidly within 10 seconds. | Replaces/refreshes active pending OTP without memory leak. |
| | | B3.5 | `test_otp_dispatch_when_email_disabled` | `EmailConfigModel.isEnabled == false`. | Graceful failure indicating email dispatch is currently disabled. |
| **B4** | **OTP Verify & Reset Boundaries** | B4.1 | `test_otp_expired_verification_fails` | OTP verified after 5-minute expiry threshold. | Rejected with "Mã OTP đã hết hạn". |
| | | B4.2 | `test_otp_incorrect_code_fails` | OTP input differs from generated code. | Rejected with "Mã OTP không chính xác". |
| | | B4.3 | `test_otp_non_digit_characters` | OTP input contains letters or spaces (`"123abc"`). | Rejected immediately. |
| | | B4.4 | `test_reset_password_short_length` | New password has fewer than 6 characters. | Rejected with minimum length constraint. |
| | | B4.5 | `test_reset_password_confirmation_mismatch` | New password and confirmation do not match. | Rejected before consuming OTP. |

---

### Tier 3: Cross-Feature Combinations (Pairwise & Sequential Integration)
Validates interactions between disparate modules, state transitions, and identity reconciliation.

| Test Case ID | Test Case Name | Cross-Feature Combination | Expected Behavior |
|---|---|---|---|
| **C3.1** | `test_account_linking_manual_then_google` | Manual Registration with Gmail -> Later Google Login with matching Gmail | Existing user account is linked (`isGoogleLinked = true`), preserving prior data and avoiding duplicate records. |
| **C3.2** | `test_hybrid_recovery_flow` | Google Login -> Password Reset via Gmail OTP -> Manual Login | Google user creates manual password via OTP recovery; subsequently can authenticate via either Google or manual credentials. |
| **C3.3** | `test_session_handover_manual_to_google` | Manual User Active -> Logout -> Google User Login | Session transitions cleanly; previous manual credentials cleared; new Google session established. |
| **C3.4** | `test_admin_portal_strict_isolation` | Admin Shell (`DangNhapQuanTriView`) vs User Auth Modal | Admin login strictly lacks Google button; Google tokens cannot authenticate Admin RPC. |
| **C3.5** | `test_locked_user_cross_auth_rejection` | User locked in Admin -> Attempts Google Sign-In & Manual Sign-In | Both authentication pathways are rejected with the same lockout policy. |

---

### Tier 4: Real-World Application Scenarios (Realistic User Journeys)
Simulates end-to-end user experiences on Flutter Web.

| Test Case ID | Test Case Name | Realistic User Journey Scenario |
|---|---|---|
| **S4.1** | `test_journey_first_time_google_user` | New visitor visits web app -> opens auth dialog -> taps "Đăng nhập bằng Google" -> signs in -> profile loaded -> session restored across simulated page refresh. |
| **S4.2** | `test_journey_manual_user_forgets_password` | Registered user forgets credentials -> requests OTP -> verifies OTP from inbox -> sets new password -> logs in and accesses health profile. |
| **S4.3** | `test_journey_guest_escalates_to_google` | Guest analyzes emergency data -> decides to save data -> logs in via Google -> guest records linked to user account. |
| **S4.4** | `test_journey_zero_config_evaluation` | Evaluator clones repository on fresh machine without Google Client ID -> runs app on `localhost` -> Google login functions via Mock mode seamlessly. |

---

## 3. Test Infrastructure Architecture & Harnesses

### Test Doubles & Isolation
1. **`MockGoogleAuthService`**:
   - In-memory deterministic simulation of Google OAuth flow.
   - Configurable mock user profile (`email`, `displayName`, `id`).
   - Supports simulated error triggers (`simulateError`, `simulateCancel`).
2. **`MockLocalStorage`**:
   - Backed by `SharedPreferences.setMockInitialValues({})`.
   - Cleared in `setUp()` and verified in `tearDown()`.
3. **`UserAccountService` In-Memory Reset**:
   - Accounts isolated per test run to prevent cross-test contamination.
4. **`EmailConfigService` In-Memory Reset**:
   - Pending OTP map and logs reset before each test execution.

---

## 4. Verification Command
Run the complete automated test suite:
```powershell
& "D:\fluter\flutter\bin\flutter.bat" test test/google_auth_and_otp_test.dart
```
