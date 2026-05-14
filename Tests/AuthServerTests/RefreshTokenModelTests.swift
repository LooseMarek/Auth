import XCTest
import Fluent
@testable import AuthServer

final class RefreshTokenModelTests: XCTestCase {

    func testSchema() {
        XCTAssertEqual(RefreshToken.schema, "refresh_tokens")
    }

    func testInitialization() {
        let userID = UUID()
        let expiresAt = Date().addingTimeInterval(86400)
        let token = RefreshToken(
            token: "unique-refresh-token-string",
            userID: userID,
            expiresAt: expiresAt
        )

        XCTAssertEqual(token.token, "unique-refresh-token-string")
        XCTAssertEqual(token.$user.id, userID)
        XCTAssertEqual(token.expiresAt, expiresAt)
        XCTAssertNil(token.id)
    }

    func testInitializationWithCustomID() {
        let id = UUID()
        let token = RefreshToken(
            id: id,
            token: "token",
            userID: UUID(),
            expiresAt: Date()
        )

        XCTAssertEqual(token.id, id)
    }
}
