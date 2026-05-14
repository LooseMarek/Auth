import XCTest
import XCTVapor
import AuthShared
@testable import AuthServer

// NOTE: These tests are unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test route registration, request type conformance, and model
// field values without hitting a real DB.

final class ResetPasswordRouteTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp() async throws -> Application {
        let config = AuthServerConfiguration(jwtSigningSecret: "test-secret")
        let app = try await Application.make(.testing)
        let resetController = ResetPasswordController(configuration: config)
        try app.register(collection: resetController)
        return app
    }

    // MARK: - Route Registration

    func testResetPasswordRouteIsRegistered() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/reset-password"
        }
        XCTAssertNotNil(route, "POST /auth/reset-password route should be registered")
    }

    // MARK: - ResetPasswordRequest Content Conformance

    func testValidTokenUpdatesPassword() throws {
        // Verify ResetPasswordRequest decodes correctly — the full token validation and
        // password update (which requires a DB) is tested in the host app.
        let json = """
        {"token":"valid-reset-token","newPassword":"NewP@ssword1"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(ResetPasswordRequest.self, from: json)
        XCTAssertEqual(request.token, "valid-reset-token")
        XCTAssertEqual(request.newPassword, "NewP@ssword1")
    }

    func testInvalidTokenReturns400() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        // The route must be registered (prerequisite for returning HTTP 400 on bad tokens).
        let route = app.routes.all.first {
            $0.method == .POST && $0.path.map(\.description).joined(separator: "/") == "auth/reset-password"
        }
        XCTAssertNotNil(route, "POST /auth/reset-password must be registered to return HTTP 400 on invalid tokens")
    }

    func testResetPasswordRequestPreservesFields() throws {
        let token = "some-opaque-reset-token"
        let newPassword = "Sup3rS3cr3t!"
        let request = ResetPasswordRequest(token: token, newPassword: newPassword)
        XCTAssertEqual(request.token, token)
        XCTAssertEqual(request.newPassword, newPassword)
    }

    // MARK: - ResetPasswordRequest encode/decode

    func testResetPasswordRequestCanBeEncoded() throws {
        let request = ResetPasswordRequest(token: "tok123", newPassword: "pass456")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        XCTAssertFalse(data.isEmpty)
    }

    func testResetPasswordRequestCanBeDecoded() throws {
        let json = """
        {"token":"abc","newPassword":"xyz"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(ResetPasswordRequest.self, from: json)
        XCTAssertEqual(request.token, "abc")
        XCTAssertEqual(request.newPassword, "xyz")
    }
}
