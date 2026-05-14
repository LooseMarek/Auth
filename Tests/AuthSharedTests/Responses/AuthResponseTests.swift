import XCTest
@testable import AuthShared

final class AuthResponseTests: XCTestCase {

    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func testEncodeDecodeRoundTrip_preservesAllFields() throws {
        let user = UserDTO(id: "u-1", email: "test@example.com", displayName: "Bob")
        let expiresAt = Date(timeIntervalSince1970: 1_800_000_000)
        let original = AuthResponse(
            accessToken: "access-jwt",
            refreshToken: "refresh-token",
            expiresAt: expiresAt,
            user: user
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AuthResponse.self, from: data)
        XCTAssertEqual(decoded.accessToken, original.accessToken)
        XCTAssertEqual(decoded.refreshToken, original.refreshToken)
        XCTAssertEqual(decoded.user.id, original.user.id)
        XCTAssertEqual(decoded.user.email, original.user.email)
        XCTAssertEqual(decoded.user.displayName, original.user.displayName)
    }

    func testExpiresAt_encodesAndDecodesAsISO8601() throws {
        let user = UserDTO(id: "u-2", email: nil, displayName: nil)
        let expiresAt = Date(timeIntervalSince1970: 1_700_000_000)
        let original = AuthResponse(
            accessToken: "tok",
            refreshToken: "ref",
            expiresAt: expiresAt,
            user: user
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AuthResponse.self, from: data)
        // ISO8601 has second-level precision — compare within 1 second
        XCTAssertEqual(
            decoded.expiresAt.timeIntervalSince1970,
            expiresAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }
}
