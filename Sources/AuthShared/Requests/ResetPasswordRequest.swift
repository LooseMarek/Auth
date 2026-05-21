/// A request to reset a user's password using a one-time reset token.
public struct ResetPasswordRequest: Codable, Sendable {
    public let token: String
    public let newPassword: String

    /// Creates a reset-password request.
    ///
    /// - Parameters:
    ///   - token: The one-time reset token delivered to the user's email address.
    ///   - newPassword: The plaintext password to set. The server hashes this before storage.
    public init(token: String, newPassword: String) {
        self.token = token
        self.newPassword = newPassword
    }
}
