/// A request to reset a user's password using a one-time reset token.
public struct ResetPasswordRequest: Codable, Sendable {
    public let token: String
    public let newPassword: String

    public init(token: String, newPassword: String) {
        self.token = token
        self.newPassword = newPassword
    }
}
