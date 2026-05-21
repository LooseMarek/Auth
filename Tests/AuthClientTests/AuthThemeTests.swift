import XCTest
import SwiftUI
@testable import AuthClient

// swiftlint:disable file_length
final class AuthThemeTests: XCTestCase {

    // MARK: - Helpers

    /// Returns the HSBA components of a Color resolved on macOS via NSColor,
    /// or on iOS via UIColor. Returns (hue, saturation, brightness, alpha).
    private func hsba(of color: Color) -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
#if canImport(UIKit)
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
#else
        NSColor(color).usingColorSpace(.deviceRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
#endif
        return (h, s, b, a)
    }

    /// Returns the RGBA components of a Color.
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

    // MARK: - testDefaultPrimaryColor

    /// Default AuthTheme uses Auth Blue (#0A66FF light / #3D8BFF dark).
    func testDefaultPrimaryColor() {
        let lightTheme = AuthTheme(configuration: AuthClientConfiguration(), colorScheme: .light)
        let darkTheme = AuthTheme(configuration: AuthClientConfiguration(), colorScheme: .dark)

        // Auth Blue light: #0A66FF → R=0.039, G=0.400, B=1.0
        let lightRGBA = rgba(of: lightTheme.primaryColor)
        XCTAssertEqual(lightRGBA.r, 0.039, accuracy: 0.01, "Light primary R should be ~0.039 (#0A66FF)")
        XCTAssertEqual(lightRGBA.g, 0.400, accuracy: 0.01, "Light primary G should be ~0.400 (#0A66FF)")
        XCTAssertEqual(lightRGBA.b, 1.000, accuracy: 0.01, "Light primary B should be ~1.0 (#0A66FF)")
        XCTAssertEqual(lightRGBA.a, 1.000, accuracy: 0.001)

        // Auth Blue dark: #3D8BFF → R=0.239, G=0.545, B=1.0
        let darkRGBA = rgba(of: darkTheme.primaryColor)
        XCTAssertEqual(darkRGBA.r, 0.239, accuracy: 0.01, "Dark primary R should be ~0.239 (#3D8BFF)")
        XCTAssertEqual(darkRGBA.g, 0.545, accuracy: 0.01, "Dark primary G should be ~0.545 (#3D8BFF)")
        XCTAssertEqual(darkRGBA.b, 1.000, accuracy: 0.01, "Dark primary B should be ~1.0 (#3D8BFF)")
        XCTAssertEqual(darkRGBA.a, 1.000, accuracy: 0.001)
    }

    // MARK: - testHoverDerivationLightMode

    /// Hover color is ΔL −10% from primaryColor in light mode (HSB brightness adjusted).
    func testHoverDerivationLightMode() {
        let knownColor = Color(red: 0.039, green: 0.400, blue: 1.0)
        let config = AuthClientConfiguration(primaryColor: knownColor)
        let theme = AuthTheme(configuration: config, colorScheme: .light)

        let primaryHSBA = hsba(of: theme.primaryColor)
        let hoverHSBA = hsba(of: theme.primaryHover)

        // Hover in light mode: brightness decreases by 0.10 (ΔL −10%)
        XCTAssertEqual(hoverHSBA.h, primaryHSBA.h, accuracy: 0.001, "Hover hue should equal primary hue")
        XCTAssertEqual(hoverHSBA.s, primaryHSBA.s, accuracy: 0.01, "Hover saturation should equal primary saturation")
        let expectedBrightness = max(0, primaryHSBA.b - 0.10)
        XCTAssertEqual(hoverHSBA.b, expectedBrightness, accuracy: 0.01, "Hover brightness should be primary brightness − 0.10")
        XCTAssertEqual(hoverHSBA.a, 1.0, accuracy: 0.001)
    }

    // MARK: - testHoverDerivationDarkMode

    /// Hover color is ΔL +5% from primaryColor in dark mode.
    func testHoverDerivationDarkMode() {
        let knownColor = Color(red: 0.239, green: 0.545, blue: 1.0)
        let config = AuthClientConfiguration(primaryColor: knownColor)
        let theme = AuthTheme(configuration: config, colorScheme: .dark)

        let primaryHSBA = hsba(of: theme.primaryColor)
        let hoverHSBA = hsba(of: theme.primaryHover)

        // Hover in dark mode: brightness increases by 0.05 (ΔL +5%)
        XCTAssertEqual(hoverHSBA.h, primaryHSBA.h, accuracy: 0.001, "Hover hue should equal primary hue")
        XCTAssertEqual(hoverHSBA.s, primaryHSBA.s, accuracy: 0.01, "Hover saturation should equal primary saturation")
        let expectedBrightness = min(1, primaryHSBA.b + 0.05)
        XCTAssertEqual(hoverHSBA.b, expectedBrightness, accuracy: 0.01, "Hover brightness should be primary brightness + 0.05")
        XCTAssertEqual(hoverHSBA.a, 1.0, accuracy: 0.001)
    }

