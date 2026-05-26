import Foundation
import XCTest
@testable import AuthClient
import AuthShared

/// Tests that verify the localization bundle is threaded through view models correctly.
///
/// The tests use `LoginViewModel` as a representative — all three view models share the
/// same bundle-injection pattern.
@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - localizationBundle: nil → falls back to .module

    func testStringResolutionUsesModuleBundleWhenLocalizationBundleIsNil() async {
        let mock = AlwaysFailingNetworkService(error: AuthNetworkError.invalidCredentials)
        let viewModel = LoginViewModel(networkService: mock, localizationBundle: nil)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "wrong"
        await viewModel.login(authManager: authManager)

        // The error message should match the string from the module bundle.
        let expectedMessage = String(localized: "auth.login.error.invalid_credentials", bundle: .module)
        XCTAssertEqual(
            viewModel.errorMessage,
            expectedMessage,
            "When localizationBundle is nil, error strings should resolve from Bundle.module"
        )
    }

    // MARK: - localizationBundle: custom → uses provided bundle

    func testStringResolutionUsesCustomBundleWhenLocalizationBundleIsSet() async {
        let customBundle = Bundle.main
        let mock = AlwaysFailingNetworkService(error: AuthNetworkError.invalidCredentials)
        let viewModel = LoginViewModel(networkService: mock, localizationBundle: customBundle)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "wrong"
        await viewModel.login(authManager: authManager)

        // The error message should come from the custom bundle.
        // Bundle.main does NOT contain "auth.login.error.invalid_credentials", so the
        // String(localized:bundle:) API returns the key itself as a fallback when the
        // key is missing in the provided bundle.
        let expectedMessage = String(localized: "auth.login.error.invalid_credentials", bundle: customBundle)
        XCTAssertEqual(
            viewModel.errorMessage,
            expectedMessage,
            "When localizationBundle is set, error strings should resolve from the provided bundle"
        )

        // Additionally, verify this is DIFFERENT from the module bundle result,
        // confirming the custom bundle is actually being used.
        let moduleMessage = String(localized: "auth.login.error.invalid_credentials", bundle: .module)
        // Bundle.main won't have this key, so they differ — confirming the custom bundle is used.
        XCTAssertNotEqual(
            viewModel.errorMessage,
            moduleMessage,
            "Custom bundle result should differ from module bundle result since Bundle.main lacks auth keys"
        )
    }
}

// MARK: - Test doubles

private final class AlwaysFailingNetworkService: AuthNetworkService, @unchecked Sendable {
    let error: Error

    init(error: Error) {
        self.error = error
    }

    func login(email: String, password: String) async throws -> AuthResponse { throw error }
    func register(email: String, password: String) async throws -> AuthResponse { throw error }
    func forgotPassword(email: String) async throws { throw error }
    func refreshToken(refreshToken: String) async throws -> AuthResponse { throw error }
    func logout(refreshToken: String) async throws { throw error }
    func deleteAccount(accessToken: String) async throws { throw error }
    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse { throw error }
    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse { throw error }
    func signInWithGoogle(identityToken: String) async throws -> AuthResponse { throw error }
    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse { throw error }
    func loginAsGuest() async throws -> AuthResponse { throw error }
    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse { throw error }
}
