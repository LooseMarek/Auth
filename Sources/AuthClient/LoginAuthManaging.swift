/// The interface `LoginViewModel` uses to authenticate a user.
/// `AuthManager` conforms to this protocol in production; test doubles use it in tests.
@MainActor
public protocol LoginAuthManaging: AnyObject {
    /// Authenticate with email and password. Throws `AuthError` on failure.
    func login(email: String, password: String) async throws
}
