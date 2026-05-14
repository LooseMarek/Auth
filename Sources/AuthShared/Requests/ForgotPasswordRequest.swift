/// A request to initiate a password reset for the given email address.
public struct ForgotPasswordRequest: Codable, Sendable {
    public let email: String

    public init(email: String) {
        self.email = email
    }
}
