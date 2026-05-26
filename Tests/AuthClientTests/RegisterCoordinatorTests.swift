import Foundation
import XCTest
@testable import AuthClient
import AuthShared

/// Tests that verify the RegisterView's coordinator-level navigation wiring —
/// specifically that the "Log in" button routes the user back to LoginView.
///
/// The project uses SwiftUI NavigationStack rather than a dedicated Coordinator object.
/// Navigation back to LoginView is achieved by calling `dismiss()` (via
/// `@Environment(\.dismiss)`) when the RegisterViewModel fires its `onNavigateToLogin`
/// callback. These tests verify that wiring end-to-end at the ViewModel callback level.
@MainActor
final class RegisterCoordinatorTests: XCTestCase {

    // MARK: - testLogInAction_showsLoginView

    func testLogInAction_showsLoginView() {
        // Given: a RegisterViewModel configured with an onNavigateToLogin callback
        var loginNavigationTriggered = false
        let mock = CoordinatorMockNetworkService()
        let viewModel = RegisterViewModel(
            networkService: mock,
            onNavigateToLogin: { loginNavigationTriggered = true }
        )

        // When: the log-in action fires (simulates the button tap)
        viewModel.navigateToLogin()

        // Then: the navigation callback is invoked — the coordinator/view will call dismiss()
        XCTAssertTrue(
            loginNavigationTriggered,
            "The onNavigateToLogin callback must be invoked when navigateToLogin() is called, " +
            "which causes the view to call dismiss() and return to LoginView."
        )
    }

    func testLogInAction_doesNotTriggerWhenNotCalled() {
        // Given: a RegisterViewModel configured with an onNavigateToLogin callback
        var loginNavigationTriggered = false
        let mock = CoordinatorMockNetworkService()
        let viewModel = RegisterViewModel(
            networkService: mock,
            onNavigateToLogin: { loginNavigationTriggered = true }
        )

        // When: navigateToLogin() is NOT called (simulates no button tap yet)
        _ = viewModel // silence unused warning

        // Then: the callback has not been invoked
        XCTAssertFalse(
            loginNavigationTriggered,
            "onNavigateToLogin must not be called until navigateToLogin() is explicitly invoked."
        )
    }
}

// MARK: - Test doubles

private final class CoordinatorMockNetworkService: AuthNetworkService, @unchecked Sendable {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func logout(refreshToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func deleteAccount(accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}
