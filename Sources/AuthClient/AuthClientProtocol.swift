import Foundation

/// Protocol defining the authentication client used by the UI.
/// Conform to provide an implementation that performs network requests.
public protocol AuthClientProtocol: Sendable {
    /// Attempt to log in with the given email and password.
    /// - Throws an error if the credentials are invalid or the request fails.
    func login(email: String, password: String) async throws
}
