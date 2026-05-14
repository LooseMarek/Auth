import XCTest
import XCTVapor
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration and request type conformance without exercising the DB.
// Full register/login integration tests (with a real DB) belong in the host app's test suite.

final class RegisterRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(configuration: AuthServerConfiguration = .init(jwtSigningSecret: "test-secret")) async throws -> Application {
        let app = try await Application.make(.testing)
        let controller = AuthController(configuration: configuration)
        try app.register(collection: controller)
        return app
    }

    // MARK: - Route Registration

    func testRegisterRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let registerRoute = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/register"
        }
        XCTAssertNotNil(registerRoute, "POST /auth/register route should be registered")
    }

    // MARK: - RegisterRequest Content Conformance

    func testRegisterRequestCanBeEncoded() throws {
        let request = RegisterRequest(email: "user@example.com", password: "secret123")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
    }

    func testRegisterRequestCanBeDecoded() throws {
        let json = """
        {"email":"user@example.com","password":"secret123"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(RegisterRequest.self, from: json)
        XCTAssertEqual(request.email, "user@example.com")
        XCTAssertEqual(request.password, "secret123")
    }

    func testRegisterRequestPreservesEmailAndPassword() throws {
        let email = "test@domain.io"
        let password = "p@ssw0rd!"
        let request = RegisterRequest(email: email, password: password)
        XCTAssertEqual(request.email, email)
        XCTAssertEqual(request.password, password)
    }
}
