/// A request to exchange a refresh token for a new set of tokens.
public struct RefreshTokenRequest: Codable, Sendable {
    /// The opaque refresh token string issued by a previous authentication response.
    public let refreshToken: String

    /// Creates a refresh token request.
    ///
    /// - Parameter refreshToken: The refresh token previously issued by the server.
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
