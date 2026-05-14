import XCTest
import SwiftUI
@testable import AuthClient

final class AuthClientConfigurationTests: XCTestCase {

    func testCustomPrimaryColor() {
        let customColor = Color.red
        let config = AuthClientConfiguration(primaryColor: customColor)
        XCTAssertEqual(config.primaryColor, customColor)
    }

    func testAllowGuestAccessFalseDisablesGuest() {
        let config = AuthClientConfiguration(allowGuestAccess: false)
        XCTAssertFalse(config.allowGuestAccess)
    }
}
