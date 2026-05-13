# Architecture Plan — Auth

**Date:** 2026-05-12
**Based on:** MVP Scope v1.0

---

## Project Identity

- **Name:** Auth
- **Platforms:** SPM — multi-target (iOS 17+ + macOS 14+ client, macOS 14+ / Linux server)
- **Scale:** Solo side project — personal-use open-source package

---

## Component Structure

| Folder | Purpose |
|--------|---------|
| `Sources/AuthShared/` | Shared Codable request/response types and JWT metadata models |
| `Sources/AuthClient/` | iOS SwiftUI auth views, MVVM ViewModels, Keychain token storage, silent refresh |
| `Sources/AuthServer/` | Vapor 4 auth routes, JWT middleware, Fluent User/RefreshToken models |
| `Tests/AuthSharedTests/` | Unit tests for shared models |
| `Tests/AuthClientTests/` | Unit + snapshot tests for client views and ViewModels |
| `Tests/AuthServerTests/` | Unit + integration tests for server routes |
| `docs/` | Documentation, ADRs, design specs |

### SPM Products

| Product | Targets exposed | Consumer |
|---------|----------------|---------|
| `AuthShared` | `AuthShared` | Both iOS and Vapor host projects |
| `AuthClient` | `AuthClient` (+ transitive `AuthShared`) | iOS host projects |
| `AuthServer` | `AuthServer` (+ transitive `AuthShared`) | Vapor host projects |
| `AuthKit` | `AuthShared` + `AuthClient` + `AuthServer` | Full-stack projects wanting a single import |

---

## Tech Stack

| Target | Language / Framework | Architecture Pattern |
|--------|---------------------|---------------------|
| `AuthShared` | Swift 6.2 — Codable structs, no dependencies | Plain value types |
| `AuthClient` | Swift 6.2 — SwiftUI, iOS 17.0+ | MVVM with `@Observable` (Swift 5.9 / iOS 17) |
| `AuthServer` | Swift 6.2 — Vapor 4, jwt-kit 5, Fluent 4 | Vapor route controllers + Fluent models |

---

## Testing Strategy

| Target | Enabled Test Types |
|--------|-------------------|
| `AuthShared` | Unit |
| `AuthClient` | Unit, Snapshot (swift-snapshot-testing) |
| `AuthServer` | Unit, Integration (in-memory Vapor `Application`) |

---

## Third-Party Dependencies

| Target | Package | Product | Purpose |
|--------|---------|---------|---------|
| `AuthClient` | `google/GoogleSignIn-iOS` 9.1.0 | `GoogleSignIn` | Google Sign-In OAuth flow |
| `AuthClient` | Apple Security framework (system) | — | JWT + refresh token Keychain storage (direct, no third-party wrapper) |
| `AuthClient` (tests) | `pointfreeco/swift-snapshot-testing` 1.19.2 | `SnapshotTesting` | SwiftUI view snapshot tests |
| `AuthServer` | `vapor/vapor` 4.121.4 | `Vapor` | HTTP framework + auth middleware |
| `AuthServer` | `vapor/jwt-kit` 5.5.0 | `JWTKit` | JWT signing, verification, and key management |
| `AuthServer` | `vapor/fluent` 4.13.0 | `Fluent` | Driver-agnostic ORM for User/RefreshToken models |

> **Note:** `AuthenticationServices` (Sign in with Apple) is a system framework — no SPM dependency required.
> All package versions above should be verified against the latest stable releases at integration time.

---

## Infrastructure

| Item | Decision | Details |
|------|----------|---------|
| GitHub Project | Yes | Views: Roadmap, Board, Backlog |
| GitHub Actions CI | Yes | Runs `swift test` across iOS + macOS platforms on push/PR |
| Fastlane | Yes | `mac test` lane — runs `swift test`; no Apple credentials required for SPM |
| API Hosting | N/A | SPM package — no hosted service |
| Promo Web | N/A | SPM package — no promotional website |

