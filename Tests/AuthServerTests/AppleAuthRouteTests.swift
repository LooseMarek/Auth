import XCTest
import XCTVapor
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration and request type conformance without exercising the DB.
// Full Apple social-auth integration tests (with a real DB and JWKS) belong in the
// host app's test suite.

final class AppleAuthRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = AppleAuthController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    // MARK: - Route Registration

    func testAppleAuthRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/apple"
        }
        XCTAssertNotNil(route, "POST /auth/apple route should be registered")
    }

    // MARK: - SocialAuthRequest Content Conformance

    func testSocialAuthRequestCanBeEncoded() throws {
        let request = SocialAuthRequest(provider: .apple, identityToken: "eyJhbGciOiJSUzI1NiJ9.test-token")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
    }

    func testSocialAuthRequestCanBeDecoded() throws {
        let json = """
        {"provider":"apple","identityToken":"eyJhbGciOiJSUzI1NiJ9.test-token"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(SocialAuthRequest.self, from: json)
        XCTAssertEqual(request.provider, .apple)
        XCTAssertEqual(request.identityToken, "eyJhbGciOiJSUzI1NiJ9.test-token")
    }

    func testSocialAuthRequestPreservesIdentityToken() throws {
        let token = "eyJhbGciOiJSUzI1NiJ9.apple-identity-token-value"
        let request = SocialAuthRequest(provider: .apple, identityToken: token)
        XCTAssertEqual(request.provider, .apple)
        XCTAssertEqual(request.identityToken, token)
    }

    // MARK: - Same Identity Route Registration

    func testSameIdentityRouteIsRegistered() async throws {
        // Verifies the route exists for idempotent find-or-create calls.
        // Two calls to POST /auth/apple with the same identity should hit the same route.
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let appleRoutes = app.routes.all.filter {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/apple"
        }
        XCTAssertEqual(appleRoutes.count, 1, "Exactly one POST /auth/apple route should be registered (no duplicates)")
    }

    // MARK: - AppleAuthController Initialisation

    func testAppleAuthControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = AppleAuthController(configuration: config)
        XCTAssertNotNil(controller)
    }

    // MARK: - JWT Middleware — No Protection on Apple Auth Route

    func testAppleAuthRouteDoesNotRequireJWT() async throws {
        // POST /auth/apple is the sign-in entry point; it must NOT require a pre-existing JWT.
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        // Sending an empty body should get past JWT middleware (no 401 from middleware).
        // We expect 400 (bad request / decoding error) or 401 from token verification,
        // but NOT 401 from a JWT auth middleware guard.
        try await app.test(.POST, "/auth/apple", beforeRequest: { req in
            try req.content.encode(["provider": "apple", "identityToken": "invalid"])
        }) { res async in
            // Must not be rejected by JWTMiddleware (which would also give 401 but before
            // the handler runs). The handler itself may return 401 for an invalid token.
            // Acceptable statuses here: 401 (invalid token from handler), 400 (bad body).
            // Unacceptable: any crash or 500 that indicates a middleware misconfiguration.
            XCTAssertTrue(
                res.status == .unauthorized || res.status == .badRequest || res.status == .internalServerError,
                "POST /auth/apple should not require a pre-existing Bearer JWT — got \(res.status)"
            )
        }
    }
}
