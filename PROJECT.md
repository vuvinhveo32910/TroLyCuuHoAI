# Project: Google Auth, Manual Registration & Gmail OTP Reset

## Architecture
- **Presentation Layer**:
  - `lib/features/user/views/widgets/user_auth_modal_dialog.dart`: User login (Tab 0), manual registration (Tab 1), forgot password & OTP reset (Tab 2).
  - `lib/features/admin/views/admin_login_view.dart`: Isolated admin portal (`/admin`), strictly untouched, no Google sign-in.
- **State Management Layer**:
  - `lib/features/user/viewmodels/user_navigation_viewmodel.dart` (`UserViewModel`): Orchestrates login, registration, session persistence, and OTP reset.
- **Service & Domain Layer**:
  - `lib/core/config/google_auth_config.dart`: Configuration for Google OAuth via `--dart-define=GOOGLE_CLIENT_ID` and fallback detection.
  - `lib/core/auth/google_auth_service.dart`: Abstraction `GoogleAuthService` with `LiveGoogleAuthService` (GIS Web / native) and `MockGoogleAuthService` (zero-config local test mode).
  - `lib/core/user_management/user_account_service.dart`: User account store (Supabase Cloud + in-memory fallback), Google account linking, password reset.
  - `lib/core/email/email_config_service.dart`: OTP generation, 5-minute expiry, dispatch logging, and verification.
  - `lib/core/storage/local_storage_service.dart`: SharedPreferences session persistence for user credentials.
- **Data Models**:
  - `lib/features/user/models/user_account_model.dart`: Zero-Knowledge user account model extended with `authProvider`, `googleId`, `isGoogleLinked`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | `GoogleOAuthConfig` | OAuth configuration via `--dart-define` / project config with mock auto-detection | M1 | spec_miner_survey_3 |
| 2 | `GoogleAuthService` & `MockGoogleAuthService` | Service abstraction supporting production Web GIS and headless/local mock testing | M1 | spec_miner_survey_3 |
| 3 | `UserAccountModel` Google fields | Add `authProvider`, `googleId`, `isGoogleLinked` to model with backward-compatible serialization | M1 | explorer_survey_2 |
| 4 | `UserAccountService` Google Linking | Find or create user account linked to Google email | M1 | explorer_survey_2 |
| 5 | `UserAccountService.resetPasswordAsync` | Reset password without requiring old password after valid OTP consumption | M1 | explorer_survey_2 |
| 6 | `UserNavigationViewModel.loginWithGoogle` | Handle Google sign-in flow, link account, set `_currentUser`, persist session | M1 | explorer_survey_1 |
| 7 | `UserNavigationViewModel.requestPasswordResetOtp` | Resolve linked Gmail when requesting OTP for Google accounts | M1 | explorer_survey_2 |
| 8 | `UserAuthModalDialog` Google Button | Add "Đăng nhập bằng Google" button with Google styling & divider to Tab 0 (Image 1) | M2 | explorer_survey_1 |
| 9 | Manual Registration Preservation | Keep Tab 1 manual registration form and flow intact (Image 2) | M2 | explorer_survey_1 |
| 10 | Admin Portal Isolation | Verify that Admin login view strictly excludes Google login and remains isolated | M2 | explorer_survey_1 |
| 11 | E2E Automated Tests | Independent automated tests verifying Google login, manual registration, and Gmail OTP reset flows | M3 | spec_miner_survey_3 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | `M1_core_auth_services` | `GoogleOAuthConfig`, `GoogleAuthService`, `UserAccountModel` extension, `UserAccountService` linking & reset, `UserNavigationViewModel` integration | none | DONE |
| 2 | `M2_ui_integration` | Tab 0 Google button in `UserAuthModalDialog`, preserve Tab 1 manual registration, verify Admin isolation | M1_core_auth_services | DONE |
| 3 | `M3_e2e_verification` | E2E automated test suite (`test/google_auth_and_otp_test.dart`), compilation validation, adversarial tests, forensic audit | M2_ui_integration | DONE |

## Interface Contracts
### `GoogleAuthService` ↔ `UserNavigationViewModel`
- `Future<GoogleAuthResult> signIn()`
- `Future<void> signOut()`
- `bool get isMockMode`
- `GoogleAuthResult`: contains `bool isSuccess`, `String? email`, `String? displayName`, `String? id`, `String? errorMessage`, `bool isCancelled`.

### `UserAccountService` ↔ `UserNavigationViewModel`
- `Future<UserAccountModel> signInWithGoogleAsync({required String googleId, required String email, String? displayName})`
- `Future<String?> resetPasswordAsync({required String usernameOrEmail, required String newPassword})`
- `Future<String?> registerAsync({required String username, required String password, String? emailOrPhone})`

### `EmailConfigService` ↔ `UserNavigationViewModel`
- `Map<String, dynamic> generateAndDispatchOtp({required String identifier, required String targetEmail})`
- `bool verifyOtp({required String identifier, required String otpInput, String? targetEmail})`
- `void consumeOtp({required String identifier, String? targetEmail})`

## Code Layout
- `lib/core/config/google_auth_config.dart` (M1: Google OAuth configuration)
- `lib/core/auth/google_auth_service.dart` (M1: Google Auth abstraction & mock)
- `lib/features/user/models/user_account_model.dart` (M1: Data model extensions)
- `lib/core/user_management/user_account_service.dart` (M1: Account linking and reset logic)
- `lib/features/user/viewmodels/user_navigation_viewmodel.dart` (M1: Auth and OTP viewmodel orchestration)
- `lib/features/user/views/widgets/user_auth_modal_dialog.dart` (M2: UI integration)
- `test/google_auth_and_otp_test.dart` (M3: Automated E2E & integration test suite)