### Fastlane Details

| Field | Value |
|-------|-------|
| Fastlane lane | `mac test` |
| Command | `swift test` |
| Apple credentials | Not required (SPM only) |

---

## ADRs

| # | Title | Decision |
|---|-------|----------|
| ADR-001 | Multi-target SPM structure | Three targets: `AuthShared` (shared), `AuthClient` (iOS), `AuthServer` (Vapor) |
| ADR-002 | `@Observable` and iOS 17.0 deployment target | Use `@Observable` macro; bump deployment target from 16.0 to 17.0 |
| ADR-003 | Non-rotating refresh tokens | Non-rotating tokens with configurable TTL (default: 1 day) |
| ADR-004 | Driver-agnostic Fluent persistence | `AuthServer` declares Fluent models only; host app provides the DB driver |
| ADR-005 | Email transport as injected closure | Async closure `(String, String, String) async throws -> Void`; no bundled SMTP |

---

## AuthClient Presentation Mechanism

The adopting app is not limited to a single fixed auth entry point. `AuthClient` exposes an `@Observable` class — `AuthManager` — that the host app uses to trigger auth UI from any context.

**Integration pattern:**

1. The host app attaches a `.authSheet(manager:)` SwiftUI view modifier to its root view once. This modifier owns the sheet presentation state.
2. From any screen (Profile, paywall, feature gate, etc.), the host app calls `authManager.presentAuthFlow()`.
3. `AuthManager` sets internal state that the modifier observes, which causes the sheet to appear.
4. On successful sign-in or registration, `AuthManager` dismisses the sheet and publishes the updated auth state.

**Guest upgrade:** when the current session is a guest session, the auth screens presented via this mechanism automatically include credential-attachment logic — on completion the guest UUID is preserved and credentials are attached to it. The host app does not need to distinguish between "new sign-in" and "guest upgrade" call sites.

**`AuthManager` is the single source of truth for auth state** in the host app. It exposes the current session (authenticated / guest / unauthenticated) as an `@Observable` property so any view can react to changes.

---

## AuthClient Configuration

`AuthClient` is configured via an `AuthClientConfiguration` struct passed at setup time by the adopting app. All properties are developer-facing — the end user never sees or changes them.

| Property | Type | Default | Effect |
|----------|------|---------|--------|
| `allowGuestAccess` | `Bool` | `true` | When `false`, all guest / anonymous sign-in UI is hidden; the guest auth flow is completely removed from the screens |
| `primaryColor` | `Color` | system accent | Tint applied to buttons and interactive elements |
| `backgroundColor` | `Color` | system background | Screen background color |
| `font` | `Font?` | `nil` (system default) | Custom font applied to all auth screens |

> **Rule:** any feature that can be toggled on/off in `AuthClient` must be expressed as a property on `AuthClientConfiguration`, not as a runtime user preference.

---

## Notes

- The `AuthKit` umbrella product is a convenience: it exposes all three targets via a single import for full-stack projects. Host apps that only need the iOS side should import `AuthClient`; host apps that only need the server side should import `AuthServer`.
- Package.swift must declare both `.iOS(.v17)` and `.macOS(.v14)` at the package level. `AuthClient` is a SwiftUI target and supports both iOS and macOS natively — do not guard the entire target with `#if canImport(UIKit)` as UIKit is not available on macOS native. Any UIKit-specific code within `AuthClient` (e.g. UIKit integration points for Google Sign-In) must be individually guarded with `#if canImport(UIKit)`. The `AuthServer` target must never import `AuthClient`; that boundary is enforced by SPM target declarations, not compile-time flags.
- The `AuthServer` target is Linux-compatible — no `macOS`-only APIs should be introduced there.
- Dependency versions noted above are best-effort estimates based on known stable versions as of the architecture date. Verify each against the GitHub release page before adding to Package.swift.
