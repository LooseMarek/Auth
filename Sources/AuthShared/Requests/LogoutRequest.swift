/// A request to invalidate the current refresh token and end the authenticated session.
public struct LogoutRequest: Codable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
