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

    // MARK: - testConfigurationHasLightAndDarkTokens

    func testConfigurationHasLightAndDarkTokens() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: both scheme-specific token sets are supplied (dual-scheme API)
        XCTAssertNotNil(config.lightTokens, "lightTokens must be set for the custom theme")
        XCTAssertNotNil(config.darkTokens,  "darkTokens must be set for the custom theme")
    }

    // MARK: - testLightTokensHaveWarmOrangePrimary

    func testLightTokensHaveWarmOrangePrimary() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        guard let lightPrimary = config.lightTokens?.primaryColor else {
            XCTFail("lightTokens.primaryColor must be set")
            return
        }

        // Then: light primary is the warm orange (~#FF6B35)
        #if canImport(UIKit)
        let uiColor = UIColor(lightPrimary)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red,   1.0,  accuracy: 0.01, "light primaryColor red should be ~1.0")
        XCTAssertEqual(green, 0.42, accuracy: 0.01, "light primaryColor green should be ~0.42")
        XCTAssertEqual(blue,  0.21, accuracy: 0.01, "light primaryColor blue should be ~0.21")
        #else
        XCTAssertNotNil(lightPrimary)
        #endif
    }

    // MARK: - testDarkTokensHaveBrighterOrangePrimary

    func testDarkTokensHaveBrighterOrangePrimary() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        guard let darkPrimary = config.darkTokens?.primaryColor else {
            XCTFail("darkTokens.primaryColor must be set")
            return
        }

        // Then: dark primary is brighter than the light primary (higher green component)
        #if canImport(UIKit)
        let uiColor = UIColor(darkPrimary)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        XCTAssertEqual(red,   1.0,  accuracy: 0.01, "dark primaryColor red should be ~1.0")
        XCTAssertGreaterThan(green, 0.42, "dark primaryColor green should be brighter than light variant")
        #else
        XCTAssertNotNil(darkPrimary)
        #endif
    }

    // MARK: - testAllTokensHaveExplicitBackgroundAndSurface

    func testAllTokensHaveExplicitBackgroundAndSurface() {
        // Given: the custom app configuration
        let config = DemoAuthCustomApp.makeConfiguration()

        // Then: neither scheme uses a nil backgroundColor or surfaceColor — full customisation
        XCTAssertNotNil(config.lightTokens?.backgroundColor, "light backgroundColor must be explicitly set")
        XCTAssertNotNil(config.lightTokens?.surfaceColor,    "light surfaceColor must be explicitly set")
        XCTAssertNotNil(config.darkTokens?.backgroundColor,  "dark backgroundColor must be explicitly set")
        XCTAssertNotNil(config.darkTokens?.surfaceColor,     "dark surfaceColor must be explicitly set")
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
    "auth.login.register_prompt",
    "auth.login.register_link",
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
    "auth.register.login_prompt",
    "auth.register.login_link",
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
    "auth.forgot.success.button.enter_token",
    // ResetPasswordView
    "auth.reset.title",
    "auth.reset.subtitle",
    "auth.reset.field.token.placeholder",
    "auth.reset.field.new_password.placeholder",
    "auth.reset.field.confirm_password.placeholder",
    "auth.reset.button.submit",
    "auth.reset.link.back",
    "auth.reset.success.title",
    "auth.reset.success.body",
    "auth.reset.error.password_mismatch",
    "auth.reset.error.password_too_short",
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
    "auth.error.server_unreachable",
    "auth.error.server",
    "auth.social.error.token_invalid",
    "auth.upgrade.error.account_already_exists",
    "auth.error.invalid_reset_token",
    // Toast
    "auth.toast.dismiss.hint",
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
