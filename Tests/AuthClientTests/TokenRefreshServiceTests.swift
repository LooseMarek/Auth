import XCTest
import Foundation
@testable import AuthClient
import AuthShared

/// Tests for silent token refresh behaviour.
///
/// Verifies that when `withFreshToken` triggers a silent refresh, the new token
/// is correctly persisted to the token store — so subsequent calls use the
/// refreshed access token rather than the stale one.
@MainActor
final class TokenRefreshServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeUser() -> UserDTO {
        UserDTO(id: "user-refresh-1", email: "refresh@example.com", displayName: "Refresh User")
    }

    private func makeAuthResponse(
        accessToken: String = "refreshed-access",
        refreshToken: String = "refreshed-refresh",
        expiresAt: Date = Date().addingTimeInterval(3600)
    ) -> AuthResponse {
        AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: makeUser()
        )
    }

    // MARK: - testRefresh_success_updatesStoredToken

    /// Verifies that the new token is persisted to the store after a successful
    /// silent refresh. After `withFreshToken` completes, the store must hold the
    /// refreshed access token, not the original near-expiry one.
    func testRefresh_success_updatesStoredToken() async throws {
        // Given: a near-expiry token stored in the token store (expires in 30s,
        //        within the 60-second AuthManager.tokenRefreshThreshold)
        let store = InMemoryTokenStore()
        let nearExpiryMetadata = TokenMetadata(
            accessToken: "old-access",
            refreshToken: "old-refresh",
            expiresAt: Date().addingTimeInterval(30)
        )
        try store.save(nearExpiryMetadata)

        // And: a network service that returns a new token on refresh
        let networkService = MockAuthNetworkService()
        let refreshedResponse = makeAuthResponse(
            accessToken: "new-access-after-refresh",
            refreshToken: "new-refresh-after-refresh"
        )
        networkService.refreshTokenResult = .success(refreshedResponse)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: withFreshToken is called (triggers silent refresh due to near-expiry)
        var receivedToken: String?
        _ = try await manager.withFreshToken { token in
            receivedToken = token
            return token
        }

        // Then: the body received the new access token
        XCTAssertEqual(receivedToken, "new-access-after-refresh",
                       "withFreshToken should pass the refreshed access token to the body")

        // And: the token store now holds the new token (not the old one)
        let storedMetadata = try store.load()
        XCTAssertEqual(storedMetadata?.accessToken, "new-access-after-refresh",
                       "The token store must be updated with the new access token after refresh")
        XCTAssertEqual(storedMetadata?.refreshToken, "new-refresh-after-refresh",
                       "The token store must be updated with the new refresh token after refresh")

        // And: the network service was called once to refresh
        XCTAssertEqual(networkService.refreshTokenCallCount, 1,
                       "refreshToken should have been called exactly once")
        XCTAssertEqual(networkService.lastRefreshTokenArg, "old-refresh",
                       "The original refresh token should have been used to request the new one")
    }
}
