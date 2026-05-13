# Implementation Order — Auth

Tasks must be completed in the order below. Each step lists the GitHub issue and its milestone. Dependencies are noted where one task's output is required before the next can start.

---

## Phase 1 — AuthShared (foundation for all other targets)

Both AuthServer and AuthClient import these types. Complete before writing any server or client code.

| Order | Issue | Title |
|-------|-------|-------|
| 1 | #9 | [Task] Implement AuthShared request types |
| 2 | #10 | [Task] Implement AuthShared response types and TokenMetadata |

---

## Phase 2 — AuthServer Core

Build the server foundation on top of the shared types. JWT middleware and Fluent models must exist before routes can be implemented.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 3 | #11 | [Task] Implement Fluent User and RefreshToken models | #9, #10 |
| 4 | #12 | [Task] Implement JWT middleware and AuthServer configuration | #11 |
| 5 | #13 | [Task] Implement POST /auth/register and POST /auth/login | #11, #12 |
| 6 | #14 | [Task] Implement POST /auth/forgot-password and POST /auth/reset-password | #11, #12 |
| 7 | #15 | [Task] Implement POST /auth/logout and DELETE /auth/account | #11, #12 |

---

## Phase 3 — AuthServer Social + Guest + Upgrade

Extend the server with social identity verification and anonymous sessions. Requires the core Fluent models and JWT middleware from Phase 2.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 8 | #16 | [Task] Implement POST /auth/apple and POST /auth/google | #11, #12 |
| 9 | #17 | [Task] Implement POST /auth/guest and POST /auth/upgrade | #11, #12 |

---

## Phase 4 — AuthClient Core

Build the client foundation: `AuthManager`, Keychain storage, and the three core views. `AuthManager` and `KeychainTokenStore` must be in place before views can wire up to them.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 10 | #18 | [Task] Implement AuthManager and AuthClientConfiguration | #9, #10 |
| 11 | #19 | [Task] Implement KeychainTokenStore (JWT + refresh token storage) | #18 |
| 12 | #20 | [Task] Implement LoginView and LoginViewModel | #18, #19 |
| 13 | #21 | [Task] Implement RegisterView and RegisterViewModel | #18, #19 |
| 14 | #22 | [Task] Implement ForgotPasswordView and ForgotPasswordViewModel | #18, #19 |
| 15 | #23 | [Task] Implement silent token refresh and logout in AuthManager | #18, #19 |

---

## Phase 5 — AuthClient Social Sign-In

Wire Apple and Google sign-in into the existing views. Requires core views and `AuthManager` from Phase 4.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 16 | #24 | [Task] Implement Sign in with Apple flow in AuthClient | #18, #20 |
| 17 | #25 | [Task] Implement Sign in with Google flow in AuthClient | #18, #20 |

---

## Phase 6 — AuthClient Programmatic Presentation + Guest Upgrade

Add the `.authSheet(manager:)` modifier and guest upgrade flow. Requires all core views and social flows to be complete so the sheet can host all screens.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 18 | #26 | [Task] Implement AuthSheetContainer and .authSheet(manager:) modifier | #20, #21, #22, #24, #25 |
| 19 | #27 | [Task] Implement guest session and guest upgrade flow in AuthClient | #17, #18, #19, #26 |

---

## Phase 7 — AuthClient Theming + Localisation

Can run in parallel with Phase 6 once the core views (#20–#22) exist, but must be complete before release.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 20 | #28 | [Task] Implement AuthClientConfiguration theming API | #18, #20, #21, #22 |
| 21 | #29 | [Task] Implement full string localisation (Localizable.strings) | #20, #21, #22 |

---

## Phase 8 — Documentation + Release

Complete only after all feature tasks (#9–#29) are done and CI is green.

| Order | Issue | Title | Depends on |
|-------|-------|-------|------------|
| 22 | #30 | [Task] Write README integration guide | all feature tasks |
| 23 | #31 | [Task] Add doc comments to all public API surfaces | all feature tasks |
| 24 | #32 | [Chore] Finalise Package.swift dependency versions and cut v1.0 release | #30, #31 |
