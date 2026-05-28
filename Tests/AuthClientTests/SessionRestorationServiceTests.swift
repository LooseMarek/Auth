import XCTest
import Foundation
@testable import AuthClient
import AuthShared

/// Tests for session restoration on app launch.
///
/// `AuthManager.restoreSession()` reads any persisted `TokenMetadata` from the
/// token store and attempts a token refresh to recover the full `AuthResponse`
/// (including `UserDTO`). On success, `session` transitions to `.authenticated`.
/// On failure (expired refresh token or no stored token), `session` remains
/// `.unauthenticated`.
@MainActor
final class SessionRestorationServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeUser(id: String = "user-restore-1") -> UserDTO {
        UserDTO(id: id, email: "restore@example.com", displayName: "Restore User")
    }

    private func makeAuthResponse(
        accessToken: String = "restored-access",
        refreshToken: String = "restored-refresh",
        expiresAt: Date = Date().addingTimeInterval(3600),
        user: UserDTO? = nil
    ) -> AuthResponse {
        AuthResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            user: user ?? makeUser()
        )
    }

    // MARK: - testAppLaunch_validTokenPresent_restoredToAuthenticatedState

    /// Verifies that when a valid (non-expiring) token is stored and the network
    /// returns a successful refresh response, `restoreSession()` transitions the
    /// session to `.authenticated`.
    func testAppLaunch_validTokenPresent_restoredToAuthenticatedState() async throws {
        // Given: a stored valid token (expires in 10 minutes — well outside threshold)
        let store = InMemoryTokenStore()
        let validMetadata = TokenMetadata(
            accessToken: "valid-access",
            refreshToken: "valid-refresh",
            expiresAt: Date().addingTimeInterval(600)
        )
        try store.save(validMetadata)

        // And: a network service that returns a successful refresh response
        let networkService = MockAuthNetworkService()
        let restoredUser = makeUser()
        networkService.refreshTokenResult = .success(makeAuthResponse(user: restoredUser))

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called (simulating app launch)
        await manager.restoreSession()

        // Then: session transitions to .authenticated with the user from the refresh response
        guard case .authenticated(let user) = manager.session else {
            XCTFail("Expected session to be .authenticated after restoreSession(), got \(manager.session)")
            return
        }
        XCTAssertEqual(user.id, restoredUser.id,
                       "Restored user ID should match the refresh response")
    }

    // MARK: - testAppLaunch_expiredAccessToken_validRefreshToken_silentlyRefreshes

    /// Verifies that when the stored access token is near expiry (or expired) but
    /// the refresh token is still valid, `restoreSession()` silently refreshes
    /// and transitions the session to `.authenticated`.
    func testAppLaunch_expiredAccessToken_validRefreshToken_silentlyRefreshes() async throws {
        // Given: a stored near-expiry token (expires in 30 seconds — within 60s threshold)
        let store = InMemoryTokenStore()
        let nearExpiryMetadata = TokenMetadata(
            accessToken: "near-expiry-access",
            refreshToken: "still-valid-refresh",
            expiresAt: Date().addingTimeInterval(30)
        )
        try store.save(nearExpiryMetadata)

        // And: a network service that returns a successful refresh response
        let networkService = MockAuthNetworkService()
        let restoredUser = makeUser(id: "user-refreshed")
        networkService.refreshTokenResult = .success(makeAuthResponse(
            accessToken: "new-access",
            refreshToken: "new-refresh",
            user: restoredUser
        ))

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called
        await manager.restoreSession()

        // Then: session transitions to .authenticated
        guard case .authenticated(let user) = manager.session else {
            XCTFail("Expected session to be .authenticated after silent refresh, got \(manager.session)")
            return
        }
        XCTAssertEqual(user.id, restoredUser.id,
                       "Session should be restored with user from refresh response")

        // And: the network service was called to refresh
        XCTAssertEqual(networkService.refreshTokenCallCount, 1,
                       "refreshToken should have been called once during restoration")
        XCTAssertEqual(networkService.lastRefreshTokenArg, "still-valid-refresh",
                       "The stored refresh token should have been used")
    }

    // MARK: - testAppLaunch_expiredRefreshToken_showsLogin

    /// Verifies that when the stored refresh token is expired or revoked (the
    /// network returns an error), `restoreSession()` leaves the session as
    /// `.unauthenticated`.
    func testAppLaunch_expiredRefreshToken_showsLogin() async throws {
        // Given: a stored token where the refresh token is also expired
        let store = InMemoryTokenStore()
        let expiredMetadata = TokenMetadata(
            accessToken: "expired-access",
            refreshToken: "expired-refresh",
            expiresAt: Date().addingTimeInterval(-3600) // already expired
        )
        try store.save(expiredMetadata)

        // And: a network service that rejects the refresh
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .failure(AuthNetworkError.invalidCredentials)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called
        await manager.restoreSession()

        // Then: session remains .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to remain .unauthenticated when refresh token is expired, got \(manager.session)")
            return
        }
    }

    // MARK: - testAppLaunch_noStoredToken_remainsUnauthenticated

    /// Verifies that when there is no stored token (fresh install or after logout),
    /// `restoreSession()` leaves the session as `.unauthenticated` without making
    /// any network calls.
    func testAppLaunch_noStoredToken_remainsUnauthenticated() async {
        // Given: an empty token store
        let store = InMemoryTokenStore()
        let networkService = MockAuthNetworkService()

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called
        await manager.restoreSession()

        // Then: session remains .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to remain .unauthenticated with no stored token, got \(manager.session)")
            return
        }

        // And: no network calls were made
        XCTAssertEqual(networkService.refreshTokenCallCount, 0,
                       "No network calls should be made when there is no stored token")
    }

    // MARK: - testAppLaunch_savedGuestToken_restoredToGuestState

    /// Verifies that when no main token is stored but a guest refresh token is
    /// persisted in the GuestTokenStore slot, `restoreSession()` silently refreshes
    /// and transitions the session to `.guest(uuid)`.
    func testAppLaunch_savedGuestToken_restoredToGuestState() async throws {
        // Given: a MockTokenStore with a saved guest refresh token (no main token)
        let store = MockTokenStore()
        store.savedGuestRefreshToken = "saved-guest-refresh"

        // And: a network service that returns a successful refresh response for the guest UUID
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let guestResponse = AuthResponse(
            accessToken: "guest-access-token",
            refreshToken: "guest-refresh-new",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .success(guestResponse)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called on app launch
        await manager.restoreSession()

        // Then: session transitions to .guest with the UUID from the server response
        guard case .guest(let uuid) = manager.session else {
            XCTFail("Expected session to be .guest after restoring guest session, got \(manager.session)")
            return
        }
        XCTAssertEqual(uuid.uuidString.uppercased(), guestUUIDString.uppercased(),
                       "Restored guest UUID should match the one returned by the refresh response")

        // And: the refresh was called with the saved guest token
        XCTAssertEqual(networkService.refreshTokenCallCount, 1,
                       "refreshToken should have been called once")
        XCTAssertEqual(networkService.lastRefreshTokenArg, "saved-guest-refresh",
                       "The saved guest refresh token should have been used")
    }

    // MARK: - testRestoreSession_guestUser_setsGuestSession

    /// Verifies that when the main token store holds a guest refresh token (the app
    /// was killed while a guest session was active), `restoreSession()` restores the
    /// session to `.guest(uuid)` — NOT `.authenticated` — because the server returns
    /// `isGuest: true` in the refresh response.
    func testRestoreSession_guestUser_setsGuestSession() async throws {
        // Given: a main token store seeded with the active guest refresh token
        let store = InMemoryTokenStore()
        let guestMetadata = TokenMetadata(
            accessToken: "guest-access",
            refreshToken: "guest-main-refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try store.save(guestMetadata)

        // And: the server returns a guest user in the refresh response
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil, isGuest: true)
        let guestResponse = AuthResponse(
            accessToken: "new-guest-access",
            refreshToken: "new-guest-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .success(guestResponse)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called (simulating an app relaunch mid-guest-session)
        await manager.restoreSession()

        // Then: session is .guest(uuid), NOT .authenticated
        guard case .guest(let uuid) = manager.session else {
            XCTFail("Expected session to be .guest after restoring a guest token, got \(manager.session)")
            return
        }
        XCTAssertEqual(uuid.uuidString.uppercased(), guestUUIDString.uppercased(),
                       "Restored guest UUID should match the one returned by the refresh response")

        // And: session.isGuest is true so a subsequent logout() will save the guest token
        XCTAssertTrue(manager.session.isGuest,
                      "session.isGuest must be true after restoring a guest session from the main token slot")
    }

    // MARK: - testAppLaunch_savedGuestToken_refreshFails_remainsUnauthenticated

    /// Verifies that when the saved guest refresh token is expired or revoked,
    /// `restoreSession()` clears the guest token slot and leaves the session as
    /// `.unauthenticated`.
    func testAppLaunch_savedGuestToken_refreshFails_remainsUnauthenticated() async {
        // Given: a MockTokenStore with a saved (expired) guest refresh token
        let store = MockTokenStore()
        store.savedGuestRefreshToken = "expired-guest-refresh"

        // And: a network service that rejects the refresh
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .failure(AuthNetworkError.invalidCredentials)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: restoreSession() is called
        await manager.restoreSession()

        // Then: session remains .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to be .unauthenticated when guest refresh fails, got \(manager.session)")
            return
        }

        // And: the stale guest token is cleared
        XCTAssertNil(store.savedGuestRefreshToken,
                     "Expired guest refresh token should be deleted after failed restoration")
    }
}
