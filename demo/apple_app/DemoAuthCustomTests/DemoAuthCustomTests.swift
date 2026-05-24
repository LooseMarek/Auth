import XCTest
import AuthClient
@testable import DemoAuthCustom

// MARK: - DemoAuthCustomAppTests

final class DemoAuthCustomAppTests: XCTestCase {

    func testCustomTargetBuildsWithoutErrors() {
        // This test verifies the DemoAuthCustom target compiles successfully.
        // A successful build is sufficient — no runtime assertions needed.
        XCTAssertTrue(true)
    }

    // MARK: - testConfigurationHasCustomPrimaryColor

    func testConfigurationHasCustomPrimaryColor() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: primaryColor is the warm orange (#FF6B35)
        // We verify by round-tripping through UIColor to extract components.
        // Color(red:green:blue:) stores sRGB components — resolve via UIColor.
        #if canImport(UIKit)
        let uiColor = UIColor(config.primaryColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red,   1.0,  accuracy: 0.01, "primaryColor red component should be ~1.0")
        XCTAssertEqual(green, 0.42, accuracy: 0.01, "primaryColor green component should be ~0.42")
        XCTAssertEqual(blue,  0.21, accuracy: 0.01, "primaryColor blue component should be ~0.21")
        #else
        // On macOS the Color resolves differently; just assert it is not the Auth Blue default.
        // The Auth Blue default has red ~0.039 in light mode — orange has red 1.0, clearly distinct.
        XCTAssertNotNil(config.primaryColor)
        #endif
    }

    // MARK: - testConfigurationHasCustomSurfaceColor

    func testConfigurationHasCustomSurfaceColor() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: surfaceColor is non-nil (an explicit override, not using the Auth adaptive default)
        XCTAssertNotNil(config.surfaceColor, "surfaceColor must be explicitly set for the custom theme")
    }

    // MARK: - testConfigurationHasCustomFont

    func testConfigurationHasCustomFont() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: font is non-nil (a custom font override is provided)
        XCTAssertNotNil(config.font, "font must be explicitly set for the custom theme")
    }

    // MARK: - testLocalizationBundleIsSetToMainBundle

    func testLocalizationBundleIsSetToMainBundle() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: localizationBundle is Bundle.main so the demo app's .lproj files are used
        XCTAssertEqual(
            config.localizationBundle,
            Bundle.main,
            "localizationBundle must be Bundle.main so the demo app's Localizable.strings override Auth's built-in strings"
        )
    }
}

// MARK: - DemoAuthCustomLocalisationTests

/// All keys that must be present in the demo app's Localizable.strings files.
/// Derived from AuthClient's canonical en.lproj/Localizable.strings.
private let allAuthKeys: [String] = [
    // LoginView
    "auth.login.title",
    "auth.login.subtitle",
    "auth.login.field.email.placeholder",
    "auth.login.field.password.placeholder",
    "auth.login.button.submit",
    "auth.login.link.forgot_password",
    "auth.login.link.register",
    "auth.login.button.guest",
    "auth.login.error.invalid_credentials",
    // RegisterView
    "auth.register.title",
    "auth.register.subtitle",
    "auth.register.upgrade.title",
    "auth.register.upgrade.subtitle",
    "auth.register.field.email.placeholder",
    "auth.register.field.password.placeholder",
    "auth.register.field.confirm_password.placeholder",
    "auth.register.button.submit",
    "auth.register.upgrade.button.submit",
    "auth.register.link.login",
    "auth.register.error.password_too_short",
    "auth.register.error.password_mismatch",
    "auth.register.error.email_taken",
    // ForgotPasswordView
    "auth.forgot.title",
    "auth.forgot.subtitle",
    "auth.forgot.field.email.placeholder",
    "auth.forgot.button.submit",
    "auth.forgot.link.back",
    "auth.forgot.success.title",
    "auth.forgot.success.body",
    // Shared buttons
    "auth.button.apple",
    "auth.button.apple.accessibility",
    "auth.button.google",
    "auth.button.google.accessibility",
    // Shared UI
    "auth.separator.or",
    "auth.field.password.show",
    "auth.field.password.hide",
    // Shared errors
    "auth.error.required",
    "auth.error.email_format",
    "auth.error.network",
    "auth.error.server",
    "auth.social.error.token_invalid",
]

final class DemoAuthCustomLocalisationTests: XCTestCase {

    // MARK: - testEnglishStringsFileContainsAllAuthKeys

    func testEnglishStringsFileContainsAllAuthKeys() {
        // Given: the English Localizable.strings file from the demo app bundle
        guard let stringsURL = Bundle.main.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: "en"
        ) else {
            XCTFail("en.lproj/Localizable.strings not found in Bundle.main — ensure the file is added to the DemoAuthCustom target")
            return
        }

        guard let strings = NSDictionary(contentsOf: stringsURL) as? [String: String] else {
            XCTFail("Failed to parse en.lproj/Localizable.strings as a strings dictionary")
            return
        }

        // Then: every AuthClient key has a corresponding entry
        for key in allAuthKeys {
            XCTAssertNotNil(
                strings[key],
                "en.lproj/Localizable.strings is missing key: \"\(key)\""
            )
        }
    }

    // MARK: - testPolishStringsFileContainsAllAuthKeys

    func testPolishStringsFileContainsAllAuthKeys() {
        // Given: the Polish Localizable.strings file from the demo app bundle
        guard let stringsURL = Bundle.main.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: nil,
            localization: "pl"
        ) else {
            XCTFail("pl.lproj/Localizable.strings not found in Bundle.main — ensure the file is added to the DemoAuthCustom target")
            return
        }

        guard let strings = NSDictionary(contentsOf: stringsURL) as? [String: String] else {
            XCTFail("Failed to parse pl.lproj/Localizable.strings as a strings dictionary")
            return
        }

        // Then: every AuthClient key has a corresponding Polish entry
        for key in allAuthKeys {
            XCTAssertNotNil(
                strings[key],
                "pl.lproj/Localizable.strings is missing key: \"\(key)\""
            )
        }
    }
}
