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

    // MARK: Guest session

    func testGuestSessionSetsGuestState() async throws {
        // Given: a network service that returns a successful AuthResponse for loginAsGuest
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let guestResponse = AuthResponse(
            accessToken: "guest-access",
            refreshToken: "guest-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.loginAsGuestResult = .success(guestResponse)

        let store = InMemoryTokenStore()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: loginAsGuest() is called
        try await manager.loginAsGuest()

        // Then: session transitions to .guest with the UUID from the response
        guard case .guest(let uuid) = manager.session else {
            XCTFail("Expected session to be .guest, got \(manager.session)")
            return
        }
        XCTAssertEqual(uuid.uuidString.uppercased(), guestUUIDString.uppercased())

        // And: tokens are stored
        let stored = try store.load()
        XCTAssertEqual(stored?.accessToken, "guest-access")
    }

    func testGuestUpgradePreservesUUID() async throws {
        // Given: a guest session with a known UUID
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUUID = UUID(uuidString: guestUUIDString)!
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let upgradeUser = UserDTO(id: guestUUIDString, email: "test@example.com", displayName: "Test")
        let upgradeResponse = AuthResponse(
            accessToken: "upgraded-access",
            refreshToken: "upgraded-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: upgradeUser
        )
        let networkService = MockAuthNetworkService()
        networkService.upgradeGuestWithEmailResult = .success(upgradeResponse)

        let store = InMemoryTokenStore()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        // Seed the guest session directly
        let guestTokenMetadata = TokenMetadata(
            accessToken: "guest-access",
            refreshToken: "guest-refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try store.save(guestTokenMetadata)
        manager.setGuestSession(uuid: guestUUID)

        // When: upgradeGuestWithEmail is called (simulating login while in guest state)
        let viewModel = LoginViewModel(networkService: networkService)
        viewModel.email = "test@example.com"
        viewModel.password = "secret123"
        await viewModel.login(authManager: manager)

        // Then: session transitions to .authenticated
        guard case .authenticated(let user) = manager.session else {
            XCTFail("Expected session to be .authenticated, got \(manager.session)")
            return
        }
        // And: the user ID (UUID) is preserved from the guest session
        XCTAssertEqual(user.id.uppercased(), guestUUIDString.uppercased())
        // And: upgradeGuestWithEmail was called (not plain login)
        XCTAssertEqual(networkService.upgradeGuestWithEmailCallCount, 1)
        XCTAssertEqual(networkService.loginCallCount, 0)
        XCTAssertEqual(networkService.lastUpgradeGuestWithEmailUUID, guestUUID)
    }

    func testAllowGuestAccessFalseHidesGuestButton() {
        // Given: configuration with allowGuestAccess = false
        let config = AuthClientConfiguration(allowGuestAccess: false)
        let manager = AuthManager(configuration: config)

        // When: allowGuestAccess is read
        // Then: it is false
        XCTAssertFalse(manager.configuration.allowGuestAccess)
    }

    // MARK: Auth flow presentation

    func testPresentAuthFlowSetsPresentingTrue() {
        // Given: a freshly initialised AuthManager
        let manager = AuthManager(configuration: AuthClientConfiguration())
        XCTAssertFalse(manager.isPresentingAuthFlow, "isPresentingAuthFlow should start false")

        // When: presentAuthFlow() is called
        manager.presentAuthFlow()

        // Then: isPresentingAuthFlow is true
        XCTAssertTrue(manager.isPresentingAuthFlow, "isPresentingAuthFlow should be true after presentAuthFlow()")
    }

    func testDismissAuthFlowSetsPresentingFalse() {
        // Given: an AuthManager with an active auth flow
        let manager = AuthManager(configuration: AuthClientConfiguration())
        manager.presentAuthFlow()
        XCTAssertTrue(manager.isPresentingAuthFlow, "Precondition: isPresentingAuthFlow should be true")

        // When: dismissAuthFlow() is called
        manager.dismissAuthFlow()

        // Then: isPresentingAuthFlow is false
        XCTAssertFalse(manager.isPresentingAuthFlow, "isPresentingAuthFlow should be false after dismissAuthFlow()")
    }

    func testSignInDismissesAuthFlow() {
        // Given: isPresentingAuthFlow is true (sheet is open)
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: MockAuthNetworkService(),
            tokenStore: InMemoryTokenStore()
        )
        manager.presentAuthFlow()
        XCTAssertTrue(manager.isPresentingAuthFlow, "Precondition: isPresentingAuthFlow should be true")

        // When: signIn(response:) is called with a valid response
        manager.signIn(response: makeAuthResponse())

        // Then: isPresentingAuthFlow is false
        XCTAssertFalse(manager.isPresentingAuthFlow, "isPresentingAuthFlow should be false after successful signIn")
    }

    func testLoginAsGuestDismissesAuthFlow() async throws {
        // Given: isPresentingAuthFlow is true (sheet is open)
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let guestResponse = AuthResponse(
            accessToken: "guest-access",
            refreshToken: "guest-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.loginAsGuestResult = .success(guestResponse)

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        manager.presentAuthFlow()
        XCTAssertTrue(manager.isPresentingAuthFlow, "Precondition: isPresentingAuthFlow should be true")

        // When: loginAsGuest() is called and the mock network service returns success
        try await manager.loginAsGuest()

        // Then: isPresentingAuthFlow is false
        XCTAssertFalse(manager.isPresentingAuthFlow, "isPresentingAuthFlow should be false after successful loginAsGuest")
    }

    // MARK: Guest session persistence

    func testGuestLogout_savesGuestRefreshToken() async throws {
        // Given: an active guest session with a known refresh token
        let guestUUID = UUID()
        let networkService = MockAuthNetworkService()
        let store = MockTokenStore()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        // Seed the store with a guest refresh token and set session to .guest
        let metadata = TokenMetadata(
            accessToken: "guest-access",
            refreshToken: "guest-refresh-to-save",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try store.save(metadata)
        manager.setGuestSession(uuid: guestUUID)

        // When: logout() is called
        await manager.logout()

        // Then: the guest refresh token was saved to the guest slot before clearing the main store
        XCTAssertEqual(store.savedGuestRefreshToken, "guest-refresh-to-save",
                       "Guest refresh token should be persisted to the guest slot on guest logout")

        // And: the main token store is cleared
        XCTAssertNil(try store.load(), "Main token store should be empty after logout")

        // And: session is .unauthenticated
        guard case .unauthenticated = manager.session else {
            XCTFail("Expected session to be .unauthenticated after guest logout, got \(manager.session)")
            return
        }
    }

    func testGuestSignIn_resumesExistingSession_whenGuestTokenExists() async throws {
        // Given: a saved guest refresh token in the guest slot
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let refreshedResponse = AuthResponse(
            accessToken: "refreshed-guest-access",
            refreshToken: "refreshed-guest-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .success(refreshedResponse)

        let store = MockTokenStore()
        store.savedGuestRefreshToken = "stale-guest-refresh"

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: loginAsGuest() is called
        try await manager.loginAsGuest()

        // Then: refreshToken was called instead of loginAsGuest
        XCTAssertEqual(networkService.refreshTokenCallCount, 1,
                       "Should call refreshToken to resume the existing guest session")
        XCTAssertEqual(networkService.loginAsGuestCallCount, 0,
                       "Should NOT call loginAsGuest when a saved guest token exists")
        XCTAssertEqual(networkService.lastRefreshTokenArg, "stale-guest-refresh")

        // And: session transitions to .guest with the UUID from the refreshed response
        guard case .guest(let uuid) = manager.session else {
            XCTFail("Expected session to be .guest after resuming, got \(manager.session)")
            return
        }
        XCTAssertEqual(uuid.uuidString.uppercased(), guestUUIDString.uppercased())
    }

    func testGuestSignIn_createsNewSession_whenGuestTokenExpired() async throws {
        // Given: a saved guest refresh token that is expired (refresh call fails)
        let guestUUIDString = "B2C3D4E5-F6A7-8901-BCDE-F12345678901"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let newGuestResponse = AuthResponse(
            accessToken: "new-guest-access",
            refreshToken: "new-guest-refresh",
            expiresAt: Date().addingTimeInterval(3600),
            user: guestUser
        )
        let networkService = MockAuthNetworkService()
        networkService.refreshTokenResult = .failure(AuthNetworkError.invalidCredentials)
        networkService.loginAsGuestResult = .success(newGuestResponse)

        let store = MockTokenStore()
        store.savedGuestRefreshToken = "expired-guest-refresh"

        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )

        // When: loginAsGuest() is called and the refresh fails
        try await manager.loginAsGuest()

        // Then: the stale guest token was cleared
        XCTAssertNil(store.savedGuestRefreshToken,
                     "Stale guest refresh token should be cleared when refresh fails")

        // And: a new guest session was created
        XCTAssertEqual(networkService.loginAsGuestCallCount, 1,
                       "Should fall back to creating a new guest account when token is expired")
        XCTAssertEqual(networkService.refreshTokenCallCount, 1,
                       "Should have attempted the refresh before falling back")

        // And: session transitions to .guest
        guard case .guest = manager.session else {
            XCTFail("Expected session to be .guest after new guest creation, got \(manager.session)")
            return
        }
    }

    func testDeleteAccount_clearsGuestRefreshToken() async throws {
        // Given: an authenticated session with a saved guest refresh token
        let store = MockTokenStore()
        store.savedGuestRefreshToken = "some-guest-refresh-token"
        let networkService = MockAuthNetworkService()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        manager.signIn(response: makeAuthResponse(accessToken: "access-for-deletion"))

        // When: deleteAccount() is called and succeeds
        try await manager.deleteAccount()

        // Then: the guest refresh token slot is also cleared
        XCTAssertNil(store.savedGuestRefreshToken,
                     "Guest refresh token should be cleared when account is deleted")
    }

    func testAuthenticatedLogout_doesNotTouchGuestRefreshToken() async throws {
        // Given: an authenticated (non-guest) session with a saved guest refresh token
        let store = MockTokenStore()
        store.savedGuestRefreshToken = "preserved-guest-refresh"
        let networkService = MockAuthNetworkService()
        let manager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: store
        )
        manager.signIn(response: makeAuthResponse())

        // When: an authenticated user logs out
        await manager.logout()

        // Then: the guest refresh token slot is preserved
        XCTAssertEqual(store.savedGuestRefreshToken, "preserved-guest-refresh",
                       "Authenticated logout must NOT clear the guest refresh token slot")
    }
}
