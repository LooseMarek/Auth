# Auth

> A multi-target Swift Package that gives any iOS + Vapor project email, Google, Apple,
> and guest authentication with a shared token lifecycle — no manual wiring required.

---

## Requirements

- **iOS:** 17.0+
- **macOS:** 14.0+
- **Swift:** 6.2+
- **Vapor:** 4.x (server side)

---

## Products

| Product | Use when… |
|---------|-----------|
| `AuthClient` | Building an iOS / macOS SwiftUI app |
| `AuthServer` | Building a Vapor 4 backend |
| `AuthShared` | Sharing request/response types between both sides |
| `AuthKit` | Full-stack project — imports all three with a single line |

---

## Installation

Add the package to your `Package.swift`:

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/LooseMarek/Auth", from: "1.0.0"),
    ],
    targets: [
        // iOS / macOS app target
        .target(
            name: "MyiOSApp",
            dependencies: [
                .product(name: "AuthClient", package: "Auth"),
            ]
        ),
        // Vapor server target
        .target(
            name: "MyVaporServer",
            dependencies: [
                .product(name: "AuthServer", package: "Auth"),
            ]
        ),
        // Full-stack target (imports AuthShared + AuthClient + AuthServer)
        .target(
            name: "MyFullStackApp",
            dependencies: [
                .product(name: "AuthKit", package: "Auth"),
            ]
        ),
    ]
)
```

---

## iOS Quick-Start

### 1. Configure `AuthManager`

Create an `AuthManager` instance once — typically in your `App` entry point or at the
top of your view hierarchy — and store it as a `@State` property.

```swift
import SwiftUI
import AuthClient

@main
struct MyApp: App {
    @State private var authManager = AuthManager(
        configuration: AuthClientConfiguration()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .authSheet(manager: authManager)
                .environment(authManager)
        }
    }
}
```

### 2. Trigger the auth flow

From any screen, inject the `AuthManager` from the environment and call
`presentAuthFlow()`:

```swift
import SwiftUI
import AuthClient

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Button("Sign In") {
            authManager.presentAuthFlow()
        }
    }
}
```

The `.authSheet(manager:)` modifier observes `isPresentingAuthFlow` and presents the
full auth UI — login, registration, social sign-in, and guest access — automatically.

### 3. React to auth state changes

`AuthManager` exposes a `session` property that updates after every auth event:

```swift
switch authManager.session {
case .authenticated(let user):
    Text("Welcome, \(user.email)")
case .guest(let uuid):
    Text("Browsing as guest \(uuid)")
case .unauthenticated:
    Text("Not signed in")
}
```

### 4. Logout

```swift
Button("Sign Out") {
    Task { await authManager.logout() }
}
```

---

## Vapor Quick-Start

### 1. Configure `AuthServerConfiguration`

```swift
import Vapor
import AuthServer

let config = AuthServerConfiguration(
    jwtSigningSecret: Environment.get("JWT_SECRET") ?? "change-me",
    accessTokenTTL: 3600,    // 1 hour (default)
    refreshTokenTTL: 86400,  // 1 day (default)
    emailTransport: { recipient, subject, body in
        // Deliver via your preferred email provider (SendGrid, SES, etc.)
        try await myEmailProvider.send(to: recipient, subject: subject, body: body)
    },
    appleJWKS: try await fetchAppleJWKS(),   // https://appleid.apple.com/auth/keys
    googleJWKS: try await fetchGoogleJWKS()  // https://www.googleapis.com/oauth2/v3/certs
)
```

### 2. Register migrations

```swift
app.migrations.add(CreateUser())
app.migrations.add(CreateRefreshToken())
app.migrations.add(CreatePasswordResetToken())
try await app.autoMigrate()
```

### 3. Register route controllers

```swift
try app.register(collection: AuthController(configuration: config))
try app.register(collection: GuestAuthController(configuration: config))
try app.register(collection: AppleAuthController(configuration: config))
try app.register(collection: GoogleAuthController(configuration: config))
try app.register(collection: ForgotPasswordController(configuration: config))
try app.register(collection: ResetPasswordController(configuration: config))
try app.register(collection: LogoutController(configuration: config))
try app.register(collection: AccountDeletionController(configuration: config))
try app.register(collection: UpgradeController(configuration: config))
```

This registers the following routes under the `/auth` prefix:

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/register` | Email + password registration |
| `POST` | `/auth/login` | Email + password login |
| `POST` | `/auth/guest` | Anonymous guest session |
| `POST` | `/auth/apple` | Sign in with Apple |
| `POST` | `/auth/google` | Sign in with Google |
| `POST` | `/auth/forgot-password` | Send password reset email |
| `POST` | `/auth/reset-password` | Apply password reset token |
| `POST` | `/auth/logout` | Invalidate refresh token (JWT required) |
| `DELETE` | `/auth/account` | Delete account (JWT required) |
| `POST` | `/auth/upgrade` | Upgrade guest to full account (JWT required) |

