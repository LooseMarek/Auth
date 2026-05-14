import XCTest
import XCTVapor
import JWTKit
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test AuthController structure, route registration, and the pure
// TokenGenerator helper (JWT signing, refresh token format) without hitting the DB.

final class AuthControllerTests: XCTestCase {

    private let configuration = AuthServerConfiguration(
        jwtSigningSecret: "test-signing-secret",
        accessTokenTTL: 3600,
        refreshTokenTTL: 86400
    )

    // MARK: - AuthController initialisation

    func testAuthControllerInitialisesWithConfiguration() {
        let controller = AuthController(configuration: configuration)
        XCTAssertNotNil(controller)
    }

    // MARK: - Route registration (both routes)

    func testBothAuthRoutesAreRegistered() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        let controller = AuthController(configuration: configuration)
        try app.register(collection: controller)

        let paths = app.routes.all.map { route in
            "\(route.method.rawValue) \(route.path.map(\.description).joined(separator: "/"))"
        }

        XCTAssertTrue(paths.contains("POST auth/register"), "POST auth/register must be registered")
        XCTAssertTrue(paths.contains("POST auth/login"), "POST auth/login must be registered")
    }

    // MARK: - TokenGenerator — pure JWT signing

    func testTokenGeneratorProducesNonEmptyAccessToken() async throws {
        let generator = TokenGenerator(configuration: configuration)
        let userID = UUID()
        let token = try await generator.makeAccessToken(userID: userID)
        XCTAssertFalse(token.token.isEmpty, "Access token string must not be empty")
    }

    func testTokenGeneratorAccessTokenExpiresAfterTTL() async throws {
        let ttl: TimeInterval = 60
        let config = AuthServerConfiguration(jwtSigningSecret: "secret", accessTokenTTL: ttl)
        let generator = TokenGenerator(configuration: config)
        let result = try await generator.makeAccessToken(userID: UUID())

        let expectedExpiry = Date().addingTimeInterval(ttl)
        XCTAssertEqual(
            result.expiresAt.timeIntervalSince1970,
            expectedExpiry.timeIntervalSince1970,
            accuracy: 2.0,
            "Access token expiry should match the configured TTL"
        )
    }

    func testTokenGeneratorAccessTokenCanBeVerified() async throws {
        let generator = TokenGenerator(configuration: configuration)
        let result = try await generator.makeAccessToken(userID: UUID())

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: configuration.jwtSigningSecret), digestAlgorithm: .sha256)
        let payload = try await keys.verify(result.token, as: AuthPayload.self)
        XCTAssertFalse(payload.subject.value.isEmpty, "Verified token should contain a subject claim")
    }

    func testTokenGeneratorAccessTokenSubjectMatchesUserID() async throws {
        let generator = TokenGenerator(configuration: configuration)
        let userID = UUID()
        let result = try await generator.makeAccessToken(userID: userID)

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: configuration.jwtSigningSecret), digestAlgorithm: .sha256)
        let payload = try await keys.verify(result.token, as: AuthPayload.self)
        XCTAssertEqual(payload.subject.value, userID.uuidString, "JWT subject must match the user UUID")
    }

    // MARK: - TokenGenerator — refresh token

    func testTokenGeneratorProducesNonEmptyRefreshToken() {
        let generator = TokenGenerator(configuration: configuration)
        let refreshToken = generator.makeRefreshToken(userID: UUID())
        XCTAssertFalse(refreshToken.token.isEmpty, "Refresh token string must not be empty")
    }

    func testTokenGeneratorRefreshTokenExpiresAfterTTL() {
        let ttl: TimeInterval = 7200
        let config = AuthServerConfiguration(jwtSigningSecret: "s", refreshTokenTTL: ttl)
        let generator = TokenGenerator(configuration: config)
        let result = generator.makeRefreshToken(userID: UUID())

        let expectedExpiry = Date().addingTimeInterval(ttl)
        XCTAssertEqual(
            result.expiresAt.timeIntervalSince1970,
            expectedExpiry.timeIntervalSince1970,
            accuracy: 2.0,
            "Refresh token expiry should match the configured TTL"
        )
    }

    func testTokenGeneratorRefreshTokenUserIDMatchesInput() {
        let generator = TokenGenerator(configuration: configuration)
        let userID = UUID()
        let result = generator.makeRefreshToken(userID: userID)
        XCTAssertEqual(result.userID, userID, "Refresh token must reference the correct user ID")
    }

    func testTwoRefreshTokensAreUnique() {
        let generator = TokenGenerator(configuration: configuration)
        let userID = UUID()
        let first = generator.makeRefreshToken(userID: userID)
        let second = generator.makeRefreshToken(userID: userID)
        XCTAssertNotEqual(first.token, second.token, "Each refresh token should be unique")
    }
}
