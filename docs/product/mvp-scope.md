# MVP Scope — Auth

**Version:** 1.0  
**Date:** 2026-05-12  
**Author:** Product Owner  
**Status:** Draft

---

## Vision

> A drop-in Swift Package that gives any iOS + Vapor project email, Google, and Apple authentication with a shared token lifecycle — no manual wiring of 4–6 separate packages required.

---

## Problem Statement

Every iOS + Vapor project requires manually integrating vapor/jwt-kit, vapor/auth, GoogleSignIn-iOS, AuthenticationServices, a Keychain wrapper, and shared request/response models by hand. There is no token lifecycle owner: JWT generation, Keychain storage, auto-refresh, and logout invalidation are re-implemented from scratch in each project. No existing SPM package unifies the iOS client side and the Vapor server side in a single, configurable module.

---

## Target User

| Attribute | Detail |
|-----------|--------|
| Primary persona | Solo iOS + Vapor Swift developer (personal projects) |
| Platform | Swift Package (SPM) — multi-target: iOS client + Vapor server |
| Technical proficiency | Highly technical (experienced Swift developer) |
| Key pain point | Re-writing authentication boilerplate from scratch for every iOS + Vapor project |
| Motivation to use this app | Add the package, call `configure()`, and get working auth without touching jwt-kit, Keychain, or OAuth SDKs directly |

---

## Value Proposition

> Auth is the only SPM package that covers both the iOS client auth UI and the Vapor server auth backend in a single configurable module. It owns the full token lifecycle — from JWT generation on the server to Keychain storage, automatic refresh, and logout invalidation on the client — and it ships with themed, localised SwiftUI screens so there is nothing to wire, style, or translate.

---

## MVP Goals

1. A developer can add Auth to an iOS + Vapor project and get working email/password, Sign in with Apple, Google Sign-In, and guest authentication with zero hand-rolled boilerplate.
2. The package builds cleanly under Swift 6 strict concurrency mode across all three targets.
3. The full JWT token lifecycle (generation → Keychain storage → auto-refresh → logout invalidation) is handled entirely by the package — the app never manages tokens directly.

---

## Success Metrics

| Metric | Target | Timeframe |
|--------|--------|-----------|
| First successful integration | Package drops into a real iOS + Vapor project with no auth boilerplate | At MVP launch |
| Swift 6 compatibility | Zero warnings or errors under strict concurrency | At MVP launch |
| Auth methods coverage | All four methods (email, Apple, Google, guest) working end-to-end | At MVP launch |

---

## In Scope (MVP)

### Shared target (`AuthShared`)
- [ ] Shared request types: `RegisterRequest`, `LoginRequest`, `ForgotPasswordRequest`, `ResetPasswordRequest`, `SocialAuthRequest`, `GuestAuthRequest`, `UpgradeGuestRequest` (attach email/Apple/Google credentials to an existing guest UUID)
- [ ] Shared response types: `AuthResponse` (JWT + refresh token + expiry), `UserDTO` (id, email, display name)
- [ ] JWT token metadata model (access token, refresh token, expiry date)

### iOS client target (`AuthClient`)
- [ ] SwiftUI `LoginView` with email/password fields and social sign-in buttons
- [ ] SwiftUI `RegisterView` with email, password, and confirm-password fields
- [ ] SwiftUI `ForgotPasswordView` with email field
- [ ] Sign in with Apple button and flow via `AuthenticationServices`
- [ ] Sign in with Google button and flow via `GoogleSignIn-iOS`
- [ ] Guest / anonymous session toggle (configurable on/off)
- [ ] Guest upgrade flow: prompts a guest user to attach email, Google, or Apple credentials; preserves the existing UUID so no data is lost
- [ ] Keychain-based JWT and refresh-token storage via `KeychainAccess`
- [ ] Automatic silent token refresh before expiry
- [ ] Logout: clears Keychain and calls server invalidation endpoint
- [ ] Theming API: configurable primary color, background color, and font
- [ ] Full string localisation (all user-facing strings externalized and overridable)

### Vapor server target (`AuthServer`)
- [ ] `POST /auth/register` — email + password registration, returns `AuthResponse`
- [ ] `POST /auth/login` — email + password login, returns `AuthResponse`
- [ ] `POST /auth/logout` — invalidates refresh token in persistence layer
- [ ] `POST /auth/forgot-password` — generates reset token and triggers email send (email transport configurable via closure)
- [ ] `POST /auth/reset-password` — validates reset token, sets new hashed password
- [ ] `POST /auth/apple` — verifies Apple identity token via `AuthenticationServices`, returns `AuthResponse`
- [ ] `POST /auth/google` — verifies Google identity token, returns `AuthResponse`
- [ ] `POST /auth/guest` — issues anonymous JWT with a new UUID, returns `AuthResponse`
- [ ] `POST /auth/upgrade` — attaches email/Apple/Google credentials to an existing guest UUID; guest token required; returns updated `AuthResponse`
- [ ] JWT middleware for protecting Vapor routes (uses `vapor/jwt-kit`)
- [ ] Persistence via Fluent (driver-agnostic): Fluent models for `User` and `RefreshToken`; host app provides the database driver
- [ ] Configurable JWT signing secret, access token TTL, and refresh token TTL (default: access 1 hour, refresh 1 day; non-rotating — refresh token is reused until it expires)
- [ ] Email transport: pure Swift async closure `(recipient: String, subject: String, body: String) async throws -> Void` injected at configure time; no default transport bundled
- [ ] Password hashing via BCrypt

---

## Out of Scope (Post-MVP)

- macOS client target (iOS only for MVP)
- Additional OAuth providers: GitHub, Facebook, Microsoft, etc.
- Biometric authentication (Face ID / Touch ID as a standalone unlock step)
- Two-factor authentication (TOTP, SMS)
- Magic link / passwordless login
- Linking a second auth provider to an already-upgraded (non-guest) account (e.g. adding Google to an existing email account)
- Admin / user-management Vapor routes (list users, suspend, delete, etc.)
- Push notification on login / suspicious activity alerts
- Rate limiting on auth endpoints (left to the host app's Vapor middleware)
- Example app / demo project (README code samples are sufficient for MVP)

---

## Constraints

| Constraint | Detail |
|------------|--------|
| Timeline | No hard deadline — ship when feature-complete and Swift 6 clean |
| Platform | iOS 16+ (client); Vapor 4 + Swift 6 (server) |
| Monetisation | None — personal-use open-source package |
| Dependencies | vapor/jwt-kit, vapor/auth, google/GoogleSignIn-iOS, Apple AuthenticationServices, kishikawakatsumi/KeychainAccess |
| Known risks | Scope creep (medium) — the auth surface is large; strict adherence to the out-of-scope list is required to ship MVP |

---

## Open Questions

> All questions resolved — none outstanding before architecture planning.

| # | Question | Decision |
|---|----------|----------|
| 1 | Persistence layer | Fluent generics — driver-agnostic; host app provides the database driver |
| 2 | Email transport | Pure Swift async closure injected at configure time; no default transport bundled |
| 3 | Refresh token rotation | Non-rotating; default TTL 1 day (configurable); access token default 1 hour |
| 4 | Guest upgrade | In scope for MVP — guest gets a UUID immediately; upgrading attaches credentials to the same UUID via `POST /auth/upgrade` |
| 5 | Module naming | `AuthShared`, `AuthClient`, `AuthServer` as SPM products; `AuthKit` as umbrella library product |

---

## Approval

| Role | Name | Date | Status |
|------|------|------|--------|
| Product Owner | Marek Loose | 2026-05-12 | Draft |
| Architect | | | Pending |
