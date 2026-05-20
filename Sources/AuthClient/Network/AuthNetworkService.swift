import Foundation
import AuthShared

public enum AuthNetworkError: Error, Sendable {
    case invalidCredentials
    case emailTaken
    case networkUnavailable
    case serverError
}

public protocol AuthNetworkService: Sendable {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String) async throws -> AuthResponse
    func forgotPassword(email: String) async throws

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
    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse

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
    func upgradeGuestWithGoogle(guestUUID: UUID, identityToken: String) async throws -> AuthResponse
}
