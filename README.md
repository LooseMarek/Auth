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

> **Prerequisite — `UILaunchScreen` in `Info.plist`**
>
> Your host app's `Info.plist` must contain a `UILaunchScreen` key. Without it, iOS
> renders the app in a legacy compatibility mode and adds black bars at the top and
> bottom of the screen on all modern iPhone models — even with a bare SwiftUI view.
>
> Add the following to your `Info.plist`:
>
> ```xml
> <key>UILaunchScreen</key>
> <dict/>
> ```
>
> An empty dictionary is sufficient. It signals to iOS that the app is designed for
> the current device's full screen dimensions.

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

> **Warning:** `AuthManager.init(configuration:)` injects a no-op stub for `networkService`
> — all auth calls will silently do nothing. For real network calls, inject your own
> `AuthNetworkService` implementation and a `KeychainTokenStore`:
>
> ```swift
> @State private var authManager = AuthManager(
>     configuration: AuthClientConfiguration(),
>     networkService: MyAuthNetworkService(baseURL: URL(string: "https://api.example.com")!),
>     tokenStore: KeychainTokenStore()
> )
> ```
>
> `AuthNetworkService` is a protocol your host app implements. Each method maps to an
> Auth server endpoint (e.g. `login(email:password:)` → `POST /auth/login`). See the
> `AuthNetworkService` protocol documentation for the full list of required methods.

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
full auth UI — login, registration, social sign-in, guest access, and the complete
forgot-password flow — automatically.

> **Forgot-password flow** — `ForgotPasswordView` collects the user's email and
> triggers a reset email (`POST /auth/forgot-password`). After the email is sent,
> the user taps "Enter reset token" to navigate to `ResetPasswordView`, where they
> enter the one-time token from the email together with a new password
> (`POST /auth/reset-password`). On success, a confirmation card prompts the user to
> log in. Both views are pushed automatically by the `AuthSheetContainer` navigation
> stack — no host-app code is needed.

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

// Fetch JWKS from Apple and Google once at startup.
// Both endpoints return a JSON object that JWTKit decodes as `JWKS`.
// Apple:  GET https://appleid.apple.com/auth/keys
// Google: GET https://www.googleapis.com/oauth2/v3/certs
// Note: Apple and Google rotate their signing keys periodically — refresh these on a schedule (e.g. every 24 hours) in production.
let appleJWKS = try await app.client.get("https://appleid.apple.com/auth/keys")
    .content.decode(JWKS.self)
let googleJWKS = try await app.client.get("https://www.googleapis.com/oauth2/v3/certs")
    .content.decode(JWKS.self)

