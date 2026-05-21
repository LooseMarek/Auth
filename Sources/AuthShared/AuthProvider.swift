/// Identifies the authentication provider used to create or upgrade an account.
public enum AuthProvider: String, Codable, Sendable {
    /// Standard email-and-password authentication.
    case email
    /// Sign in with Apple — uses an Apple identity token issued by `ASAuthorizationController`.
    case apple
    /// Sign in with Google — uses a Google ID token issued by the Google Sign-In SDK.
    case google
}
