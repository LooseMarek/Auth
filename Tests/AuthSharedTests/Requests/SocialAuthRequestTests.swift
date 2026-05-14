import XCTest
@testable import AuthShared

final class SocialAuthRequestTests: XCTestCase {

    func testEncodeDecodeRoundTrip() throws {
        let original = SocialAuthRequest(provider: .apple, identityToken: "id-token-xyz")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SocialAuthRequest.self, from: data)
        XCTAssertEqual(decoded.provider, original.provider)
        XCTAssertEqual(decoded.identityToken, original.identityToken)
    }
}
