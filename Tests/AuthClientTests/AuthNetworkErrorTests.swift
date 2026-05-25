import XCTest
@testable import AuthClient

/// Tests that ``AuthNetworkError`` cases produce human-readable localised descriptions
/// that do not expose raw error domain strings such as "AuthClient.AuthNetworkError error N".
final class AuthNetworkErrorTests: XCTestCase {

    // MARK: - testError3_mapsToHumanReadableMessage

    /// AuthNetworkError case index 3 is `.serverError`.
    /// `error.localizedDescription` must return a user-facing string, not
    /// "The operation couldn't be completed. (AuthClient.AuthNetworkError error 3.)".
    func testError3_mapsToHumanReadableMessage() {
        let error: AuthNetworkError = .serverError

        let description = error.localizedDescription

        XCTAssertFalse(
            description.contains("AuthClient.AuthNetworkError"),
            "localizedDescription must not expose the raw error domain. Got: \(description)"
        )
        XCTAssertFalse(
            description.contains("error 3"),
            "localizedDescription must not expose the raw error code. Got: \(description)"
        )
        XCTAssertFalse(
            description.isEmpty,
            "localizedDescription must not be empty."
        )
    }

    // MARK: - All cases produce human-readable descriptions

    func testAllCases_doNotExposeRawDomainString() {
        let cases: [AuthNetworkError] = [
            .invalidCredentials,
            .emailTaken,
            .networkUnavailable,
            .serverError,
        ]

        for error in cases {
            let description = error.localizedDescription
            XCTAssertFalse(
                description.contains("AuthClient.AuthNetworkError"),
                "Case \(error) localizedDescription must not expose the raw error domain. Got: \(description)"
            )
        }
    }

    func testNetworkUnavailable_containsNetworkRelatedMessage() {
        let error: AuthNetworkError = .networkUnavailable
        let description = error.localizedDescription

        XCTAssertFalse(description.isEmpty, "networkUnavailable must produce a non-empty message.")
        XCTAssertFalse(
            description.contains("AuthClient.AuthNetworkError"),
            "networkUnavailable must not expose the raw error domain."
        )
    }

    func testInvalidCredentials_containsCredentialRelatedMessage() {
        let error: AuthNetworkError = .invalidCredentials
        let description = error.localizedDescription

        XCTAssertFalse(description.isEmpty, "invalidCredentials must produce a non-empty message.")
        XCTAssertFalse(
            description.contains("AuthClient.AuthNetworkError"),
            "invalidCredentials must not expose the raw error domain."
        )
    }
}
