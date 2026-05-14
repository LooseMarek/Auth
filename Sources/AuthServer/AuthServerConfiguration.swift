import Vapor
import JWTKit

/// Configuration for the AuthServer target.
///
/// Pass an instance to `JWTMiddleware` and any route controllers that need
/// access to JWT signing secrets or token TTLs.
public struct AuthServerConfiguration: Sendable {

    // MARK: - Storage key for Vapor's Application.storage

    public struct StorageKey: Vapor.StorageKey {
        public typealias Value = AuthServerConfiguration
    }

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

    // MARK: - Initialiser

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
