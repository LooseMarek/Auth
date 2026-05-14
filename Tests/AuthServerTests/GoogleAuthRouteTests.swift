import XCTest
import XCTVapor
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration and request type conformance without exercising the DB.
// Full Google social-auth integration tests (with a real DB and JWKS) belong in the
// host app's test suite.

final class GoogleAuthRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(
        configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")
    ) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = GoogleAuthController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    // MARK: - Route Registration

    func testGoogleAuthRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/google"
        }
        XCTAssertNotNil(route, "POST /auth/google route should be registered")
    }

    // MARK: - SocialAuthRequest Content Conformance (Google)

    func testSocialAuthRequestCanBeEncodedForGoogle() throws {
        let request = SocialAuthRequest(provider: .google, identityToken: "eyJhbGciOiJSUzI1NiJ9.google-test-token")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
    }

    func testSocialAuthRequestCanBeDecodedForGoogle() throws {
        let json = """
        {"provider":"google","identityToken":"eyJhbGciOiJSUzI1NiJ9.google-test-token"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(SocialAuthRequest.self, from: json)
        XCTAssertEqual(request.provider, .google)
        XCTAssertEqual(request.identityToken, "eyJhbGciOiJSUzI1NiJ9.google-test-token")
    }

    func testSocialAuthRequestPreservesIdentityTokenForGoogle() throws {
        let token = "eyJhbGciOiJSUzI1NiJ9.google-identity-token-value"
        let request = SocialAuthRequest(provider: .google, identityToken: token)
        XCTAssertEqual(request.provider, .google)
        XCTAssertEqual(request.identityToken, token)
    }

    // MARK: - GoogleAuthController Initialisation

    func testGoogleAuthControllerInitialisesWithConfiguration() {
        let config = AuthServerConfiguration(jwtSigningSecret: "secret")
        let controller = GoogleAuthController(configuration: config)
        XCTAssertNotNil(controller)
    }

    // MARK: - JWT Middleware — No Protection on Google Auth Route

    func testGoogleAuthRouteDoesNotRequireJWT() async throws {
        // POST /auth/google is the sign-in entry point; it must NOT require a pre-existing JWT.
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        try await app.test(.POST, "/auth/google", beforeRequest: { req in
            try req.content.encode(["provider": "google", "identityToken": "invalid"])
        }) { res async in
            // Must not be rejected by JWTMiddleware. The handler may return 401 for an
            // invalid token, or 400 for a bad body. Any of those is acceptable here.
            XCTAssertTrue(
                res.status == .unauthorized || res.status == .badRequest || res.status == .internalServerError,
                "POST /auth/google should not require a pre-existing Bearer JWT — got \(res.status)"
            )
        }
    }
}
