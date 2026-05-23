@testable import demoauth
import Foundation
import Testing
import Vapor

/// Tests verifying that `MeResponse` encodes correctly to JSON with all required keys.
@Suite("MeResponse Tests", .serialized)
struct MeResponseTests {

    // MARK: - JSON encoding

    @Test("MeResponse encodes all required fields to JSON")
    func testMeResponseEncodesAllFields() throws {
        let id = UUID()
        let refreshTokenId = UUID()
        let now = Date()
        let expiry = now.addingTimeInterval(3600)

        let response = MeResponse(
            id: id,
            email: "test@example.com",
            authProvider: "email",
            createdAt: now,
            isGuest: false,
            accessTokenExpiry: expiry,
            refreshTokenId: refreshTokenId
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil, "Encoded data should be a valid JSON object")
        #expect(json?["id"] as? String == id.uuidString, "id should be the UUID string")
        #expect(json?["email"] as? String == "test@example.com", "email should be present")
        #expect(json?["authProvider"] as? String == "email", "authProvider should be present")
        #expect(json?["isGuest"] as? Bool == false, "isGuest should be present")
        #expect(json?["refreshTokenId"] as? String == refreshTokenId.uuidString, "refreshTokenId should be the UUID string")

        // Verify createdAt and accessTokenExpiry keys are present (ISO 8601 strings)
        #expect(json?["createdAt"] != nil, "createdAt should be present")
        #expect(json?["accessTokenExpiry"] != nil, "accessTokenExpiry should be present")
    }
}
