# Test Ready: Google Auth, Manual Registration & Gmail OTP Verification Suite

**Status**: READY FOR VERIFICATION  
**Target Suite**: `test/google_auth_and_otp_test.dart`  
**Test Framework**: Flutter Test (`package:flutter_test`)  
**Design Reference**: `TEST_INFRA.md` & `PROJECT.md`  
**Execution Command**:
```powershell
& "D:\fluter\flutter\bin\flutter.bat" test test/google_auth_and_otp_test.dart
```

---

## 1. Test Suite Summary by Tier

| Tier | Category | Number of Tests | Scope & Objective |
|---|---|:---:|---|
| **Tier 1** | **Feature Coverage** | **20** | Verifies the happy path and primary behavior for all four core features (>= 5 tests each): Google login, manual registration, OTP dispatch to Gmail, OTP verification and password reset. |
| | *F1: Google Login* | 5 | Sign-in with mock, auto-provisioning new account, LocalStorage session persistence, model backward compatibility, sign-out & guest reset. |
| | *F2: Manual Registration* | 5 | All fields valid, optional email omitted (Zero-Knowledge), provider assignment (`manual`), duplicate username handling, immediate credential re-login. |
| | *F3: OTP Dispatch to Gmail* | 5 | Dispatch to linked Gmail, username resolution to linked Gmail, 6-digit numeric format & 5-minute expiry, dispatch audit logging, graceful failure when no email exists. |
| | *F4: OTP Verify & Reset* | 5 | OTP code verification, password update without requiring old password for Google users, token consumption replay prevention, hybrid credential login, consecutive bad OTP handling. |
| **Tier 2** | **Boundary & Corner Cases** | **20** | Verifies boundary conditions, error handling, input stress, and failure cascading (>= 5 tests each). |
| | *B1: Google Login Boundaries* | 5 | User cancellation, network error handling, locked account policy enforcement, unicode & emoji display names, unconfigured client ID mock fallback. |
| | *B2: Manual Reg Boundaries* | 5 | Empty fields rejection, short username boundary (< 3 chars), short password boundary (< 6 chars), username whitespace trimming, email sanitization. |
| | *B3: OTP Dispatch Boundaries* | 5 | Non-existent user lookup, whitespace-only identifier rejection, case-insensitive email matching, rapid repeated dispatch overwrite, disabled email service graceful rejection. |
| | *B4: OTP Verify & Reset Boundaries* | 5 | Expired OTP rejection, incorrect code rejection, alphanumeric/invalid format rejection, short new password rejection (< 6 chars), unverified identifier rejection. |
| **Tier 3** | **Cross-Feature Combinations** | **5** | Multi-step integration and cross-feature interactions. |
| | *C3.1* | 1 | Account Linking: Manual registration followed by Google sign-in with matching email reconciles into single record. |
| | *C3.2* | 1 | Hybrid Recovery Flow: Google sign-in -> OTP request to linked Gmail -> password reset -> manual credential login. |
| | *C3.3* | 1 | Session Handover: Manual user active -> logout -> Google user sign-in -> clean session switch. |
| | *C3.4* | 1 | Admin Portal Strict Isolation: Widget test verifying `DangNhapQuanTriView` strictly excludes Google login button. |
| | *C3.5* | 1 | Locked Account Cross-Auth: Verifies that administratively blocked accounts cannot bypass lock via Google or manual paths. |
| **Tier 4** | **Real-World Application Scenarios** | **4** | Realistic user journeys simulating Flutter Web usage. |
| | *S4.1* | 1 | First-time Google user journey with simulated page refresh and session restoration from SharedPreferences. |
| | *S4.2* | 1 | Manual user forgets credentials, recovers via Gmail OTP, updates medical profile. |
| | *S4.3* | 1 | Guest navigates features, escalates to Google account without losing navigation position. |
| | *S4.4* | 1 | Zero-configuration evaluator tests complete auth and OTP lifecycle on localhost without Google Cloud setup. |
| **TOTAL** | | **49 Tests** | **100% Hermetic, Zero-External-Network Dependency** |

---

## 2. Feature & Requirement Traceability Matrix

| Requirement | Acceptance Criteria | Verified By Tests | Status |
|---|---|---|:---:|
| **R1: Google Sign-In** | Google login button in user dialog, updates session & stores profile | F1.1, F1.2, F1.3, F1.4, F1.5, B1.1, B1.2, B1.3, B1.4, S4.1, S4.3 | Covered |
| **R1: Admin Isolation** | Admin portal strictly excludes Google login | C3.4 | Covered |
| **R2: Manual Registration** | Manual registration form intact, supports optional email, creates account | F2.1, F2.2, F2.3, F2.4, F2.5, B2.1, B2.2, B2.3, B2.4, B2.5, S4.2 | Covered |
| **R3: Gmail OTP Reset** | Dispatches OTP to linked Gmail of Google user, verifies and sets new password | F3.1, F3.2, F3.3, F3.4, F4.1, F4.2, F4.3, F4.4, B3.1, B3.3, B4.1, B4.2, C3.2, S4.2 | Covered |
| **R4: Flutter Web & Mock Config** | Configurable via `--dart-define`, automatically falls back to mock mode | B1.5, S4.4 | Covered |

---

## 3. How to Execute the Test Suite

Run the test suite using the standard project Flutter runner:
```powershell
& "D:\fluter\flutter\bin\flutter.bat" test test/google_auth_and_otp_test.dart
```

Or run all project tests:
```powershell
& "D:\fluter\flutter\bin\flutter.bat" test
```

### Verification Checklist
- [x] All 49 test cases are self-contained and isolated.
- [x] Mock storage (`SharedPreferences.setMockInitialValues({})`) is reset in `setUp()`.
- [x] In-memory services (`EmailConfigService`, `GoogleAuthConfig`) reset in `setUp()` and `tearDown()`.
- [x] No dependencies on external network or real Google OAuth credentials.
- [x] 100% compliant with `TEST_INFRA.md` 4-tier matrix.
