import Foundation
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {

    // MARK: - Back navigation

    func testBackToSignInTapped_navigatesToLogin() {
        var navigatedBack = false
        let mock = MockForgotPasswordNetworkService(result: .success(()))
        let viewModel = ForgotPasswordViewModel(
            networkService: mock,
            onBackToSignIn: { navigatedBack = true }
        )

        viewModel.backToSignIn()

        XCTAssertTrue(navigatedBack, "backToSignIn() should invoke the onBackToSignIn callback")
    }

    // MARK: - Error clearing on email input

    func testEmailFieldChanged_clearsError() {
        let mock = MockForgotPasswordNetworkService(result: .success(()))
        let viewModel = ForgotPasswordViewModel(
            networkService: mock,
            initialErrorMessage: "Something went wrong. Please try again."
        )

        XCTAssertNotNil(viewModel.errorMessage, "Precondition: errorMessage should be set before typing")

        viewModel.email = "new@example.com"

        XCTAssertNil(viewModel.errorMessage, "Typing in the email field should clear errorMessage")
    }

    // MARK: - Existing tests

    func testSuccessfulSubmitTransitionsToSuccessState() async {
        let mock = MockForgotPasswordNetworkService(result: .success(()))
        let viewModel = ForgotPasswordViewModel(networkService: mock)

        viewModel.email = "user@example.com"
        await viewModel.submit()

        XCTAssertTrue(viewModel.isSuccess, "isSuccess should be true after a successful submit")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on success")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testNetworkErrorSetsErrorMessage() async {
        let mock = MockForgotPasswordNetworkService(result: .failure(AuthNetworkError.networkUnavailable))
        let viewModel = ForgotPasswordViewModel(networkService: mock)

        viewModel.email = "user@example.com"
        await viewModel.submit()

        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set on network error")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }
}

// MARK: - Test doubles

private final class MockForgotPasswordNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<Void, Error>

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        switch result {
        case .success: return
        case .failure(let error): throw error
        }
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
