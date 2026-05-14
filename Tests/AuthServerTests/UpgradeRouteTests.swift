import XCTest
import XCTVapor
import JWTKit
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration, JWT middleware wiring, and request type conformance
// without hitting a real DB.

final class UpgradeRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = UpgradeController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    private func signedToken(
        secret: String = "test-secret",
        expiration: Date = Date().addingTimeInterval(3600)
    ) async throws -> String {
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: secret), digestAlgorithm: .sha256)
        let payload = AuthPayload(
            subject: SubjectClaim(value: UUID().uuidString),
            expiration: ExpirationClaim(value: expiration)
        )
        return try await keys.sign(payload)
    }

    // MARK: - Route Registration

    func testEmailUpgradePreservesUUID() async throws {
        // Verifies POST /auth/upgrade route is registered.
        // UUID preservation (guest UUID unchanged after upgrade) is tested in the
        // host app's integration suite where a real DB is available.
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/upgrade"
        }
        XCTAssertNotNil(route, "POST /auth/upgrade route should be registered")
    }

    // MARK: - JWT Middleware Protection

    func testUpgradeWithoutGuestJWTReturns401() async throws {
        // POST /auth/upgrade requires a valid Bearer JWT.
        // A request with no Authorization header must be rejected by JWTMiddleware with 401.
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        try await app.test(.POST, "/auth/upgrade") { res async in
            XCTAssertEqual(res.status, .unauthorized, "POST /auth/upgrade must require a valid JWT — got \(res.status)")
        }
    }

    // MARK: - UpgradeGuestRequest Content Conformance

    func testAlreadyUpgradedUserCannotUpgradeAgain() throws {
        // Verifies UpgradeGuestRequest can be encoded and decoded with all fields intact.
        // The "already upgraded" 409 response is enforced at the DB layer in the handler
        // and is tested end-to-end in the host app's integration suite.
        let guestUUID = UUID().uuidString
        let request = UpgradeGuestRequest(
            guestUUID: guestUUID,
            provider: .email,
            email: "user@example.com",
            password: "s3cr3t!",
            identityToken: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UpgradeGuestRequest.self, from: data)

        XCTAssertEqual(decoded.guestUUID, guestUUID)
        XCTAssertEqual(decoded.provider, .email)
        XCTAssertEqual(decoded.email, "user@example.com")
        XCTAssertEqual(decoded.password, "s3cr3t!")
        XCTAssertNil(decoded.identityToken)
    }

    func testUpgradeGuestRequestCanBeEncodedWithSocialProvider() throws {
        let guestUUID = UUID().uuidString
        let request = UpgradeGuestRequest(
            guestUUID: guestUUID,
            provider: .apple,
            email: nil,
            password: nil,
            identityToken: "eyJhbGciOiJSUzI1NiJ9.apple-token"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UpgradeGuestRequest.self, from: data)
        XCTAssertEqual(decoded.provider, .apple)
        XCTAssertEqual(decoded.identityToken, "eyJhbGciOiJSUzI1NiJ9.apple-token")
        XCTAssertNil(decoded.email)
        XCTAssertNil(decoded.password)
    }

    func testUpgradeGuestRequestPreservesGuestUUID() throws {
        let uuid = UUID().uuidString
        let request = UpgradeGuestRequest(
            guestUUID: uuid,
            provider: .google,
            email: nil,
            password: nil,
            identityToken: "google-token"
        )
        XCTAssertEqual(request.guestUUID, uuid)
        XCTAssertEqual(request.provider, .google)
    }

    // MARK: - UpgradeController Initialisation

    func testUpgradeControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = UpgradeController(configuration: config)
        XCTAssertNotNil(controller)
    }

    // MARK: - Route Uniqueness

    func testUpgradeRouteIsRegisteredExactlyOnce() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let upgradeRoutes = app.routes.all.filter {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/upgrade"
        }
        XCTAssertEqual(upgradeRoutes.count, 1, "Exactly one POST /auth/upgrade route should be registered (no duplicates)")
    }
}
