import XCTest
import Foundation
@testable import AuthClient
import AuthShared

final class AuthSessionStateTests: XCTestCase {

    // MARK: - isGuest

    func testIsGuest_returnsTrue_forGuestSession() {
        let uuid = UUID()
        let state = AuthSessionState.guest(uuid)
        XCTAssertTrue(state.isGuest, "isGuest should return true for .guest(_)")
    }

    func testIsGuest_returnsFalse_forUnauthenticatedSession() {
        let state = AuthSessionState.unauthenticated
        XCTAssertFalse(state.isGuest, "isGuest should return false for .unauthenticated")
    }

    func testIsGuest_returnsFalse_forAuthenticatedSession() {
        let user = UserDTO(id: "user-1", email: "user@example.com", displayName: "Test User")
        let state = AuthSessionState.authenticated(user)
        XCTAssertFalse(state.isGuest, "isGuest should return false for .authenticated(_)")
    }
}
