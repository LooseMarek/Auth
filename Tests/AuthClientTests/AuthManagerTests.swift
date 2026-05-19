import XCTest
import Foundation
@testable import AuthClient
import AuthShared

// MARK: - Helpers

private func makeUser() -> UserDTO {
    UserDTO(id: "user-1", email: "test@example.com", displayName: "Test")
}

private func makeAuthResponse(accessToken: String = "new-access", refreshToken: String = "refresh-token", expiresAt: Date = Date().addingTimeInterval(3600)) -> AuthResponse {
    AuthResponse(accessToken: accessToken, refreshToken: refreshToken, expiresAt: expiresAt, user: makeUser())
}

private func makeNearExpiryMetadata(refreshToken: String = "refresh-token") -> TokenMetadata {
    // Expires in 30 seconds — within the 60-second threshold
    TokenMetadata(accessToken: "old-access", refreshToken: refreshToken, expiresAt: Date().addingTimeInterval(30))
}

private func makeHealthyMetadata(refreshToken: String = "refresh-token") -> TokenMetadata {
    // Expires in 10 minutes — well outside the threshold
    TokenMetadata(accessToken: "valid-access", refreshToken: refreshToken, expiresAt: Date().addingTimeInterval(600))
}

// MARK: - Tests

@MainActor
final class AuthManagerTests: XCTestCase {

    // MARK: Existing tests

    func testInitialStateIsUnauthenticated() {
        let config = AuthClientConfiguration()
        let manager = AuthManager(configuration: config)
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected initial session to be .unauthenticated, got \(manager.session)")
            return
        }
    }

    func testConfigurationAllowGuestAccessDefaultTrue() {
        let config = AuthClientConfiguration()
        let manager = AuthManager(configuration: config)
        XCTAssertTrue(manager.configuration.allowGuestAccess)
    }

    // MARK: Silent token refresh

    func testNearExpiryTokenTriggersRefresh() async throws {
        // Given: a near-expiry token stored in the token store
        let store = InMemoryTokenStore()
        let nearExpiryMetadata = makeNearExpiryMetadata()
        try store.save(nearExpiryMetadata)

        let refreshResponse = makeAuthResponse(accessToken: "refreshed-access", refreshToken: "refresh-token")
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .success(refreshResponse)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: withFreshToken is called
        var receivedToken: String?
        _ = try await manager.withFreshToken { token in
            receivedToken = token
            return token
        }

        // Then: the network service was called to refresh the token
        XCTAssertEqual(networkService.refreshTokenCallCount, 1)
        XCTAssertEqual(networkService.lastRefreshTokenArg, "refresh-token")
        // And the fresh access token is provided to the body
        XCTAssertEqual(receivedToken, "refreshed-access")
    }

    func testExpiredRefreshTokenTransitionsToUnauthenticated() async throws {
        // Given: a near-expiry token seeded via signIn, and a network service that rejects refresh
        let nearExpiryDate = Date().addingTimeInterval(30)
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .failure(AuthNetworkError.invalidCredentials)

        let store = InMemoryTokenStore()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        // signIn with a near-expiry response so the store holds a near-expiry token
        manager.signIn(response: makeAuthResponse(accessToken: "near-expiry-access", expiresAt: nearExpiryDate))

        // When: withFreshToken is called and the refresh fails
        do {
            _ = try await manager.withFreshToken { token in token }
            XCTFail("Expected an error to be thrown")
        } catch {
            // Then: state transitions to .unauthenticated
            guard case .unauthenticated = manager.session else {
                XCTFail("Expected session to be .unauthenticated after failed refresh, got \(manager.session)")
                return
            }
        }
    }

    // MARK: Logout

    func testLogoutClearsKeychainAndCallsServer() async throws {
        // Given: a valid stored token with a known refresh token, seeded via signIn
        let store = InMemoryTokenStore()
        let networkService = MockAuthNetworkService()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        // signIn with a response that carries the specific refresh token we want to assert
        manager.signIn(response: makeAuthResponse(refreshToken: "my-refresh-token"))

        // When: logout() is called
        await manager.logout()

        // Then: the Keychain/store is cleared
        let storedToken = try store.load()
        XCTAssertNil(storedToken, "Token store should be empty after logout")

        // And: POST /auth/logout was called with the refresh token
        XCTAssertEqual(networkService.logoutCallCount, 1)
        XCTAssertEqual(networkService.lastLogoutRefreshTokenArg, "my-refresh-token")

        // And: session is .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to be .unauthenticated after logout, got \(manager.session)")
            return
        }
    }

    func testLogoutSucceedsLocallyEvenWhenServerFails() async throws {
        // Given: an authenticated session and a server that errors on logout
        let store = InMemoryTokenStore()
        let networkService = MockAuthNetworkService()
        networkService.logoutShouldThrow = AuthNetworkError.networkUnavailable

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        manager.signIn(response: makeAuthResponse())

        // When: logout() is called despite server failure
        await manager.logout()

        // Then: Keychain is still cleared
        XCTAssertNil(try store.load(), "Token store should be empty even when server logout fails")

        // And: session is .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to be .unauthenticated even after server failure")
            return
        }
    }

    // MARK: Account deletion

    func testDeleteAccountClearsStateAndKeychain() async throws {
        // Given: an authenticated session with a known access token
        let store = InMemoryTokenStore()
        let networkService = MockAuthNetworkService()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        // signIn seeds the store with the access token we want to assert is passed to deleteAccount
        manager.signIn(response: makeAuthResponse(accessToken: "access-for-deletion"))

        // When: deleteAccount() is called
        try await manager.deleteAccount()

        // Then: DELETE /auth/account was called with the access token
        XCTAssertEqual(networkService.deleteAccountCallCount, 1)
        XCTAssertEqual(networkService.lastDeleteAccountAccessTokenArg, "access-for-deletion")

        // And: Keychain is cleared
        XCTAssertNil(try store.load(), "Token store should be empty after account deletion")

        // And: state transitions to .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to be .unauthenticated after account deletion, got \(manager.session)")
            return
        }
    }
}
