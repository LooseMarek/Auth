import Foundation

/// Stateless utility that validates password requirements for the Auth flow.
enum PasswordValidator {

    /// The minimum number of characters a password must contain.
    static let minimumLength = 8

    /// Returns `true` when `password` meets the minimum length requirement.
    ///
    /// - Parameter password: The plaintext password string to validate.
    static func isValidLength(_ password: String) -> Bool {
        password.count >= minimumLength
    }
}
