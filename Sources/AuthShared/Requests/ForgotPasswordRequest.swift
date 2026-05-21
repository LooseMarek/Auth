/// A request to initiate a password reset for the given email address.
public struct ForgotPasswordRequest: Codable, Sendable {
    public let email: String

    /// Creates a forgot-password request for the given email address.
    ///
    /// - Parameter email: The email address of the account to reset.
    public init(email: String) {
        self.email = email
    }
}
