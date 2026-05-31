import Vapor
import JWTKit

/// Configuration for the AuthServer target.
///
/// Pass an instance to `JWTMiddleware` and any route controllers that need
/// access to JWT signing secrets or token TTLs.
public struct AuthServerConfiguration: Sendable {

    // MARK: - Storage key for Vapor's Application.storage

    /// Vapor `StorageKey` used to attach `AuthServerConfiguration` to `Application.storage`.
    ///
    /// Access the stored configuration via:
    /// ```swift
    /// app.storage[AuthServerConfiguration.StorageKey.self]
    /// ```
    public struct StorageKey: Vapor.StorageKey {
        public typealias Value = AuthServerConfiguration
    }

    // MARK: - Development default

    /// Insecure default signing secret used by the demo API when `JWT_SIGNING_SECRET`
    /// is not set in the environment.
    ///
    /// - Important: This value is intentionally hardcoded for development convenience.
    ///   **Never use it in production.** Set `JWT_SIGNING_SECRET` to a strong random
    ///   secret before deploying.
    public static let developmentDefaultJWTSigningSecret = "demo-secret-change-in-production"

    // MARK: - Properties

    /// The secret used to sign and verify HMAC-SHA256 JWTs.
    public let jwtSigningSecret: String

    /// Lifetime of an access token in seconds. Defaults to 3600 (1 hour).
    public let accessTokenTTL: TimeInterval

    /// Lifetime of a refresh token in seconds. Defaults to 86400 (1 day).
    public let refreshTokenTTL: TimeInterval

    /// Optional email transport closure injected by the host application.
    ///
    /// The closure is called by the `forgot-password` route to deliver reset emails.
    /// If `nil`, the route will fail at runtime with a 500 error (fail-fast).
    ///
    /// Type: `(@Sendable (recipient: String, subject: String, body: String) async throws -> Void)?`
    public let emailTransport: (@Sendable (String, String, String) async throws -> Void)?

    /// Optional JWKS used to verify Apple identity tokens.
    ///
    /// The host application is responsible for fetching Apple's public JWKS from
    /// `https://appleid.apple.com/auth/keys` and supplying it here.
    /// If `nil`, `POST /auth/apple` will fail at runtime with a 500 error (fail-fast).
    public let appleJWKS: JWKS?

    /// Optional JWKS used to verify Google identity tokens.
    ///
    /// The host application is responsible for fetching Google's public JWKS from
    /// `https://www.googleapis.com/oauth2/v3/certs` and supplying it here.
    /// If `nil`, `POST /auth/google` will fail at runtime with a 500 error (fail-fast).
    public let googleJWKS: JWKS?

    /// Optional closure that produces the subject and body for password-reset emails.
    ///
    /// Called by `ForgotPasswordController` with the one-time reset token. Return
    /// a `(subject:, body:)` tuple containing the full email subject and body text.
    ///
    /// When `nil` (the default), `ForgotPasswordController` falls back to a built-in
    /// English template. Set this closure to localise or brand the reset email for
    /// your application.
    ///
    /// Example:
    /// ```swift
    /// authConfig.passwordResetEmailContent = { token in
    ///     (
    ///         subject: "Reset your MyApp password",
    ///         body: "Use this token to reset your password: \(token). It expires in 1 hour."
    ///     )
    /// }
    /// ```
    public var passwordResetEmailContent: (@Sendable (String) -> (subject: String, body: String))?

    // MARK: - Initialiser

    /// Creates an `AuthServerConfiguration`.
    ///
    /// - Parameters:
    ///   - jwtSigningSecret: The secret used to sign and verify HMAC-SHA256 access tokens.
    ///     Keep this value in a secret store (e.g. environment variable) — never commit it.
    ///   - accessTokenTTL: Lifetime of an access token in seconds. Defaults to 3600 (1 hour).
    ///   - refreshTokenTTL: Lifetime of a refresh token in seconds. Defaults to 86400 (1 day).
    ///   - emailTransport: A closure the server calls to deliver password-reset emails.
    ///     Parameters are `(recipient, subject, body)`. Pass `nil` to defer configuration —
    ///     the forgot-password route will fail at runtime with HTTP 500 until this is set.
    ///   - appleJWKS: Apple's public JWKS for verifying Sign in with Apple tokens.
    ///     Fetch from `https://appleid.apple.com/auth/keys`. Pass `nil` to defer — the
    ///     Apple sign-in route will fail at runtime with HTTP 500 until this is set.
    ///   - googleJWKS: Google's public JWKS for verifying Google Sign-In tokens.
    ///     Fetch from `https://www.googleapis.com/oauth2/v3/certs`. Pass `nil` to defer.
    public init(
        jwtSigningSecret: String,
        accessTokenTTL: TimeInterval = 3600,
        refreshTokenTTL: TimeInterval = 86400,
        emailTransport: (@Sendable (String, String, String) async throws -> Void)? = nil,
        appleJWKS: JWKS? = nil,
        googleJWKS: JWKS? = nil
    ) {
        self.jwtSigningSecret = jwtSigningSecret
        self.accessTokenTTL = accessTokenTTL
        self.refreshTokenTTL = refreshTokenTTL
        self.emailTransport = emailTransport
        self.appleJWKS = appleJWKS
        self.googleJWKS = googleJWKS
    }
}