    // MARK: - testPressedDerivation

    /// Pressed color is ΔL −20% (light) / +10% (dark).
    func testPressedDerivation() {
        let primaryColor = Color(red: 0.5, green: 0.5, blue: 0.8)
        let config = AuthClientConfiguration(primaryColor: primaryColor)

        let lightTheme = AuthTheme(configuration: config, colorScheme: .light)
        let darkTheme = AuthTheme(configuration: config, colorScheme: .dark)

        let lightPrimaryHSBA = hsba(of: lightTheme.primaryColor)
        let lightPressedHSBA = hsba(of: lightTheme.primaryPressed)

        // Pressed in light mode: brightness decreases by 0.20
        XCTAssertEqual(lightPressedHSBA.h, lightPrimaryHSBA.h, accuracy: 0.001)
        let expectedLightBrightness = max(0, lightPrimaryHSBA.b - 0.20)
        XCTAssertEqual(lightPressedHSBA.b, expectedLightBrightness, accuracy: 0.01, "Pressed brightness should be primary − 0.20 in light mode")

        let darkPrimaryHSBA = hsba(of: darkTheme.primaryColor)
        let darkPressedHSBA = hsba(of: darkTheme.primaryPressed)

        // Pressed in dark mode: brightness increases by 0.10
        XCTAssertEqual(darkPressedHSBA.h, darkPrimaryHSBA.h, accuracy: 0.001)
        let expectedDarkBrightness = min(1, darkPrimaryHSBA.b + 0.10)
        XCTAssertEqual(darkPressedHSBA.b, expectedDarkBrightness, accuracy: 0.01, "Pressed brightness should be primary + 0.10 in dark mode")
    }

    // MARK: - testDisabledAlpha

    /// Disabled = primaryColor at 40% opacity.
    func testDisabledAlpha() {
        let primaryColor = Color(red: 0.039, green: 0.400, blue: 1.0)
        let config = AuthClientConfiguration(primaryColor: primaryColor)
        let theme = AuthTheme(configuration: config, colorScheme: .light)

        let primaryRGBA = rgba(of: theme.primaryColor)
        let disabledRGBA = rgba(of: theme.primaryDisabled)

        // RGB values should match primary; only alpha differs.
        XCTAssertEqual(disabledRGBA.r, primaryRGBA.r, accuracy: 0.01)
        XCTAssertEqual(disabledRGBA.g, primaryRGBA.g, accuracy: 0.01)
        XCTAssertEqual(disabledRGBA.b, primaryRGBA.b, accuracy: 0.01)
        XCTAssertEqual(disabledRGBA.a, 0.40, accuracy: 0.01, "Disabled alpha should be 40%")
    }

    // MARK: - testSoftAlphaLightDark

    /// Soft = primaryColor at 10% opacity (light) / 14% opacity (dark).
    func testSoftAlphaLightDark() {
        let primaryColor = Color(red: 0.039, green: 0.400, blue: 1.0)
        let config = AuthClientConfiguration(primaryColor: primaryColor)

        let lightTheme = AuthTheme(configuration: config, colorScheme: .light)
        let darkTheme = AuthTheme(configuration: config, colorScheme: .dark)

        let lightSoftRGBA = rgba(of: lightTheme.primarySoft)
        let darkSoftRGBA = rgba(of: darkTheme.primarySoft)

        XCTAssertEqual(lightSoftRGBA.a, 0.10, accuracy: 0.01, "Soft alpha should be 10% in light mode")
        XCTAssertEqual(darkSoftRGBA.a, 0.14, accuracy: 0.01, "Soft alpha should be 14% in dark mode")
    }

    // MARK: - testAppleColorsImmutable

