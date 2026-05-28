import XCTest
@testable import AuthClient

/// Verifies the Localizable.strings file is correctly structured and follows naming conventions.
final class LocalisationTests: XCTestCase {

    // MARK: - Bundle access

    private var bundle: Bundle { Bundle.module }

    // MARK: - All keys that must exist in Localizable.strings

    private let allExpectedKeys: [String] = [
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

    // MARK: - Tests

    /// Verifies every expected localisation key resolves to a non-empty default value
    /// from the module bundle (i.e., the key exists and has a real string, not the key itself).
    func testAllKeysHaveDefaultValues() {
        for key in allExpectedKeys {
            let value = String(localized: String.LocalizationValue(key), bundle: bundle)
            XCTAssertFalse(
                value.isEmpty,
                "Key '\(key)' resolved to an empty string."
            )
            XCTAssertNotEqual(
                value, key,
                "Key '\(key)' was not found in Localizable.strings — resolved to the key itself."
            )
        }
    }

    // MARK: - Register view placeholder values

    /// Verifies the email placeholder on RegisterView is "Email" (issue #97).
    func testRegisterEmailPlaceholder_isEmail() {
        let value = String(localized: "auth.register.field.email.placeholder", bundle: bundle)
        XCTAssertEqual(value, "Email", "Register email placeholder should be 'Email'")
    }

    /// Verifies the password placeholder on RegisterView is "Password" (issue #97).
    func testRegisterPasswordPlaceholder_isPassword() {
        let value = String(localized: "auth.register.field.password.placeholder", bundle: bundle)
        XCTAssertEqual(value, "Password", "Register password placeholder should be 'Password'")
    }

    /// Verifies the confirm-password placeholder on RegisterView is "Re-enter password" (issue #97).
    func testRegisterConfirmPasswordPlaceholder_isReEnterPassword() {
        let value = String(localized: "auth.register.field.confirm_password.placeholder", bundle: bundle)
        XCTAssertEqual(value, "Re-enter password", "Register confirm-password placeholder should be 'Re-enter password'")
    }

    // MARK: - auth.error.server key

    /// Verifies `auth.error.server` resolves to a non-empty, human-readable string (not the bare key).
    func testAuthErrorServerKey_resolvesNonEmpty() {
        let value = String(localized: "auth.error.server", bundle: bundle)
        XCTAssertFalse(value.isEmpty, "auth.error.server should resolve to a non-empty string")
        XCTAssertNotEqual(
            value, "auth.error.server",
            "auth.error.server should not resolve to the bare key — add it to Localizable.strings"
        )
    }

    // MARK: - Key convention

    /// Spot-checks that a representative set of keys follows the auth.{screen}.{element} pattern.
    func testKeyConventionIsCorrect() {
        let conventionPattern = #"^auth\.[a-z_]+(\.[a-z_]+)+$"#
        guard let regex = try? NSRegularExpression(pattern: conventionPattern) else {
            XCTFail("Invalid regex pattern — this is a test bug.")
            return
        }

        let spotCheckKeys = [
            "auth.login.title",
            "auth.login.button.submit",
            "auth.register.error.password_mismatch",
            "auth.forgot.success.body",
            "auth.button.google",
            "auth.error.network",
            "auth.field.password.show",
            "auth.social.error.token_invalid",
        ]

        for key in spotCheckKeys {
            let range = NSRange(key.startIndex..., in: key)
            let match = regex.firstMatch(in: key, range: range)
            XCTAssertNotNil(
                match,
                "Key '\(key)' does not follow the auth.{screen}.{element} naming convention."
            )
        }
    }
}
