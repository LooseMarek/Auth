import XCTest
import XCTVapor
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration and request type conformance without exercising the DB.
// Full login integration tests (with a real DB) belong in the host app's test suite.

final class LoginRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = AuthController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    // MARK: - Route Registration

    func testLoginRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let loginRoute = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/login"
        }
        XCTAssertNotNil(loginRoute, "POST /auth/login route should be registered")
    }

    // MARK: - LoginRequest Content Conformance

    func testLoginRequestCanBeEncoded() throws {
        let request = LoginRequest(email: "user@example.com", password: "secret123")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
    }

    func testLoginRequestCanBeDecoded() throws {
        let json = """
        {"email":"user@example.com","password":"secret123"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(LoginRequest.self, from: json)
        XCTAssertEqual(request.email, "user@example.com")
        XCTAssertEqual(request.password, "secret123")
    }

    func testLoginRequestPreservesEmailAndPassword() throws {
        let email = "login@domain.io"
        let password = "my-password"
        let request = LoginRequest(email: email, password: password)
        XCTAssertEqual(request.email, email)
        XCTAssertEqual(request.password, password)
    }
}
