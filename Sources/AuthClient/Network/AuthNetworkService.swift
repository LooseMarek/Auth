import Foundation
import AuthShared

/// Errors that can be thrown by ``AuthNetworkService`` operations.
public enum AuthNetworkError: Error, LocalizedError, Sendable {
    /// The supplied credentials (email/password or identity token) were rejected by the server.
    case invalidCredentials
    /// Registration failed because the email address is already associated with an account.
    case emailTaken
    /// Upgrade failed because the email address or social account is already registered
    /// to an existing account. Account merging is not supported.
    case accountAlreadyExists
    /// The password-reset token is invalid, not found, or has expired.
    case invalidResetToken
    /// The device has no internet connection (e.g. airplane mode, `NSURLErrorNotConnectedToInternet`).
    case networkUnavailable
    /// The device has internet but the API server is unreachable — connection refused,
    /// timed out, or the network connection was lost mid-request.
    case serverUnreachable
    /// The server returned an unexpected error response.
    case serverError
    /// The requested operation is not supported for this account type.
    /// Returned as HTTP 422 when an email-only operation (e.g. change password) is attempted
    /// on an Apple, Google, or guest account.
    case unsupportedOperation

    /// A human-readable description suitable for display in the UI.
    ///
    /// Conforms to `LocalizedError` so that `error.localizedDescription` returns a
    /// user-facing string instead of the raw domain/code string produced by the
    /// default `Error` implementation (e.g. "AuthClient.AuthNetworkError error 3").
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return String(localized: "auth.login.error.invalid_credentials", bundle: .module)
        case .emailTaken:
            return String(localized: "auth.register.error.email_taken", bundle: .module)
        case .accountAlreadyExists:
            return String(localized: "auth.upgrade.error.account_already_exists", bundle: .module)
        case .invalidResetToken:
            return String(localized: "auth.error.invalid_reset_token", bundle: .module)
        case .networkUnavailable:
            return String(localized: "auth.error.network", bundle: .module)
        case .serverUnreachable:
            return String(localized: "auth.error.server_unreachable", bundle: .module)
        case .serverError:
            return String(localized: "auth.error.server", bundle: .module)
        case .unsupportedOperation:
            return String(localized: "auth.error.unsupported_operation", bundle: .module)
        }
    }
}

/// Defines the network contract between `AuthManager` and the host app's backend.
///
/// Implement this protocol in your host app (or use a pre-built implementation) and
/// pass it to `AuthManager.init(configuration:networkService:tokenStore:)`.
/// Each method maps to a specific Auth server endpoint.
///
/// The default dependency injected by `AuthManager.init(configuration:)` is a
/// no-op stub (`NoOpAuthNetworkService`) — you must replace it with a real
/// implementation before any network calls succeed.
public protocol AuthNetworkService: Sendable {
    /// Authenticates an existing user via POST /auth/login.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's plaintext password.
    /// - Returns: An ``AuthResponse`` with fresh tokens and user info.
    /// - Throws: ``AuthNetworkError/invalidCredentials`` when the credentials are wrong.
    func login(email: String, password: String) async throws -> AuthResponse

    /// Registers a new user account via POST /auth/register.
    ///
    /// - Parameters:
    ///   - email: The desired email address for the new account.
    ///   - password: The desired plaintext password (hashed server-side).
    /// - Returns: An ``AuthResponse`` with fresh tokens and user info.
    /// - Throws: ``AuthNetworkError/emailTaken`` when the email is already registered.
    func register(email: String, password: String) async throws -> AuthResponse

    /// Initiates a password reset for the given email via POST /auth/forgot-password.
    ///
    /// The server sends a reset email if the address is registered. Always returns
    /// without error regardless of whether the email exists (prevents user enumeration).
    ///
    /// - Parameter email: The email address for the account to reset.
    func forgotPassword(email: String) async throws

    /// Resets the user's password using a one-time reset token via POST /auth/reset-password.
    ///
    /// - Parameters:
    ///   - token: The one-time reset token delivered via email.
    ///   - newPassword: The new plaintext password to set (hashed server-side).
    /// - Throws: ``AuthNetworkError/invalidResetToken`` when the token is not found or has expired.
    func resetPassword(token: String, newPassword: String) async throws

    /// Exchanges a refresh token for a new ``AuthResponse`` containing fresh tokens.
    func refreshToken(refreshToken: String) async throws -> AuthResponse

    /// Invalidates the given refresh token server-side (POST /auth/logout).
    func logout(refreshToken: String) async throws

    /// Deletes the authenticated account server-side (DELETE /auth/account).
    func deleteAccount(accessToken: String) async throws

    /// Authenticates with an Apple identity token via POST /auth/apple.
    ///
    /// - Parameters:
    ///   - identityToken: The JWT identity token returned by `ASAuthorizationAppleIDCredential`.
    ///   - displayName: The user's display name (only provided by Apple on first sign-in).
    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse

    /// Upgrades a guest session to a fully-authenticated account via POST /auth/upgrade,
    /// attaching Apple credentials to the existing guest UUID.
    ///
    /// - Parameters:
    ///   - guestUUID: The UUID of the existing guest session.
    ///   - identityToken: The JWT identity token returned by `ASAuthorizationAppleIDCredential`.
    ///   - displayName: The user's display name (only provided by Apple on first sign-in).
    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse

    /// Authenticates with a Google identity token via POST /auth/google.
    ///
    /// - Parameter identityToken: The JWT identity token returned by the Google Sign-In SDK.
    func signInWithGoogle(identityToken: String) async throws -> AuthResponse

    /// Upgrades a guest session to a fully-authenticated account via POST /auth/upgrade,
    /// attaching Google credentials to the existing guest UUID.
    ///
    /// - Parameters:
    ///   - guestUUID: The UUID of the existing guest session.
    ///   - identityToken: The JWT identity token returned by the Google Sign-In SDK.
    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse

    /// Creates an anonymous guest session via POST /auth/guest.
    ///
    /// - Returns: An ``AuthResponse`` containing the guest JWT and a stable guest UUID in `user.id`.
    func loginAsGuest() async throws -> AuthResponse

    /// Upgrades a guest session to a fully-authenticated email/password account via POST /auth/upgrade.
    ///
    /// - Parameters:
    ///   - guestUUID: The UUID of the existing guest session to upgrade.
    ///   - email: The email address for the new account.
    ///   - password: The password for the new account.
    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse

    /// Changes the authenticated user's password via POST /auth/change-password.
    ///
    /// Only applicable to email-auth users. Apple, Google, and guest users do not have
    /// a stored password — the server returns HTTP 422 for those accounts (mapped to
    /// ``AuthNetworkError/serverError``).
    ///
    /// - Parameters:
    ///   - currentPassword: The user's current plaintext password (verified server-side).
    ///   - newPassword: The desired new plaintext password (hashed server-side).
    ///   - accessToken: A valid JWT access token for the authenticated user.
    /// - Throws: ``AuthNetworkError/invalidCredentials`` when `currentPassword` is wrong.
    /// - Throws: ``AuthNetworkError/unsupportedOperation`` when the account type does not support passwords (Apple, Google, or guest account).
    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws
}
