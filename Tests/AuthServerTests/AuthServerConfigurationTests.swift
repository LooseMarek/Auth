import XCTest
@testable import AuthServer

final class AuthServerConfigurationTests: XCTestCase {

    func testDefaultTTLValues() {
        let config = AuthServerConfiguration(jwtSigningSecret: "any-secret")

        XCTAssertEqual(config.accessTokenTTL, 3600)
        XCTAssertEqual(config.refreshTokenTTL, 86400)
    }
}
