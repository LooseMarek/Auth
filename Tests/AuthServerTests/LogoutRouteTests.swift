import XCTest
import XCTVapor
import JWTKit
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration, JWT middleware wiring, and request type conformance
// without hitting a real DB.

final class LogoutRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = LogoutController(configuration: configuration)
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

    func testLogoutRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/logout"
        }
        XCTAssertNotNil(route, "POST /auth/logout route should be registered")
    }

    // MARK: - JWT Middleware Protection

    func testLogoutRouteRequiresJWT() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        // Missing Authorization header must return 401 (JWTMiddleware rejects the request
        // before the handler touches the DB).
        try await app.test(.POST, "/auth/logout") { res async in
            XCTAssertEqual(res.status, .unauthorized, "POST /auth/logout must require a valid JWT")
        }
    }

    // MARK: - LogoutRequest Content Conformance

    func testLogoutRequestCanBeDecodedFromJSON() throws {
        let json = """
        {"refreshToken":"some-opaque-token-value"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(LogoutRequest.self, from: json)
        XCTAssertEqual(request.refreshToken, "some-opaque-token-value")
    }

    func testLogoutRequestPreservesRefreshToken() throws {
        let token = "my-refresh-token-abc123"
        let request = LogoutRequest(refreshToken: token)
        XCTAssertEqual(request.refreshToken, token)
    }

    // MARK: - LogoutController Initialisation

    func testLogoutControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = LogoutController(configuration: config)
        XCTAssertNotNil(controller)
    }
}
