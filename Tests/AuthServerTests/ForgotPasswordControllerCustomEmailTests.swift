import XCTest
@testable import AuthServer

// NOTE: Unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test the email-content generation helper directly, without a real DB.

final class ForgotPasswordControllerCustomEmailTests: XCTestCase {

    // MARK: - Custom closure is used when set

    /// Verifies that `ForgotPasswordController.makeEmailContent(token:)` calls
    /// `configuration.passwordResetEmailContent` when the closure is set, returning
    /// the custom subject and body rather than the built-in hardcoded strings.
    func testPasswordResetEmailContent_usesCustomClosureWhenSet() {
        var config = AuthServerConfiguration(jwtSigningSecret: "test-secret")
        config.passwordResetEmailContent = { token in
            (subject: "Custom subject", body: "Custom body for \(token)")
        }
        let controller = ForgotPasswordController(configuration: config)

        let result = controller.makeEmailContent(token: "abc-123")

        XCTAssertEqual(result.subject, "Custom subject",
            "Subject should come from the custom closure, not the hardcoded default")
        XCTAssertEqual(result.body, "Custom body for abc-123",
            "Body should come from the custom closure, not the hardcoded default")
    }

    // MARK: - Default strings are used when closure is nil

    /// Verifies that `makeEmailContent(token:)` returns the built-in English template
    /// when `passwordResetEmailContent` is `nil`.
    func testPasswordResetEmailContent_usesDefaultStringsWhenNil() {
        let config = AuthServerConfiguration(jwtSigningSecret: "test-secret")
        let controller = ForgotPasswordController(configuration: config)

        let result = controller.makeEmailContent(token: "xyz-456")

        XCTAssertFalse(result.subject.isEmpty,
            "Default subject must not be empty")
        XCTAssertTrue(result.body.contains("xyz-456"),
            "Default body must contain the reset token")
        // Verify it's the English default (not the custom closure).
        XCTAssertEqual(result.subject, "Reset your password",
            "Default subject should be the built-in English string")
    }
}
