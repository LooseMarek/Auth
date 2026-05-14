import XCTest
@testable import AuthShared

final class ForgotPasswordRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = ForgotPasswordRequest(email: "forgot@example.com")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ForgotPasswordRequest.self, from: data)
        XCTAssertEqual(decoded.email, original.email)
    }
}