### 4. Add a Fluent database driver

`AuthServer` is driver-agnostic — it declares Fluent models only. Add the driver for
your database in the host app:

```swift
// PostgreSQL
import FluentPostgresDriver
app.databases.use(.postgres(configuration: .init(hostname: "localhost", username: "vapor", password: "", database: "auth")), as: .psql)

// SQLite (testing / development)
import FluentSQLiteDriver
app.databases.use(.sqlite(.memory), as: .sqlite)
```

---

## `AuthClientConfiguration` Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `allowGuestAccess` | `Bool` | `true` | When `false`, guest/anonymous sign-in UI is hidden |
| `primaryColor` | `Color?` | Auth Blue (`#0A66FF` light / `#3D8BFF` dark) | Tint applied to buttons and interactive elements |
| `backgroundColor` | `Color?` | System background (adapts to light/dark) | Screen background colour |
| `font` | `Font?` | `nil` (system default) | Custom font applied to all auth screens |

All colour parameters accept `nil` to use the built-in adaptive defaults. Pass `nil` to
use Auth Blue and the system background:

```swift
// All defaults
let config = AuthClientConfiguration()

// Custom primary colour, no guest access
let config = AuthClientConfiguration(
    allowGuestAccess: false,
    primaryColor: .accentColor,
    font: .custom("MyFont-Regular", size: 16)
)
```

---

## `AuthServerConfiguration` Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `jwtSigningSecret` | `String` | _(required)_ | HMAC-SHA256 secret for signing and verifying access tokens. Store in an environment variable — never commit. |
| `accessTokenTTL` | `TimeInterval` | `3600` (1 hour) | Lifetime of an access token in seconds |
| `refreshTokenTTL` | `TimeInterval` | `86400` (1 day) | Lifetime of a refresh token in seconds |
| `emailTransport` | `(@Sendable (String, String, String) async throws -> Void)?` | `nil` | Closure called by `forgot-password` to deliver reset emails. Parameters: `(recipient, subject, body)`. `nil` causes a runtime HTTP 500 on that route. |
| `appleJWKS` | `JWKS?` | `nil` | Apple's public JWKS for verifying Sign in with Apple tokens. Fetch from `https://appleid.apple.com/auth/keys`. `nil` causes a runtime HTTP 500 on `POST /auth/apple`. |
| `googleJWKS` | `JWKS?` | `nil` | Google's public JWKS for verifying Google Sign-In tokens. Fetch from `https://www.googleapis.com/oauth2/v3/certs`. `nil` causes a runtime HTTP 500 on `POST /auth/google`. |

---

## AuthKit — Full-Stack Import

For monorepo or full-stack Swift projects, import the `AuthKit` umbrella product to get
`AuthShared`, `AuthClient`, and `AuthServer` in a single line:

```swift
import AuthKit
```

This is equivalent to importing all three products individually and is convenient for
shared modules or packages that need access to the complete Auth surface.

---

## CI/CD

### GitHub Actions

Workflows in `.github/workflows/` support two trigger modes:

- **Automatic** — triggered on push to `main`/`develop` or on a pull request to `main`
- **Manual** — all workflows can be triggered from the GitHub Actions tab at any time

### Fastlane

```sh
bundle exec fastlane ios test   # run iOS tests
bundle exec fastlane mac test   # run macOS tests
```

Run `bundle install` first to install Fastlane via Bundler.

---

## Development

Refer to `CLAUDE.md` for agent workflow, coding conventions, and architecture decisions.

---

## License

Private — all rights reserved.
