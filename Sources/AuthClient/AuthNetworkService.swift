import AuthShared

// MARK: - AuthNetworkError

/// Errors that can be thrown by AuthNetworkService implementations.
public enum AuthNetworkError: Error, Sendable {
    /// The provided credentials were rejected (HTTP 401).
    case invalidCredentials
    /// No network connection is available.
    case networkUnavailable
    /// An unexpected server error occurred (HTTP 5xx).
    case serverError
}

// MARK: - AuthNetworkService

/// A service that performs authentication-related network requests.
///
/// Implementations are injected into ViewModels rather than constructed directly,
/// enabling unit testing with mock implementations.
public protocol AuthNetworkService: Sendable {
    /// Authenticates a user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: An `AuthResponse` containing tokens and user information on success.
    /// - Throws: `AuthNetworkError` for known failure modes; any other error for unexpected failures.
    func login(email: String, password: String) async throws -> AuthResponse
}
