import Foundation
import JWTKit

/// A value type that produces access tokens (JWT) and refresh tokens from
/// an `AuthServerConfiguration`. It has no database dependency and is fully testable
/// as a pure unit.
public struct TokenGenerator: Sendable {

    private let configuration: AuthServerConfiguration

    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Access Token

    /// Result of generating a signed JWT access token.
    public struct AccessTokenResult: Sendable {
        /// The signed JWT string.
        public let token: String
        /// The date at which the access token expires.
        public let expiresAt: Date
    }

    /// Signs a new JWT access token for the given user ID.
    /// - Parameter userID: The UUID of the authenticated user.
    /// - Returns: An `AccessTokenResult` containing the signed JWT and its expiry date.
    public func makeAccessToken(userID: UUID) async throws -> AccessTokenResult {
        let expiresAt = Date().addingTimeInterval(configuration.accessTokenTTL)
        let payload = AuthPayload(
            subject: SubjectClaim(value: userID.uuidString),
            expiration: ExpirationClaim(value: expiresAt)
        )

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: configuration.jwtSigningSecret), digestAlgorithm: .sha256)
        let token = try await keys.sign(payload)

        return AccessTokenResult(token: token, expiresAt: expiresAt)
    }

    // MARK: - Refresh Token

    /// Result of generating a refresh token (not yet persisted to the database).
    public struct RefreshTokenResult: Sendable {
        /// The opaque refresh token string (UUID-based, unique per call).
        public let token: String
        /// The user this refresh token belongs to.
        public let userID: UUID
        /// The date at which the refresh token expires.
        public let expiresAt: Date
    }

    /// Generates a new opaque refresh token for the given user ID.
    ///
    /// The caller is responsible for persisting the result as a `RefreshToken` model.
    /// - Parameter userID: The UUID of the authenticated user.
    /// - Returns: A `RefreshTokenResult` ready for persistence.
    public func makeRefreshToken(userID: UUID) -> RefreshTokenResult {
        RefreshTokenResult(
            token: UUID().uuidString,
            userID: userID,
            expiresAt: Date().addingTimeInterval(configuration.refreshTokenTTL)
        )
    }
}
