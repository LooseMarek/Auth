import Foundation

/// The response returned by all authentication endpoints, containing tokens and user info.
public struct AuthResponse: Codable, Sendable {
    /// The JWT access token for authenticating subsequent requests.
    public let accessToken: String
    /// The refresh token used to obtain a new access token before expiry.
    public let refreshToken: String
    /// The date and time at which the access token expires.
    public let expiresAt: Date
    /// The authenticated user's information.
    public let user: UserDTO

    public init(accessToken: String, refreshToken: String, expiresAt: Date, user: UserDTO) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.user = user
    }
}
