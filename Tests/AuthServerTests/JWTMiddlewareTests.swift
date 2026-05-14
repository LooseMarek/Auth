import XCTest
import XCTVapor
import JWTKit
@testable import AuthServer

final class JWTMiddlewareTests: XCTestCase {

    // MARK: - Helpers

    private func makeApp(signingSecret: String = "test-secret") async throws -> Application {
        let app = try await Application.make(.testing)
        let jwtConfig = AuthServerConfiguration(jwtSigningSecret: signingSecret)
        app.storage[AuthServerConfiguration.StorageKey.self] = jwtConfig

        // Register a protected route under the middleware
        let protected = app.grouped(JWTMiddleware(configuration: jwtConfig))
        protected.get("protected") { _ in HTTPStatus.ok }

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

    // MARK: - Tests

    func testValidTokenAllowsRequest() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let token = try await signedToken()

        try await app.test(.GET, "/protected", headers: ["Authorization": "Bearer \(token)"]) { res async in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testExpiredTokenReturns401() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let expiredToken = try await signedToken(expiration: Date().addingTimeInterval(-3600))

        try await app.test(.GET, "/protected", headers: ["Authorization": "Bearer \(expiredToken)"]) { res async in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }

    func testMissingTokenReturns401() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        try await app.test(.GET, "/protected") { res async in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }
}
