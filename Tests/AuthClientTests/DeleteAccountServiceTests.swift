import XCTest
import Foundation
@testable import AuthClient
import AuthShared

/// Tests the delete-account flow exposed by ``DeleteAccountViewModel``.
///
/// Covers:
/// - Successful deletion signs out the user and navigates to Login (session → .unauthenticated)
/// - On failure, `retryAction` re-issues DELETE /account — not GET /me or any other endpoint
@MainActor
final class DeleteAccountServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeAuthManager(
        networkService: any AuthNetworkService,
        accessToken: String = "test-access-token"
    ) -> AuthManager {
        let store = InMemoryTokenStore()
        let metadata = TokenMetadata(
            accessToken: accessToken,
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try? store.save(metadata)
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store,
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        )
        manager.signIn(response: AuthResponse(
            accessToken: accessToken,
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600),
            user: UserDTO(id: "user-1", email: "test@example.com", displayName: "Test")
        ))
        return manager
    }

    // MARK: - testDeleteAccountSuccess_signsOutUser

    /// AC: Given a logged-in user confirms deletion and the API returns success,
    /// then the user is signed out and the session transitions to `.unauthenticated`.
    func testDeleteAccountSuccess_signsOutUser() async throws {
        // Given: an authenticated AuthManager with a network service that succeeds on deleteAccount
        let networkService = MockAuthNetworkService()
        // deleteAccountShouldThrow defaults to nil → success
        let authManager = makeAuthManager(networkService: networkService)
        let viewModel = DeleteAccountViewModel()

        // Precondition: session is .authenticated
        guard case .authenticated = authManager.session else {
            XCTFail("Precondition failed: expected .authenticated session")
            return
        }

        // When: deleteAccount is called and succeeds
        await viewModel.deleteAccount(authManager: authManager)

        // Then: session transitions to .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated after successful deletion, got \(authManager.session)")
            return
        }

        // And: deleteAccount was called on the network service exactly once
        XCTAssertEqual(networkService.deleteAccountCallCount, 1)
        // And: no error message is set
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after successful deletion")
    }

    // MARK: - testDeleteAccountFailure_retryIssuesDeleteNotGetMe

    /// AC: Given the DELETE /account request fails, when the user taps "Retry",
    /// then the DELETE /account request is retried — not GET /me or any other endpoint.
    func testDeleteAccountFailure_retryIssuesDeleteNotGetMe() async throws {
        // Given: a network service that fails on the first call and succeeds on retry
        let networkService = MockAuthNetworkService()
        networkService.deleteAccountShouldThrow = AuthNetworkError.networkUnavailable
        let authManager = makeAuthManager(networkService: networkService)
        let viewModel = DeleteAccountViewModel()

        // When: deleteAccount is called and fails
        await viewModel.deleteAccount(authManager: authManager)

        // Then: an error message is set
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set when deleteAccount fails")

        // And: deleteAccount was called once so far (not any other endpoint)
        XCTAssertEqual(networkService.deleteAccountCallCount, 1, "DELETE should be called once on first attempt")
        XCTAssertEqual(networkService.loginCallCount, 0, "login (GET /me proxy) must NOT be called")

        // Now: allow the retry to succeed
        networkService.deleteAccountShouldThrow = nil

        // When: retry() is called
        await viewModel.retry(authManager: authManager)

        // Then: deleteAccount was called again (total = 2 — first attempt + retry)
        XCTAssertEqual(networkService.deleteAccountCallCount, 2, "retry() must re-issue DELETE, not any other endpoint")
        // And: no other endpoints were called
        XCTAssertEqual(networkService.loginCallCount, 0, "retry() must not call login")
        XCTAssertEqual(networkService.refreshTokenCallCount, 0, "retry() must not call refreshToken (no GET /me)")
        // And: error is cleared after successful retry
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil after successful retry")
    }

    // MARK: - testDeleteAccountFailure_setsHumanReadableErrorMessage

    /// AC: error message must not contain raw domain strings.
    func testDeleteAccountFailure_setsHumanReadableErrorMessage() async throws {
        // Given: a network service that returns serverError (case 3)
        let networkService = MockAuthNetworkService()
        networkService.deleteAccountShouldThrow = AuthNetworkError.serverError
        let authManager = makeAuthManager(networkService: networkService)
        let viewModel = DeleteAccountViewModel()

        // When
        await viewModel.deleteAccount(authManager: authManager)

        // Then: errorMessage does not expose the raw domain
        let message = try XCTUnwrap(viewModel.errorMessage, "errorMessage should be set on failure")
        XCTAssertFalse(
            message.contains("AuthClient.AuthNetworkError"),
            "errorMessage must not expose raw domain string. Got: \(message)"
        )
        XCTAssertFalse(
            message.contains("error 3"),
            "errorMessage must not expose raw error code. Got: \(message)"
        )
    }

    // MARK: - testDeleteAccountFailure_networkUnavailable_setsNetworkErrorMessage

    func testDeleteAccountFailure_networkUnavailable_setsNetworkErrorMessage() async throws {
        // Given
        let networkService = MockAuthNetworkService()
        networkService.deleteAccountShouldThrow = AuthNetworkError.networkUnavailable
        let authManager = makeAuthManager(networkService: networkService)
        let viewModel = DeleteAccountViewModel()

        // When
        await viewModel.deleteAccount(authManager: authManager)

        // Then: error message is set and human-readable
        let message = try XCTUnwrap(viewModel.errorMessage)
        XCTAssertFalse(message.isEmpty)
        XCTAssertFalse(message.contains("AuthClient.AuthNetworkError"))
    }
}
