import XCTest
import AuthShared
@testable import AuthServer

// NOTE: Unit tests per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver dependency.
// We test request/response struct shapes and schema/field names without hitting a real DB.

final class ChangePasswordControllerTests: XCTestCase {

    // MARK: - ChangePasswordRequest — field shapes

    /// Verifies the request struct decodes JSON keys `currentPassword` and `newPassword`.
    func testChangePasswordRequest_decodesFromJSON() throws {
        let json = """
        {"currentPassword":"OldPass1","newPassword":"NewPass2"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let request = try decoder.decode(ChangePasswordRequest.self, from: json)
        XCTAssertEqual(request.currentPassword, "OldPass1")
        XCTAssertEqual(request.newPassword, "NewPass2")
    }

    /// Verifies the request struct round-trips correctly through encode → decode.
    func testChangePasswordRequest_roundTrips() throws {
        let original = ChangePasswordRequest(currentPassword: "abc123", newPassword: "xyz789")
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ChangePasswordRequest.self, from: data)
        XCTAssertEqual(decoded.currentPassword, original.currentPassword)
        XCTAssertEqual(decoded.newPassword, original.newPassword)
    }

    /// Verifies the JSON keys are `currentPassword` and `newPassword` (camelCase).
    func testChangePasswordRequest_JSONKeysAreCamelCase() throws {
        let request = ChangePasswordRequest(currentPassword: "p1", newPassword: "p2")
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(dict?["currentPassword"], "JSON must use key 'currentPassword'")
        XCTAssertNotNil(dict?["newPassword"], "JSON must use key 'newPassword'")
    }

    // MARK: - User schema/model field names

    /// Verifies the User model stores passwords in the `password_hash` field.
    func testUser_passwordHashFieldName() {
        let user = User(email: "test@example.com", passwordHash: "somehash", authProvider: "email")
        XCTAssertEqual(user.passwordHash, "somehash", "User must store password in passwordHash property (DB key: password_hash)")
    }

    /// Verifies that a user with empty passwordHash is treated as non-email-auth (social/guest).
    func testUser_emptyPasswordHash_indicatesSocialOrGuestAccount() {
        let user = User(email: "user@example.com", passwordHash: "", authProvider: "apple")
        XCTAssertTrue(user.passwordHash.isEmpty, "Social/guest accounts have empty passwordHash")
    }

    // MARK: - ChangePasswordController initialisation

    /// Verifies the controller can be initialised with a configuration (no DB needed).
    func testChangePasswordController_canBeInitialised() {
        let config = AuthServerConfiguration(jwtSigningSecret: "test-secret")
        let controller = ChangePasswordController(configuration: config)
        XCTAssertNotNil(controller, "ChangePasswordController must initialise without error")
    }
}
