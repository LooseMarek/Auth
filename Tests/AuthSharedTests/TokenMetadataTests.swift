import XCTest
@testable import AuthShared

final class TokenMetadataTests: XCTestCase {

    private var encoder: JSONEncoder!
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func testIsExpired_returnsFalse_whenExpiresAtIsInFuture() {
        let future = Date(timeIntervalSinceNow: 3600)
        let metadata = TokenMetadata(accessToken: "a", refreshToken: "r", expiresAt: future)
        XCTAssertFalse(metadata.isExpired)
    }

    func testIsExpired_returnsTrue_whenExpiresAtIsInPast() {
        let past = Date(timeIntervalSinceNow: -3600)
        let metadata = TokenMetadata(accessToken: "a", refreshToken: "r", expiresAt: past)
        XCTAssertTrue(metadata.isExpired)
    }

    func testEncodeDecodeRoundTrip_preservesAllFields() throws {
        let expiresAt = Date(timeIntervalSince1970: 1_900_000_000)
        let original = TokenMetadata(
            accessToken: "access-xyz",
            refreshToken: "refresh-abc",
            expiresAt: expiresAt
        )
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TokenMetadata.self, from: data)
        XCTAssertEqual(decoded.accessToken, original.accessToken)
        XCTAssertEqual(decoded.refreshToken, original.refreshToken)
        XCTAssertEqual(
            decoded.expiresAt.timeIntervalSince1970,
            expiresAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }
}
