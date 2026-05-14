import Foundation
import AuthShared

/// The network client protocol used by ViewModels to communicate with the auth server.
///
/// Conformers are responsible for making HTTP requests and decoding responses.
/// The production implementation is provided by the host app (or a future
/// `AuthNetworkClientLive` concrete type). A mock conformer is used in tests.
public protocol AuthNetworkClient: Sendable {

    /// Authenticates an existing user with email and password.
    ///
    /// - Parameter request: The login credentials.
    /// - Returns: An `AuthResponse` containing tokens and user information.
    /// - Throws: `AuthNetworkError` on failure.
    func login(request: LoginRequest) async throws -> AuthResponse
}

// MARK: - AuthNetworkError

/// Errors that can be thrown by an `AuthNetworkClient` implementation.
public enum AuthNetworkError: Error, Sendable {
    /// The credentials supplied were rejected by the server (HTTP 401).
    case invalidCredentials
    /// The device has no network connection.
    case networkUnavailable
    /// The server returned an unexpected error (HTTP 5xx or unrecognised response).
    case serverError
    /// A social sign-in token could not be validated.
    case socialTokenInvalid
    /// An unknown or unclassified error occurred.
    case unknown
}
