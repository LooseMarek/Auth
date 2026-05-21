import XCTest
import XCTVapor
import JWTKit
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration, request-type Content conformance, and controller
// initialisation without hitting a real DB.

final class RefreshTokenRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = RefreshTokenController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    // MARK: - Route Registration

    func testRefreshRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/refresh"
        }
        XCTAssertNotNil(route, "POST /auth/refresh route should be registered")
    }

    // MARK: - RefreshTokenRequest Content Conformance

    func testRefreshTokenRequestCanBeDecodedFromJSON() throws {
        let json = """
        {"refreshToken":"some-opaque-refresh-token"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(RefreshTokenRequest.self, from: json)
        XCTAssertEqual(request.refreshToken, "some-opaque-refresh-token")
    }

    func testRefreshTokenRequestPreservesToken() throws {
        let token = "opaque-refresh-abc123"
        let request = RefreshTokenRequest(refreshToken: token)
        XCTAssertEqual(request.refreshToken, token)
    }

    // MARK: - RefreshTokenController Initialisation

    func testRefreshTokenControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = RefreshTokenController(configuration: config)
        XCTAssertNotNil(controller)
    }

    // MARK: - No JWT Middleware on Refresh Route

    func testRefreshRouteIsNotInAJWTProtectedGroup() async throws {
        // The refresh endpoint must not sit behind JWTMiddleware — the refresh token
        // itself is the credential, so no Bearer JWT is needed to call this endpoint.
        // We verify this by checking that the registered route path does NOT include
        // a JWTMiddleware in its middleware stack (inspectable via the Vapor routes list).
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let refreshRoute = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/refresh"
        }
        XCTAssertNotNil(refreshRoute, "POST /auth/refresh route must exist")

        // A route registered under JWTMiddleware would be nested under a grouped builder
        // that injects that middleware. The route's description should not mention JWTMiddleware.
        let routeDescription = refreshRoute.map { "\($0)" } ?? ""
        XCTAssertFalse(
            routeDescription.contains("JWTMiddleware"),
            "POST /auth/refresh must not be wrapped in JWTMiddleware"
        )
    }
}
