/// A request to invalidate the current refresh token and end the authenticated session.
public struct LogoutRequest: Codable, Sendable {
    public let refreshToken: String

    /// Creates a logout request with the refresh token to invalidate.
    ///
    /// - Parameter refreshToken: The opaque refresh token string currently stored
    ///   by the client. The server deletes this record to end the session.
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
