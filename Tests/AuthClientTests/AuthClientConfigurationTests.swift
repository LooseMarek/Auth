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

    // MARK: - localizationBundle

    func testLocalizationBundleDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.localizationBundle, "localizationBundle should default to nil when not supplied")
    }

    func testLocalizationBundleIsStoredWhenSupplied() {
        let customBundle = Bundle.main
        let config = AuthClientConfiguration(localizationBundle: customBundle)
        XCTAssertTrue(config.localizationBundle === customBundle, "localizationBundle should store the supplied bundle")
    }
}
