import Foundation
@testable import AuthClient
import AuthShared

/// A full-featured mock of ``AuthNetworkService`` that records every call and
/// returns configurable results. Used across ``AuthManagerTests``.
final class MockAuthNetworkService: AuthNetworkService, @unchecked Sendable {

    // MARK: - Call counts

    var loginCallCount = 0
    var registerCallCount = 0
    var forgotPasswordCallCount = 0
    var resetPasswordCallCount = 0
    var refreshTokenCallCount = 0
    var logoutCallCount = 0
    var deleteAccountCallCount = 0
    var signInWithAppleCallCount = 0
    var upgradeGuestWithAppleCallCount = 0
    var signInWithGoogleCallCount = 0
    var upgradeGuestWithGoogleCallCount = 0
    var loginAsGuestCallCount = 0
    var upgradeGuestWithEmailCallCount = 0
    var changePasswordCallCount = 0

    // MARK: - Recorded arguments

    var lastRefreshTokenArg: String?
    var lastLogoutRefreshTokenArg: String?
    var lastDeleteAccountAccessTokenArg: String?
    var lastSignInWithAppleToken: String?
    var lastUpgradeGuestWithAppleToken: String?
    var lastUpgradeGuestUUID: UUID?
    var lastSignInWithGoogleToken: String?
    var lastUpgradeGuestWithGoogleToken: String?
    var lastUpgradeGuestWithEmailUUID: UUID?
    var lastUpgradeGuestWithEmailEmail: String?
    var lastUpgradeGuestWithEmailPassword: String?

    // MARK: - Configurable responses / errors

    var loginResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var registerResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var refreshTokenResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var signInWithAppleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var upgradeGuestWithAppleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var signInWithGoogleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var upgradeGuestWithGoogleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var loginAsGuestResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var upgradeGuestWithEmailResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    var logoutShouldThrow: Error? = nil
    var deleteAccountShouldThrow: Error? = nil
    var changePasswordResult: Result<Void, Error> = .success(())

    // MARK: - AuthNetworkService

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        return try loginResult.get()
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        registerCallCount += 1
        return try registerResult.get()
    }

    func forgotPassword(email: String) async throws {
        forgotPasswordCallCount += 1
    }

    func resetPassword(token: String, newPassword: String) async throws {
        resetPasswordCallCount += 1
    }

    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        refreshTokenCallCount += 1
        lastRefreshTokenArg = refreshToken
        return try refreshTokenResult.get()
    }

    func logout(refreshToken: String) async throws {
        logoutCallCount += 1
        lastLogoutRefreshTokenArg = refreshToken
        if let error = logoutShouldThrow {
            throw error
        }
    }

    func deleteAccount(accessToken: String) async throws {
        deleteAccountCallCount += 1
        lastDeleteAccountAccessTokenArg = accessToken
        if let error = deleteAccountShouldThrow {
            throw error
        }
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        signInWithAppleCallCount += 1
        lastSignInWithAppleToken = identityToken
        return try signInWithAppleResult.get()
    }

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        upgradeGuestWithAppleCallCount += 1
        lastUpgradeGuestUUID = guestUUID
        lastUpgradeGuestWithAppleToken = identityToken
        return try upgradeGuestWithAppleResult.get()
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        signInWithGoogleCallCount += 1
        lastSignInWithGoogleToken = identityToken
        return try signInWithGoogleResult.get()
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        upgradeGuestWithGoogleCallCount += 1
        lastUpgradeGuestWithGoogleToken = identityToken
        return try upgradeGuestWithGoogleResult.get()
    }

    func loginAsGuest() async throws -> AuthResponse {
        loginAsGuestCallCount += 1
        return try loginAsGuestResult.get()
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        upgradeGuestWithEmailCallCount += 1
        lastUpgradeGuestWithEmailUUID = guestUUID
        lastUpgradeGuestWithEmailEmail = email
        lastUpgradeGuestWithEmailPassword = password
        return try upgradeGuestWithEmailResult.get()
    }

    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws {
        changePasswordCallCount += 1
        return try changePasswordResult.get()
    }
}
