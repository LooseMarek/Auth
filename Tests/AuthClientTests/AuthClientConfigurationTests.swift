import XCTest
import SwiftUI
@testable import AuthClient

final class AuthClientConfigurationTests: XCTestCase {

    // MARK: - Helpers

    /// Returns RGBA components for a flat (non-adaptive) Color.
    private func rgba(of color: Color) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
#if canImport(UIKit)
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        NSColor(color).usingColorSpace(.deviceRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        return (r, g, b, a)
    }

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

    // MARK: - Dual light/dark token sets (Task #102)

    /// Verifies that when separate light and dark token sets are provided,
    /// `AuthTheme` selects the light-scheme tokens when the colour scheme is `.light`.
    func testLightTokens_appliedInLightMode() {
        let lightPrimary = Color(red: 1.0, green: 0.0, blue: 0.0)   // red
        let darkPrimary  = Color(red: 0.0, green: 0.0, blue: 1.0)   // blue
        let lightBackground = Color(red: 1.0, green: 1.0, blue: 0.8)
        let darkBackground  = Color(red: 0.1, green: 0.1, blue: 0.2)

        let config = AuthClientConfiguration(
            light: AuthColorTokens(primaryColor: lightPrimary, backgroundColor: lightBackground),
            dark:  AuthColorTokens(primaryColor: darkPrimary,  backgroundColor: darkBackground)
        )

        let theme = AuthTheme(configuration: config, colorScheme: .light)

        // Light primary should be resolved in light scheme — red (R≈1, G≈0, B≈0)
        let primaryRGBA = rgba(of: theme.primaryColor)
        XCTAssertEqual(primaryRGBA.r, 1.0, accuracy: 0.01, "Light primary R should be 1.0 (red)")
        XCTAssertEqual(primaryRGBA.g, 0.0, accuracy: 0.01, "Light primary G should be 0.0 (red)")
        XCTAssertEqual(primaryRGBA.b, 0.0, accuracy: 0.01, "Light primary B should be 0.0 (red)")

        // Light background should be applied
        let bgRGBA = rgba(of: theme.backgroundColor)
        XCTAssertEqual(bgRGBA.r, 1.0, accuracy: 0.01, "Light background R should be 1.0")
        XCTAssertEqual(bgRGBA.g, 1.0, accuracy: 0.01, "Light background G should be 1.0")
        XCTAssertEqual(bgRGBA.b, 0.8, accuracy: 0.01, "Light background B should be 0.8")
    }

    /// Verifies that when separate light and dark token sets are provided,
    /// `AuthTheme` selects the dark-scheme tokens when the colour scheme is `.dark`.
    func testDarkTokens_appliedInDarkMode() {
        let lightPrimary = Color(red: 1.0, green: 0.0, blue: 0.0)   // red
        let darkPrimary  = Color(red: 0.0, green: 0.0, blue: 1.0)   // blue
        let lightBackground = Color(red: 1.0, green: 1.0, blue: 0.8)
        let darkBackground  = Color(red: 0.1, green: 0.1, blue: 0.2)

        let config = AuthClientConfiguration(
            light: AuthColorTokens(primaryColor: lightPrimary, backgroundColor: lightBackground),
            dark:  AuthColorTokens(primaryColor: darkPrimary,  backgroundColor: darkBackground)
        )

        let theme = AuthTheme(configuration: config, colorScheme: .dark)

        // Dark primary should be resolved in dark scheme — blue (R≈0, G≈0, B≈1)
        let primaryRGBA = rgba(of: theme.primaryColor)
        XCTAssertEqual(primaryRGBA.r, 0.0, accuracy: 0.01, "Dark primary R should be 0.0 (blue)")
        XCTAssertEqual(primaryRGBA.g, 0.0, accuracy: 0.01, "Dark primary G should be 0.0 (blue)")
        XCTAssertEqual(primaryRGBA.b, 1.0, accuracy: 0.01, "Dark primary B should be 1.0 (blue)")

        // Dark background should be applied
        let bgRGBA = rgba(of: theme.backgroundColor)
        XCTAssertEqual(bgRGBA.r, 0.1, accuracy: 0.01, "Dark background R should be 0.1")
        XCTAssertEqual(bgRGBA.g, 0.1, accuracy: 0.01, "Dark background G should be 0.1")
        XCTAssertEqual(bgRGBA.b, 0.2, accuracy: 0.01, "Dark background B should be 0.2")
    }

    /// Verifies that the default `AuthClientConfiguration()` (no custom tokens) produces
    /// a valid, non-nil primary colour and background for both light and dark schemes.
    func testDefaultConfiguration_validForBothSchemes() {
        let config = AuthClientConfiguration()

        let lightTheme = AuthTheme(configuration: config, colorScheme: .light)
        let darkTheme  = AuthTheme(configuration: config, colorScheme: .dark)

        // Primary colour must not be transparent (alpha == 1)
        let lightPrimaryRGBA = rgba(of: lightTheme.primaryColor)
        XCTAssertEqual(lightPrimaryRGBA.a, 1.0, accuracy: 0.01, "Default light primary must be fully opaque")

        let darkPrimaryRGBA = rgba(of: darkTheme.primaryColor)
        XCTAssertEqual(darkPrimaryRGBA.a, 1.0, accuracy: 0.01, "Default dark primary must be fully opaque")

        // Background colour must not be fully transparent either
        let lightBgRGBA = rgba(of: lightTheme.backgroundColor)
        XCTAssertEqual(lightBgRGBA.a, 1.0, accuracy: 0.01, "Default light background must be fully opaque")

        let darkBgRGBA = rgba(of: darkTheme.backgroundColor)
        XCTAssertEqual(darkBgRGBA.a, 1.0, accuracy: 0.01, "Default dark background must be fully opaque")

        // The two default primaries must differ (light and dark Auth Blue are different hues)
        // Auth Blue light: #0A66FF ≈ R=0.039 ; dark: #3D8BFF ≈ R=0.239
        XCTAssertNotEqual(
            lightPrimaryRGBA.r, darkPrimaryRGBA.r,
            "Default light and dark primary colours must differ"
        )
    }
}
