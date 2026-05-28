import XCTest
import AuthClient
@testable import DemoAuthDefault

final class DemoAuthDefaultAppTests: XCTestCase {
    func testDefaultTargetBuildsWithoutErrors() {
        // This test verifies the DemoAuthDefault target compiles successfully.
        // A successful build is sufficient — no runtime assertions needed.
        XCTAssertTrue(true)
    }

    // MARK: - testConfigurationHasNoOverrides

    func testConfigurationHasNoOverrides() {
        // Given: an AuthClientConfiguration created with no arguments (all defaults)
        let config = AuthClientConfiguration()

        // Then: all optional / token properties remain nil (no overrides applied)
        XCTAssertTrue(config.allowGuestAccess, "allowGuestAccess must default to true")
        XCTAssertNil(config.font, "font must be nil when no override is provided")
        XCTAssertNil(config.localizationBundle, "localizationBundle must be nil so Auth falls back to .module")
        XCTAssertNil(config.surfaceColor, "surfaceColor must be nil so AuthTheme uses its adaptive default")
        XCTAssertNil(config.primaryTextColor, "primaryTextColor must be nil so AuthTheme uses Color.primary")
        XCTAssertNil(config.secondaryTextColor, "secondaryTextColor must be nil so AuthTheme uses Color.secondary")
        XCTAssertNil(config.buttonTextColor, "buttonTextColor must be nil so AuthTheme uses .white")
        XCTAssertNil(config.errorColor, "errorColor must be nil so AuthTheme uses Color.red")
    }
}
