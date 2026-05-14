import XCTest
@testable import AuthShared

final class LoginRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = LoginRequest(email: "user@example.com", password: "pass456")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(LoginRequest.self, from: data)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.password, original.password)
    }
}
