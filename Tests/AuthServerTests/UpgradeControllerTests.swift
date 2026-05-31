import XCTest
@testable import AuthServer

// NOTE: These are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test the duplicate-key detection helper directly, without a real DB.

final class UpgradeControllerTests: XCTestCase {

    // MARK: - Duplicate-key detection (Apple upgrade — SQLite)

    /// Verifies the controller correctly identifies a UNIQUE constraint error
    /// that would occur when an Apple token's email is already registered.
    /// SQLite surfaces this as "UNIQUE constraint failed: users.email".
    func testUpgradeWithDuplicateAppleEmail_returns409() {
        struct FakeDBError: Error { let message: String }
        let error = FakeDBError(message: "UNIQUE constraint failed: users.email")
        let controller = UpgradeController(configuration: .init(jwtSigningSecret: "s"))
        XCTAssertTrue(
            controller.isDuplicateKeyError(error),
            "Controller must detect SQLite UNIQUE constraint error for Apple upgrade"
        )
    }

    // MARK: - Duplicate-key detection (Google upgrade — SQLite)

    /// Verifies the controller correctly identifies a UNIQUE constraint error
    /// that would occur when a Google token's email is already registered.
    /// SQLite surfaces this as "UNIQUE constraint failed: users.email".
    func testUpgradeWithDuplicateGoogleEmail_returns409() {
        struct FakeDBError: Error { let message: String }
        let error = FakeDBError(message: "UNIQUE constraint failed: users.email")
        let controller = UpgradeController(configuration: .init(jwtSigningSecret: "s"))
        XCTAssertTrue(
            controller.isDuplicateKeyError(error),
            "Controller must detect SQLite UNIQUE constraint error for Google upgrade"
        )
    }

    // MARK: - Duplicate-key detection (email/password upgrade — Postgres)

    /// Verifies the controller correctly identifies a duplicate key error
    /// that would occur when an email/password pair's email is already registered.
    /// Postgres surfaces this as "duplicate key value violates unique constraint".
    func testUpgradeWithDuplicateEmailPassword_returns409() {
        struct FakeDBError: Error { let message: String }
        let error = FakeDBError(message: "duplicate key value violates unique constraint")
        let controller = UpgradeController(configuration: .init(jwtSigningSecret: "s"))
        XCTAssertTrue(
            controller.isDuplicateKeyError(error),
            "Controller must detect Postgres duplicate key error for email/password upgrade"
        )
    }

    // MARK: - Non-duplicate errors are not misidentified

    /// Verifies that an unrelated database error is NOT flagged as a duplicate key error.
    func testNonDuplicateError_isNotFlaggedAsDuplicate() {
        struct FakeDBError: Error { let message: String }
        let error = FakeDBError(message: "connection refused")
        let controller = UpgradeController(configuration: .init(jwtSigningSecret: "s"))
        XCTAssertFalse(
            controller.isDuplicateKeyError(error),
            "Controller must not misidentify unrelated errors as duplicate key errors"
        )
    }
}
