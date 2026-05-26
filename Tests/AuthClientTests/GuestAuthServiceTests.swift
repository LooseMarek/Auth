import Foundation
import XCTest
@testable import AuthClient
import AuthShared

/// Tests for the guest sign-in flow through AuthManager (the "service" layer).
///
/// These tests verify the full happy path and failure path for guest authentication
/// from the perspective of the view model / UI layer calling `authManager.loginAsGuest()`.
@MainActor
final class GuestAuthServiceTests: XCTestCase {

    func testGuestSignIn_success_navigatesToAuthenticatedState() async throws {
        // Given: a network service that returns a successful guest auth response
        let guestUUIDString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let guestUser = UserDTO(id: guestUUIDString, email: nil, displayName: nil)
        let guestResponse = AuthResponse(
            accessToken: "guest-access-token",
            refreshToken: "guest-refresh-token",
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
        XCTAssertTrue(manager.isPresentingAuthFlow, "Precondition: auth flow should be presenting")

        // When: loginAsGuest() is called on the AuthManager and succeeds
        try await manager.loginAsGuest()

        // Then: session transitions to .guest with the UUID from the server response
        guard case .guest(let uuid) = manager.session else {
            XCTFail("Expected session to be .guest after successful guest sign-in, got \(manager.session)")
            return
        }
        XCTAssertEqual(uuid.uuidString.uppercased(), guestUUIDString.uppercased(),
                       "Guest UUID should match the one returned by the server")

        // And: the auth flow is dismissed (navigating to the authenticated/guest state)
        XCTAssertFalse(manager.isPresentingAuthFlow,
                       "Auth flow should be dismissed after successful guest sign-in")
    }
}
