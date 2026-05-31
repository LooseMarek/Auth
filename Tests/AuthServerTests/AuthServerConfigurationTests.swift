import XCTest
@testable import AuthServer

final class AuthServerConfigurationTests: XCTestCase {

    func testDefaultTTLValues() {
        let config = AuthServerConfiguration(jwtSigningSecret: "any-secret")

        XCTAssertEqual(config.accessTokenTTL, 3600)
        XCTAssertEqual(config.refreshTokenTTL, 86400)
    }

    /// Verifies that `AuthServerConfiguration` can be initialised with the
    /// development default signing secret (i.e. when `JWT_SIGNING_SECRET`
    /// env var is absent) without throwing.
    func testJWTSigningSecretDefaultIsUsedWhenEnvVarAbsent() {
        let secret = AuthServerConfiguration.developmentDefaultJWTSigningSecret
        let config = AuthServerConfiguration(jwtSigningSecret: secret)

        XCTAssertEqual(config.jwtSigningSecret, AuthServerConfiguration.developmentDefaultJWTSigningSecret)
    }
}
