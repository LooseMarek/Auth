import XCTest
@testable import AuthShared

final class ResetPasswordRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = ResetPasswordRequest(token: "reset-token-abc", newPassword: "newPass789")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ResetPasswordRequest.self, from: data)
        XCTAssertEqual(decoded.token, original.token)
        XCTAssertEqual(decoded.newPassword, original.newPassword)
    }
}
