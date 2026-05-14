import XCTest
@testable import AuthClient

@MainActor
final class AuthManagerTests: XCTestCase {

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
}
