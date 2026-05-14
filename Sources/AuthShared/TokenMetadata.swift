import Foundation

/// Carries the full token lifecycle information for a user session.
public struct TokenMetadata: Codable, Sendable {
    /// The JWT access token for authenticating subsequent requests.
    public let accessToken: String
    /// The refresh token used to obtain a new access token before expiry.
    public let refreshToken: String
    /// The date and time at which the access token expires.
    public let expiresAt: Date

    /// Returns `true` if the access token has expired.
    public var isExpired: Bool {
        expiresAt < Date()
    }

    public init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}
