import XCTest
import XCTVapor
import JWTKit
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration, JWT middleware wiring, and controller initialisation
// without hitting a real DB.

final class AccountDeletionRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = AccountDeletionController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    private func signedToken(
        secret: String = "test-secret",
        expiration: Date = Date().addingTimeInterval(3600),
        userID: UUID = UUID()
    ) async throws -> String {
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: secret), digestAlgorithm: .sha256)
        let payload = AuthPayload(
            subject: SubjectClaim(value: userID.uuidString),
            expiration: ExpirationClaim(value: expiration)
        )
        return try await keys.sign(payload)
    }

    // MARK: - Route Registration

    func testDeleteAccountRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .DELETE && $0.path.map(\.description).joined(separator: "/") == "auth/account"
        }
        XCTAssertNotNil(route, "DELETE /auth/account route should be registered")
    }

    // MARK: - JWT Middleware Protection

    func testDeleteAccountRouteRequiresJWT() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        // Missing Authorization header must return 401 (JWTMiddleware rejects the request
        // before the handler touches the DB).
        try await app.test(.DELETE, "/auth/account") { res async in
            XCTAssertEqual(res.status, .unauthorized, "DELETE /auth/account must require a valid JWT")
        }
    }

    func testDeleteAccountRouteRejectsExpiredJWT() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let expiredToken = try await signedToken(expiration: Date().addingTimeInterval(-3600))

        try await app.test(.DELETE, "/auth/account", headers: ["Authorization": "Bearer \(expiredToken)"]) { res async in
            XCTAssertEqual(res.status, .unauthorized, "DELETE /auth/account must reject expired JWTs")
        }
    }

    // MARK: - AccountDeletionController Initialisation

    func testDeleteAccountControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = AccountDeletionController(configuration: config)
        XCTAssertNotNil(controller)
    }
}
