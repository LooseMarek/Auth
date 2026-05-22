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

    // MARK: - Color tokens (Task #71)

    func testSurfaceColorDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.surfaceColor, "surfaceColor should default to nil when not supplied")
    }

    func testPrimaryTextColorDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.primaryTextColor, "primaryTextColor should default to nil when not supplied")
    }

    func testSecondaryTextColorDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.secondaryTextColor, "secondaryTextColor should default to nil when not supplied")
    }

    func testButtonTextColorDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.buttonTextColor, "buttonTextColor should default to nil when not supplied")
    }

    func testErrorColorDefaultsToNil() {
        let config = AuthClientConfiguration()
        XCTAssertNil(config.errorColor, "errorColor should default to nil when not supplied")
    }
}
