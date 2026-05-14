import XCTest
import Fluent
@testable import AuthServer

final class UserModelTests: XCTestCase {

    func testSchema() {
        XCTAssertEqual(User.schema, "users")
    }

    func testInitialization() {
        let user = User(email: "test@example.com", passwordHash: "hashedpassword123")

        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.passwordHash, "hashedpassword123")
        XCTAssertNil(user.id)
    }

    func testInitializationWithCustomID() {
        let id = UUID()
        let user = User(id: id, email: "test@example.com", passwordHash: "hash")

        XCTAssertEqual(user.id, id)
    }
}
