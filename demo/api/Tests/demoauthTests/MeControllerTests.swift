@testable import demoauth
import AuthServer
import FluentSQLiteDriver
import JWTKit
import VaporTesting
import Testing
import Vapor

/// Tests verifying the `GET /me` endpoint behaviour.
@Suite("MeController Tests", .serialized)
struct MeControllerTests {

    // MARK: - Helpers

    /// Signs a JWT for the given userID using the demo's test secret.
    private func makeAccessToken(for userID: UUID) async throws -> String {
        let secret = "demo-secret-change-in-production"
        let expiresAt = Date().addingTimeInterval(3600)
        let payload = AuthPayload(
            subject: SubjectClaim(value: userID.uuidString),
            expiration: ExpirationClaim(value: expiresAt)
        )
        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: secret), digestAlgorithm: .sha256)
        return try await keys.sign(payload)
    }

    // MARK: - testMeReturnsCorrectUserFields

    @Test("GET /me returns 200 with all seven fields correctly mapped")
    func testMeReturnsCorrectUserFields() async throws {
        try await withConfiguredApp { app in
            // Arrange: create a user and a refresh token
            let userID = UUID()
            let user = User(id: userID, email: "me@example.com", passwordHash: "hash")
            try await user.save(on: app.db)

            let refreshTokenID = UUID()
            let refreshToken = RefreshToken(
                id: refreshTokenID,
                token: UUID().uuidString,
                userID: userID,
                expiresAt: Date().addingTimeInterval(86400)
            )
            try await refreshToken.save(on: app.db)

            let accessToken = try await makeAccessToken(for: userID)

            // Act: call GET /me with the Bearer token
            try await app.testing().test(
                .GET,
                "me",
                headers: HTTPHeaders([("Authorization", "Bearer \(accessToken)")]),
                afterResponse: { res async in
                    // Assert: 200 response
                    #expect(res.status == .ok)

                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    guard let body = try? decoder.decode(MeResponse.self, from: Data(buffer: res.body)) else {
                        Issue.record("Failed to decode MeResponse from response body")
                        return
                    }

                    #expect(body.id == userID, "id should match the user's UUID")
                    #expect(body.email == "me@example.com", "email should match the user's email")
                    #expect(body.authProvider == "email", "authProvider should be 'email' for a non-guest user")
                    #expect(body.isGuest == false, "isGuest should be false for a non-guest user")
                    #expect(body.refreshTokenId == refreshTokenID, "refreshTokenId should match the persisted refresh token")
                    #expect(body.accessTokenExpiry > Date(timeIntervalSince1970: 0), "accessTokenExpiry should be a future date")
                    #expect(body.createdAt > Date(timeIntervalSince1970: 0), "createdAt should be a non-zero date")
                }
            )
        }
    }

    // MARK: - testMeRequiresAuthentication

    @Test("GET /me returns 401 when no Authorization header is present")
    func testMeRequiresAuthentication() async throws {
        try await withConfiguredApp { app in
            try await app.testing().test(
                .GET,
                "me",
                afterResponse: { res async in
                    #expect(res.status == .unauthorized)
                }
            )
        }
    }
}
