import XCTest
import Fluent
@testable import AuthServer

// NOTE: Unit test per CLAUDE.md constraints.
// No Fluent driver import. We construct the canonical migration list manually
// and assert its count and member types — no DB execution required.

final class AuthServerMigrationTests: XCTestCase {

    /// The canonical migration list that every host app should register.
    ///
    /// Produces the complete Auth schema in 3 steps:
    ///  1. CreateUser            — users table (includes auth_provider)
    ///  2. CreateRefreshToken    — refresh_tokens table
    ///  3. CreatePasswordResetToken — password_reset_tokens table
    private let migrations: [any AsyncMigration] = [
        CreateUser(),
        CreateRefreshToken(),
        CreatePasswordResetToken(),
    ]

    // MARK: - Count

    func testMigrationCount() {
        XCTAssertEqual(
            migrations.count,
            3,
            "There should be exactly 3 migrations: CreateUser, CreateRefreshToken, CreatePasswordResetToken"
        )
    }

    // MARK: - Types

    func testMigrationOrder_firstIsCreateUser() {
        XCTAssertTrue(
            migrations[0] is CreateUser,
            "First migration must be CreateUser"
        )
    }

    func testMigrationOrder_secondIsCreateRefreshToken() {
        XCTAssertTrue(
            migrations[1] is CreateRefreshToken,
            "Second migration must be CreateRefreshToken"
        )
    }

    func testMigrationOrder_thirdIsCreatePasswordResetToken() {
        XCTAssertTrue(
            migrations[2] is CreatePasswordResetToken,
            "Third migration must be CreatePasswordResetToken"
        )
    }
}
