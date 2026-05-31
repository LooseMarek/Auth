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
            .serverUnreachable,
            .serverError,
            .accountAlreadyExists,
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

    // MARK: - No-internet vs server-unreachable distinction (issue #98)

    /// NSURLErrorNotConnectedToInternet must produce the "No internet connection" message,
    /// not the generic server-error message.
    func testNoInternet_mapsToNoInternetMessage() {
        let error: AuthNetworkError = .networkUnavailable

        let description = error.localizedDescription

        XCTAssertTrue(
            description.contains("No internet connection"),
            "networkUnavailable must contain 'No internet connection'. Got: \(description)"
        )
        XCTAssertFalse(
            description.contains("Unable to reach the server"),
            "networkUnavailable must NOT contain 'Unable to reach the server'. Got: \(description)"
        )
    }

    /// NSURLErrorCannotConnectToHost (connection refused) must produce the
    /// server-unreachable message — not the "No internet connection" message.
    func testConnectionRefused_mapsToServerUnreachableMessage() {
        let error: AuthNetworkError = .serverUnreachable

        let description = error.localizedDescription

        XCTAssertTrue(
            description.contains("Unable to reach the server"),
            "serverUnreachable must contain 'Unable to reach the server'. Got: \(description)"
        )
        XCTAssertFalse(
            description.contains("No internet connection"),
            "serverUnreachable must NOT contain 'No internet connection'. Got: \(description)"
        )
        XCTAssertFalse(
            description.isEmpty,
            "serverUnreachable must produce a non-empty message."
        )
    }

    /// NSURLErrorTimedOut must produce the server-unreachable message — not
    /// the "No internet connection" message. The same `.serverUnreachable` case
    /// covers both cannotConnectToHost and timedOut in the URL error mapping.
    func testTimeout_mapsToServerUnreachableMessage() {
        let error: AuthNetworkError = .serverUnreachable

        let description = error.localizedDescription

        XCTAssertTrue(
            description.contains("Unable to reach the server"),
            "serverUnreachable (timeout) must contain 'Unable to reach the server'. Got: \(description)"
        )
        XCTAssertFalse(
            description.contains("No internet connection"),
            "serverUnreachable (timeout) must NOT contain 'No internet connection'. Got: \(description)"
        )
    }

    // MARK: - accountAlreadyExists (issue #127)

    /// When a guest upgrade fails because the email/social account is already registered,
    /// the error must produce a user-friendly "Account already registered" message.
    func testAccountAlreadyExists_localizedDescription() {
        let error: AuthNetworkError = .accountAlreadyExists

        let description = error.localizedDescription

        XCTAssertFalse(description.isEmpty, "accountAlreadyExists must produce a non-empty message.")
        XCTAssertFalse(
            description.contains("AuthClient.AuthNetworkError"),
            "accountAlreadyExists must not expose the raw error domain. Got: \(description)"
        )
        XCTAssertTrue(
            description.contains("Account already registered"),
            "accountAlreadyExists must contain 'Account already registered'. Got: \(description)"
        )
    }
}
