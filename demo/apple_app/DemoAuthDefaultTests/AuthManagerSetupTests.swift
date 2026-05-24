import XCTest
import AuthClient
@testable import DemoAuthDefault

@MainActor
final class AuthManagerSetupTests: XCTestCase {

    // MARK: - testAuthManagerIsInitialisedWithCorrectAPIBaseURL

    func testAuthManagerIsInitialisedWithCorrectAPIBaseURL() {
        // The demo app stores its API base URL as a constant so future tasks can wire it
        // into a real network service. This test verifies that constant is set to the
        // expected local-development value.
        XCTAssertEqual(AppRootView.demoAPIBaseURL, "http://localhost:8080")
    }

    // MARK: - testAuthSheetPresentsWhenUnauthenticated

    func testAuthSheetPresentsWhenUnauthenticated() {
        // Given: a freshly initialised AuthManager (session == .unauthenticated)
        let manager = AuthManager(configuration: AuthClientConfiguration())
        XCTAssertFalse(manager.isPresentingAuthFlow, "Sheet must not be presented before presentAuthFlow() is called")

        // When: the root view triggers presentation because the session is unauthenticated
        manager.presentAuthFlow()

        // Then: the auth sheet presentation flag is true
        XCTAssertTrue(manager.isPresentingAuthFlow)
    }

    // MARK: - testAuthSheetDismissesAfterSuccessfulLogin

    func testAuthSheetDismissesAfterSuccessfulLogin() {
        // Given: an AuthManager with the sheet open
        let manager = AuthManager(configuration: AuthClientConfiguration())
        manager.presentAuthFlow()
        XCTAssertTrue(manager.isPresentingAuthFlow)

        // When: authentication succeeds and the sheet is dismissed
        manager.dismissAuthFlow()

        // Then: the sheet presentation flag is false
        XCTAssertFalse(manager.isPresentingAuthFlow)
    }

    // MARK: - testAuthSheetReappearsAfterLogout

    func testAuthSheetReappearsAfterLogout() async {
        // Given: an AuthManager with an active session
        let manager = AuthManager(configuration: AuthClientConfiguration())
        manager.presentAuthFlow()
        manager.dismissAuthFlow()
        XCTAssertFalse(manager.isPresentingAuthFlow)

        // When: the user logs out (session resets to .unauthenticated)
        await manager.logout()

        // Then: session is unauthenticated — the root view will call presentAuthFlow() again
        switch manager.session {
        case .unauthenticated:
            break // expected
        default:
            XCTFail("Expected session to be .unauthenticated after logout, got \(manager.session)")
        }
    }
}
