/// Errors thrown by AuthClient operations.
public enum AuthError: Error, Sendable {
    /// The email or password provided was incorrect.
    case invalidCredentials
    /// No network connection was available.
    case networkUnavailable
    /// The server returned an unexpected error.
    case serverError
    /// A social sign-in token was invalid or expired.
    case socialTokenInvalid
}
