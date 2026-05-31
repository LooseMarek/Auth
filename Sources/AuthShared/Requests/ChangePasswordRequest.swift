/// A request to change the authenticated user's password.
///
/// Only applicable to email-auth users. Apple, Google, and guest users do not
/// have a stored password hash — the server returns HTTP 422 for those accounts.
public struct ChangePasswordRequest: Codable, Sendable {
    /// The user's current (old) plaintext password.
    public let currentPassword: String
    /// The desired new plaintext password. The server hashes this before storage.
    public let newPassword: String

    /// Creates a change-password request.
    ///
    /// - Parameters:
    ///   - currentPassword: The user's current plaintext password (verified server-side).
    ///   - newPassword: The desired new plaintext password (hashed server-side).
    public init(currentPassword: String, newPassword: String) {
        self.currentPassword = currentPassword
        self.newPassword = newPassword
    }
}
