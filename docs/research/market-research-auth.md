# Market Research Report — Auth (Multi-target iOS + Vapor Authentication SPM)

**Date:** 2026-05-12
**Platforms Researched:** Swift Package (SPM)

---

## Summary

No existing Swift Package unifies iOS client authentication UI and a Vapor server authentication back-end in a single multi-target SPM module. The iOS and Vapor ecosystems each have mature, standalone pieces (Google's GoogleSignIn-iOS, Apple's AuthenticationServices, vapor/jwt-kit, vapor-community/passage), but developers must stitch these together manually per project. The Auth package targets that integration gap and, for personal use, is a clear Go.

---

## Per-Platform Recommendations

| Platform | Recommendation | Rationale |
|----------|---------------|-----------|
| Swift Package (SPM) | ✅ Go | Gap in ecosystem confirmed: no unified iOS+Vapor auth package exists; rich prior-art to build on |

---

## Existing Packages / Products Found

### Server-side (Vapor)

| Package | Maintainer | Scope | Last Active | Notes |
|---------|-----------|-------|-------------|-------|
| [vapor/auth](https://github.com/vapor/auth) | Vapor core | Basic/bearer auth middleware | Active (core Vapor) | Low-level; no JWT, no OAuth, no UI |
| [vapor/jwt-kit](https://github.com/vapor/jwt-kit) | Vapor core | JWT sign/verify (HMAC, ECDSA, RSA) | Active | Production-grade; no user-management layer |
| [vapor/jwt](https://github.com/vapor/jwt) | Vapor core | Vapor wrapper around jwt-kit | Active | What most Vapor apps add as a dependency |
| [vapor-community/passage](https://swiftpackageindex.com/vapor-community/passage) | Community | Full IdM: JWT, email/phone/username, passwordless, OAuth, account linking | Nov 2025 | Server-only; no iOS client; depends on 36 packages |
| [vapor-community/Imperial](https://swiftpackageindex.com/vapor-community/Imperial) | Community | Federated OAuth (GitHub, Google, Facebook…) | Moderate | Server-only; no client companion |
| [mpdifran/vapor-sign-in-with-apple](https://swiftpackageindex.com/mpdifran/vapor-sign-in-with-apple) | Community | Sign in with Apple verification for Vapor | Low | Single-purpose; no client side |
| [vapor-community/soto-cognito-authentication](https://swiftpackageindex.com/vapor-community/soto-cognito-authentication) | Community | AWS Cognito for Vapor | Low | Ties you to AWS Cognito |

### Client-side (iOS)

| Package | Maintainer | Scope | Notes |
|---------|-----------|-------|-------|
| [google/GoogleSignIn-iOS](https://swiftpackageindex.com/google/GoogleSignIn-iOS) | Google | Google Sign-In SDK (iOS + macOS) | Official; SPM supported; client-only |
| Apple AuthenticationServices | Apple | Sign in with Apple, ASWebAuthenticationSession | Built into iOS 13+; framework, not SPM |
| Auth0.swift | Auth0 | Full auth SDK for iOS | Cloud service dependency; not self-hosted |
| Firebase Auth | Google | Multi-provider auth (email, Google, Apple…) | Firebase dependency; not compatible with Vapor backend |
| [IcaliaLabs/LoginKit](https://github.com/IcaliaLabs/LoginKit) | Community | Login/signup UI screens | Abandoned (ObjC era); no modern SwiftUI support |

### Unified iOS + Vapor

| Package | Notes |
|---------|-------|
| *(none found)* | No SPM package covering both iOS client auth UI and Vapor server auth exists on Swift Package Index or GitHub |

---

## Market Assessment

### Swift Package (SPM)
**Saturation level:** Low — the server-only space has a handful of quality packages; the iOS-only space relies on SDKs from Google/Apple/Auth0; the combined space is empty.

**Top competitor quality (server side):** Strong — vapor/jwt-kit and vapor-community/passage are well-maintained and production-grade for their scope.

**Top competitor quality (client side):** Strong — Google's SDK and Apple's native framework are first-party and reliable.

**Pain points in existing solutions (from forums, tutorials, community discussion):**
- Every iOS + Vapor project requires manually wiring together 4–6 separate packages (vapor/jwt, GoogleSignIn-iOS, AuthenticationServices, Keychain wrapper, email-validation logic…)
- Shared request/response models between client and server must be duplicated or managed in a separate shared package by hand
- No single source of truth for token expiry, refresh strategy, or user UUID assignment across the stack
- Theming and localization must be re-implemented per project
- The concept of sharing models between iOS and Vapor is actively discussed in Swift 7 documentation and blog posts but no plug-in package exists

**Evidence of demand:**
- Multiple tutorials (theswiftdev.com, kodeco.com, getstream.io, vonage.com) walk through setting up auth for iOS + Vapor from scratch — indicating developers want guidance on exactly what Auth would encapsulate
- Swift Forums thread on server-side Swift pain points cites deployment boilerplate as a top concern
- iOS boilerplate market (WrapFast, TheSwiftKit) includes auth as one of the most requested pre-built modules, priced at $50–200 per template — showing developers pay to avoid writing this code

---

## Differentiation Opportunities

1. **The only unified SPM for iOS + Vapor auth.** Every existing package is server-only or client-only. Auth is the first to package both sides together with a shared target, eliminating cross-stack duplication.
2. **Plug-in API over configuration.** Configuring login methods, theme, localization, and token TTL via a Package API (not a runtime config file) means the compiler enforces correctness — a pattern no existing auth package uses.
3. **Guest/anonymous access as a first-class mode.** None of the reviewed packages treat guest access as a built-in, toggleable option.
4. **Localization built-in from day one.** LoginKit (the only prior art with login UI) has no i18n support. All reviewed packages leave localization to the app developer.
5. **Token lifecycle ownership.** Existing packages handle JWT signing (server) or storage (client) but not the full lifecycle: generation → Keychain storage → automatic refresh → logout invalidation → deletion. Auth owns the whole chain.

---

## Risks

| Risk | Severity | Notes |
|------|----------|-------|
| Scope creep | Medium | Covering email, Google, Apple, guest + full token lifecycle + UI theming is a large surface area; phased delivery recommended |
| Google Sign-In iOS SDK dependency | Low | `google/GoogleSignIn-iOS` is a binary XCFramework; SPM support is stable but the package must declare a platform-specific conditional dependency |
| Apple Sign-in policy changes | Low | Apple requires Sign in with Apple if any other third-party login is offered in an App Store app; the Auth package's configurability satisfies this |
| vapor-community/passage future scope | Low | If passage adds an iOS companion target it would become a direct competitor; currently shows no sign of that |
| Personal-use scope | None | For private projects, App Store compliance, privacy policy, and GDPR obligations fall on the app, not this package |

---

## Detailed Recommendations

### Swift Package (SPM)
**Decision:** ✅ Go

**Rationale:** The unified iOS + Vapor auth package is a genuine gap. All constituent technologies are mature and SPM-compatible (vapor/jwt-kit, GoogleSignIn-iOS, AuthenticationServices). The configurable multi-target architecture is novel in this space. For personal use, there are no monetisation, legal, or market risks — the only execution risk is scope.

**Suggested first-party dependencies to build on:**
- `vapor/jwt-kit` — JWT primitives
- `vapor/auth` — Vapor middleware integration
- `google/GoogleSignIn-iOS` — Google login on client
- `Apple AuthenticationServices` — Sign in with Apple on client
- A Keychain wrapper (e.g. `kishikawakatsumi/KeychainAccess`) for token storage
