import XCTest
@testable import AuthShared

final class UpgradeGuestRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = UpgradeGuestRequest(
            guestUUID: "guest-uuid-123",
            provider: "email",
            email: "upgrade@example.com",
            password: "upgradePass",
            identityToken: nil
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UpgradeGuestRequest.self, from: data)
        XCTAssertEqual(decoded.guestUUID, original.guestUUID)
        XCTAssertEqual(decoded.provider, original.provider)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.password, original.password)
        XCTAssertNil(decoded.identityToken)
    }

    func testGuestUUIDFieldIsPresent() throws {
        let request = UpgradeGuestRequest(
            guestUUID: "uuid-abc",
            provider: "google",
            email: nil,
            password: nil,
            identityToken: "google-token"
        )
        XCTAssertEqual(request.guestUUID, "uuid-abc")
    }
}
