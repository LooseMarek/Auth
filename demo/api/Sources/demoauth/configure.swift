import Fluent
import FluentSQLiteDriver
import Foundation
import JWTKit
import AuthServer
import Vapor

/// Configures the Vapor application with SQLite persistence and AuthServer integration.
///
/// - Parameters:
///   - app: The Vapor application to configure.
///   - database: The database configuration factory. Defaults to a file-backed SQLite
///     database (`db.sqlite`). Pass `.sqlite(.memory)` in tests for full isolation.
public func configure(
    _ app: Application,
    database: DatabaseConfigurationFactory = .sqlite(.file("db.sqlite"))
) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.databases.use(database, as: .sqlite)

    // MARK: Development default — set JWT_SIGNING_SECRET in production
    // The demo API uses a hardcoded insecure secret when JWT_SIGNING_SECRET is absent.
    // This is intentional: the demo is not a production deployment. For a real server,
    // export a strong random value, e.g.:
    //   export JWT_SIGNING_SECRET=$(openssl rand -hex 32)
    let jwtSecret = Environment.get("JWT_SIGNING_SECRET")
        ?? AuthServerConfiguration.developmentDefaultJWTSigningSecret
    let appleJWKSData = try await URLSession.shared.data(
        from: URL(string: "https://appleid.apple.com/auth/keys")!
    ).0
    let appleJWKS = try JSONDecoder().decode(JWKS.self, from: appleJWKSData)

    let googleJWKSData = try await URLSession.shared.data(
        from: URL(string: "https://www.googleapis.com/oauth2/v3/certs")!
    ).0
    let googleJWKS = try JSONDecoder().decode(JWKS.self, from: googleJWKSData)

    // MARK: Email transport selection
    // If RESEND_API_KEY is set, use the Resend HTTP API to send real emails.
    // Otherwise, fall back to the development console transport (prints to stdout).
    //
    // Resend free tier: with `onboarding@resend.dev` as sender, Resend only delivers
    // to the email registered with the Resend account — sufficient for local demos.
    // To send to any address, verify a domain and set RESEND_FROM_EMAIL accordingly.
    // See the "Configuring Email Transport" section in README.md for full setup steps.
    let emailTransport: @Sendable (String, String, String) async throws -> Void

    // Capture app.logger here — the closure has no access to a Request or Application
    // at call time. Logging is applied in both transports so the developer always sees
    // what was sent in the server terminal, regardless of which transport is active.
    let logger = app.logger

    // Use getenv() (POSIX, reads the live process environment) instead of
    // ProcessInfo.processInfo.environment (a cached snapshot frozen at process start).
    // This ensures that test code calling setenv/unsetenv before configure() runs is
    // respected — ProcessInfo.environment does NOT reflect post-launch setenv calls.
    let resendAPIKeyRaw = getenv("RESEND_API_KEY").map { String(cString: $0) }
    if let resendAPIKey = resendAPIKeyRaw, !resendAPIKey.isEmpty {
        let fromEmail = getenv("RESEND_FROM_EMAIL").map { String(cString: $0) } ?? "onboarding@resend.dev"
        let resendTransport = makeResendEmailTransport(apiKey: resendAPIKey, fromEmail: fromEmail)
        emailTransport = { recipient, subject, body in
            logger.notice("[EMAIL] To: \(recipient) | Subject: \(subject) | Body: \(body)")
            try await resendTransport(recipient, subject, body)
        }
    } else {
        emailTransport = { recipient, subject, body in
            logger.notice("[EMAIL] To: \(recipient) | Subject: \(subject) | Body: \(body)")
        }
    }

    let authConfig = AuthServerConfiguration(
        jwtSigningSecret: jwtSecret,
        emailTransport: emailTransport,
        appleJWKS: appleJWKS,
        googleJWKS: googleJWKS
    )

    // MARK: Password-reset email content (optional)
    // By default, ForgotPasswordController uses a built-in English template.
    // Uncomment and adapt the closure below to localise or brand the reset email
    // for your application.
    //
    // authConfig.passwordResetEmailContent = { token in
    //     (
    //         subject: "Reset your MyApp password",
    //         body: "Hi, use this token to reset your password: \(token). It expires in 1 hour."
    //     )
    // }

    app.storage[AuthServerConfiguration.StorageKey.self] = authConfig

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePasswordResetToken())

    try await app.autoMigrate()

    try routes(app)
}
