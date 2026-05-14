import XCTest
@testable import AuthShared

final class RegisterRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = RegisterRequest(email: "test@example.com", password: "secret123")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RegisterRequest.self, from: data)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.password, original.password)
    }
}
