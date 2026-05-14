import XCTest
@testable import AuthShared

final class GuestAuthRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = GuestAuthRequest(deviceID: "device-uuid-001")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GuestAuthRequest.self, from: data)
        XCTAssertEqual(decoded.deviceID, original.deviceID)
    }
}
