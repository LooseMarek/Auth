import XCTest
@testable import AuthShared

final class UserDTOTests: XCTestCase {

    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func testEncodeDecodeRoundTrip_withAllFields() throws {
        let original = UserDTO(id: "abc-123", email: "user@example.com", displayName: "Alice")
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UserDTO.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.displayName, original.displayName)
    }

    func testEncodeDecodeRoundTrip_withNilOptionals_guestUser() throws {
        let original = UserDTO(id: "guest-456", email: nil, displayName: nil)
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UserDTO.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertNil(decoded.email)
        XCTAssertNil(decoded.displayName)
    }

    func testNilOptionals_areOmittedFromJSON() throws {
        let original = UserDTO(id: "guest-789", email: nil, displayName: nil)
        let data = try encoder.encode(original)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertFalse(json.contains("\"email\""), "Nil email key should be omitted from JSON, got: \(json)")
        XCTAssertFalse(json.contains("\"displayName\""), "Nil displayName key should be omitted from JSON, got: \(json)")
    }
}
