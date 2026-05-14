import XCTest
import Fluent
@testable import AuthServer

final class PasswordResetTokenModelTests: XCTestCase {

    func testSchema() {
        XCTAssertEqual(PasswordResetToken.schema, "password_reset_tokens")
    }

    func testInitialization() {
        let userID = UUID()
        let expiresAt = Date().addingTimeInterval(3600)
        let token = PasswordResetToken(
            token: "unique-reset-token",
            userID: userID,
            expiresAt: expiresAt
        )

        XCTAssertEqual(token.token, "unique-reset-token")
        XCTAssertEqual(token.$user.id, userID)
        XCTAssertEqual(token.expiresAt, expiresAt)
        XCTAssertNil(token.id)
    }

    func testInitializationWithCustomID() {
        let id = UUID()
        let token = PasswordResetToken(
            id: id,
            token: "reset-tok",
            userID: UUID(),
            expiresAt: Date()
        )

        XCTAssertEqual(token.id, id)
    }

    func testIsExpired_whenExpiryIsPast_returnsTrue() {
        let token = PasswordResetToken(
            token: "tok",
            userID: UUID(),
            expiresAt: Date().addingTimeInterval(-1)
        )
        XCTAssertTrue(token.isExpired, "A token with a past expiry date should be expired")
    }

    func testIsExpired_whenExpiryIsFuture_returnsFalse() {
        let token = PasswordResetToken(
            token: "tok",
            userID: UUID(),
            expiresAt: Date().addingTimeInterval(3600)
        )
        XCTAssertFalse(token.isExpired, "A token with a future expiry date should not be expired")
    }
}