let config = AuthServerConfiguration(
    jwtSigningSecret: Environment.get("JWT_SECRET") ?? "change-me",
    emailTransport: { recipient, subject, body in
        // Deliver via your preferred email provider (SendGrid, SES, etc.)
        // Replace the line below with your actual email SDK call.
        try await myEmailProvider.send(to: recipient, subject: subject, body: body)
    },
    appleJWKS: appleJWKS,
    googleJWKS: googleJWKS
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
try app.register(collection: RefreshTokenController(configuration: config))
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
| `POST` | `/auth/refresh` | Exchange refresh token for new tokens (token rotated) |
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

| Property | Stored Type | Init Parameter Type | Default | Description |
|----------|-------------|---------------------|---------|-------------|
| `allowGuestAccess` | `Bool` | `Bool` | `true` | When `false`, guest/anonymous sign-in UI is hidden |
| `primaryColor` | `Color` | `Color?` | Auth Blue (`#0A66FF` light / `#3D8BFF` dark) | Tint applied to buttons and interactive elements |
| `backgroundColor` | `Color` | `Color?` | System background (adapts to light/dark) | Screen background colour |
| `font` | `Font?` | `Font?` | `nil` (system default) | Custom font applied to all auth screens |

The colour init parameters accept `nil` to use the built-in adaptive defaults. The stored
properties are always non-optional `Color` values resolved inside the init. Pass `nil` to
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

## Configuring Email Transport

The `emailTransport` closure is how `AuthServer` delivers password-reset emails. You
supply the implementation — the package just calls it with three strings:

```swift
// Signature:
// (recipient: String, subject: String, body: String) async throws -> Void
```

**Where to configure it:** open `demo/api/Sources/demoauth/configure.swift` and replace
the `emailTransport` variable with the snippet for your chosen provider.

### Development — log to the Vapor console

During local development you can log the reset token to the server terminal instead of
sending a real email. No environment variables needed. Capture `app.logger` before
creating the closure (the closure itself only receives the three strings):

```swift
let logger = app.logger
emailTransport = { recipient, subject, body in
    logger.notice("[EMAIL] To: \(recipient) | Subject: \(subject) | Body: \(body)")
}
```

The token appears in Vapor's structured log stream alongside other request logs.

### Production — Resend HTTP API

The demo uses [Resend](https://resend.com) — a zero-dependency option that requires
only a `URLSession` call. Set two environment variables before starting the server:

| Variable | Description |
|----------|-------------|
| `RESEND_API_KEY` | Your Resend API key (starts with `re_`) |
| `RESEND_FROM_EMAIL` | Sender address (e.g. `noreply@yourdomain.com`) |

```swift
// Reads RESEND_API_KEY and RESEND_FROM_EMAIL from the environment.
// If RESEND_API_KEY is absent or empty, the console fallback is used automatically.
if let resendAPIKey = Environment.get("RESEND_API_KEY"), !resendAPIKey.isEmpty {
    let fromEmail = Environment.get("RESEND_FROM_EMAIL") ?? "onboarding@resend.dev"
    let resendTransport = makeResendEmailTransport(apiKey: resendAPIKey, fromEmail: fromEmail)
    emailTransport = { recipient, subject, body in
        logger.notice("[EMAIL] To: \(recipient) | Subject: \(subject) | Body: \(body)")
        try await resendTransport(recipient, subject, body)
    }
}
```

The transport also logs every send to the Vapor console, so you always see what was
delivered regardless of which provider is active.

> **Free-tier note:** When `RESEND_FROM_EMAIL` is `onboarding@resend.dev` (Resend's
> built-in test address), Resend only delivers to the email address registered with
> your Resend account. This is sufficient for local demos — copy the reset token
> from your inbox. To send to **any** address, verify a custom domain in the Resend
> dashboard and set `RESEND_FROM_EMAIL` to an address on that domain.

The same `emailTransport` pattern works for any HTTP-based transactional email
provider (SendGrid, Postmark, AWS SES, etc.) — the closure just needs to deliver
the email, and the host app owns the implementation.

### Customising the email subject and body

By default, `ForgotPasswordController` uses a built-in English template for the
password-reset email. To localise or brand the email, set the optional
`passwordResetEmailContent` closure on `AuthServerConfiguration` after creating it:

```swift
var authConfig = AuthServerConfiguration(
    jwtSigningSecret: jwtSecret,
    emailTransport: emailTransport
)

authConfig.passwordResetEmailContent = { token in
    (
        subject: "Reset your MyApp password",
        body: """
            Use the following token to reset your password in the app (valid for 1 hour):

            \(token)

            Open the app, go to Forgot Password, and enter this token.
            """
    )
}
```

When `passwordResetEmailContent` is `nil` (the default), the built-in English subject
`"Reset your password"` and a standard token-delivery body are used.

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

## Demo App

The `demo/` folder contains a full end-to-end example:

| Path | What it is |
|------|-----------|
| `demo/apple_app/` | iOS + macOS SwiftUI app (XcodeGen project, three iOS targets + one macOS target) |
| `demo/api/` | Vapor 4 backend wired to `AuthServer` with SQLite |

### Running the demo API

```sh
cd demo/api
swift run          # starts on http://0.0.0.0:8080
```

Delete `demo/api/db.sqlite` for a clean slate (Fluent recreates the schema on next start).

When testing on a real device, use your Mac's LAN IP (e.g. `http://192.168.x.x:8080`) instead of `localhost`.

### Opening the demo app in Xcode

Open `demo/apple_app/` as a Swift Package via **File → Open** (select the folder, not an `.xcodeproj`). The local Auth package dependency is resolved automatically.

To regenerate the `.xcodeproj` after editing `project.yml`:

```sh
cd demo/apple_app
xcodegen generate
```

---

### Configuring Sign in with Google

Sign in with Google requires two values from a Google OAuth 2.0 client:
the **client ID** and its **reversed form** (used as a URL scheme for the
OAuth redirect).

> **Are these values secret?** No. `CLIENT_ID` and `REVERSED_CLIENT_ID` are
> public identifiers — they end up in the app binary and in OAuth redirect
> URLs. Committing them to a private repo (or even a public one) is perfectly
> safe. Google does not treat them as credentials.

#### Step 1 — Create a Google OAuth client

1. Go to [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials).
2. Create a project (or select an existing one).
3. Click **Create Credentials → OAuth client ID**.
4. Choose **iOS** as the application type.
5. Enter your bundle identifier (e.g. `com.marekloose.DemoAuth`).
6. Click **Create** and then **Download plist** to get `GoogleService-Info.plist`.

#### Step 2 — Find your client ID values

Open the downloaded `GoogleService-Info.plist` and locate:

```xml
<key>CLIENT_ID</key>
<string>1234567890-xxxxxxxxxxxx.apps.googleusercontent.com</string>

<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.1234567890-xxxxxxxxxxxx</string>
```

#### Step 3 — Fill in `GoogleCredentials.xcconfig`

`demo/apple_app/GoogleCredentials.xcconfig` is committed with placeholder
values. Open it and replace the two placeholders with your real credentials:

```
GOOGLE_CLIENT_ID = 1234567890-xxxxxxxxxxxx.apps.googleusercontent.com
REVERSED_GOOGLE_CLIENT_ID = com.googleusercontent.apps.1234567890-xxxxxxxxxxxx
```

Then tell git to stop tracking local changes to this file so your real
credentials never appear in diffs or get accidentally committed:

```sh
git update-index --skip-worktree demo/apple_app/GoogleCredentials.xcconfig
```

That's it — rebuild. `Info.plist` already references `$(GOOGLE_CLIENT_ID)`
and `$(REVERSED_GOOGLE_CLIENT_ID)`, so Xcode injects the values at build
time. Running `xcodegen generate` is not required after editing the xcconfig.

> To undo `skip-worktree` (e.g. to commit a change to a placeholder or
> comment): `git update-index --no-skip-worktree demo/apple_app/GoogleCredentials.xcconfig`

#### Step 4 — Start the demo API

No additional configuration is needed for Google Sign-In on the server side.
The demo API fetches Google's public JWKS automatically at startup (from
`https://www.googleapis.com/oauth2/v3/certs`) and uses it to verify the
identity token signature. Just start the server as normal:

```sh
cd demo/api
swift run
```

---

### Sign in with Google in your own app

`CLIENT_ID` and `REVERSED_CLIENT_ID` are safe to commit. The recommended
patterns for host apps:

**Simple (most apps):** Put the values directly in your `Info.plist` or
in an `.xcconfig` that is checked in. No extra setup needed.

```xml
<key>GIDClientID</key>
<string>1234567890-xxxxxxxxxxxx.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.1234567890-xxxxxxxxxxxx</string>
        </array>
    </dict>
</array>
```

**Multiple environments (dev / staging / prod):** Keep one `.xcconfig` per
environment (each with its own OAuth client), select the right config via
your build scheme, and commit all of them. None are secret.

---

### Configuring Sign in with Apple

Sign in with Apple is pre-configured for real-device builds via
`DemoAuth/DemoAuth.entitlements` (which includes the
`com.apple.developer.applesignin` entitlement). No extra credential files
are needed — the system handles the OAuth flow using your Apple Developer
Team ID and the app's bundle identifier.

Requirements:
- The **Sign in with Apple** capability must be enabled for your App ID in
  [Apple Developer → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
- Your device must be registered under your development team.
- Build with a provisioned scheme (not the Simulator) for the Apple sign-in
  sheet to appear.

---

## Development

Refer to `CLAUDE.md` for agent workflow, coding conventions, and architecture decisions.

---

## License

Private — all rights reserved.