    /// Apple bg/label are vendor-fixed regardless of primaryColor.
    func testAppleColorsImmutable() {
        // Test with a completely different primary color — apple colors must not change.
        let config1 = AuthClientConfiguration(primaryColor: .red)
        let config2 = AuthClientConfiguration(primaryColor: .green)

        let lightTheme1 = AuthTheme(configuration: config1, colorScheme: .light)
        let lightTheme2 = AuthTheme(configuration: config2, colorScheme: .light)
        let darkTheme1 = AuthTheme(configuration: config1, colorScheme: .dark)
        let darkTheme2 = AuthTheme(configuration: config2, colorScheme: .dark)

        // Light: bg = #000000 (black), label = #FFFFFF (white)
        let lightBg1 = rgba(of: lightTheme1.appleButtonBackground)
        let lightBg2 = rgba(of: lightTheme2.appleButtonBackground)
        XCTAssertEqual(lightBg1.r, 0.0, accuracy: 0.01, "Apple bg R in light should be 0 (black)")
        XCTAssertEqual(lightBg1.g, 0.0, accuracy: 0.01, "Apple bg G in light should be 0 (black)")
        XCTAssertEqual(lightBg1.b, 0.0, accuracy: 0.01, "Apple bg B in light should be 0 (black)")
        XCTAssertEqual(lightBg1.r, lightBg2.r, accuracy: 0.01, "Apple bg must not vary with primaryColor")

        let lightLabel1 = rgba(of: lightTheme1.appleButtonLabel)
        XCTAssertEqual(lightLabel1.r, 1.0, accuracy: 0.01, "Apple label in light should be white")
        XCTAssertEqual(lightLabel1.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(lightLabel1.b, 1.0, accuracy: 0.01)

        // Dark: bg = #FFFFFF (white), label = #000000 (black)
        let darkBg1 = rgba(of: darkTheme1.appleButtonBackground)
        let darkBg2 = rgba(of: darkTheme2.appleButtonBackground)
        XCTAssertEqual(darkBg1.r, 1.0, accuracy: 0.01, "Apple bg R in dark should be 1 (white)")
        XCTAssertEqual(darkBg1.g, 1.0, accuracy: 0.01)
        XCTAssertEqual(darkBg1.b, 1.0, accuracy: 0.01)
        XCTAssertEqual(darkBg1.r, darkBg2.r, accuracy: 0.01, "Apple bg must not vary with primaryColor")

        let darkLabel1 = rgba(of: darkTheme1.appleButtonLabel)
        XCTAssertEqual(darkLabel1.r, 0.0, accuracy: 0.01, "Apple label in dark should be black")
        XCTAssertEqual(darkLabel1.g, 0.0, accuracy: 0.01)
        XCTAssertEqual(darkLabel1.b, 0.0, accuracy: 0.01)
    }

    // MARK: - testGoogleButtonTransparentStyle

    /// Google button returns clear background and primary.opacity(0.2) border.
    func testGoogleButtonTransparentStyle() {
        let primaryColor = Color(red: 0.039, green: 0.400, blue: 1.0)
        let config = AuthClientConfiguration(primaryColor: primaryColor)
        let theme = AuthTheme(configuration: config, colorScheme: .light)

        let googleStyle = theme.googleButtonStyle

        // Background must be transparent (Color.clear → alpha == 0)
        let bgRGBA = rgba(of: googleStyle.background)
        XCTAssertEqual(bgRGBA.a, 0.0, accuracy: 0.01, "Google button background must be transparent (Color.clear)")

        // Border color must be primaryColor at 20% opacity
        let borderRGBA = rgba(of: googleStyle.borderColor)
        let primaryRGBA = rgba(of: theme.primaryColor)
        XCTAssertEqual(borderRGBA.r, primaryRGBA.r, accuracy: 0.01, "Google border R should match primary R")
        XCTAssertEqual(borderRGBA.g, primaryRGBA.g, accuracy: 0.01, "Google border G should match primary G")
        XCTAssertEqual(borderRGBA.b, primaryRGBA.b, accuracy: 0.01, "Google border B should match primary B")
        XCTAssertEqual(borderRGBA.a, 0.20, accuracy: 0.01, "Google border alpha should be 20%")

        // Border width and corner radius
        XCTAssertEqual(googleStyle.borderWidth, 1.0, accuracy: 0.001, "Google button border should be 1pt")
        XCTAssertEqual(googleStyle.cornerRadius, 9999.0, accuracy: 0.001, "Google button corner radius should be radius.pill (9999)")
        XCTAssertEqual(googleStyle.height, 50.0, accuracy: 0.001, "Google button height should be 50pt")
    }
}
// swiftlint:enable file_length
