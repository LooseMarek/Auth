import Foundation
@testable import AuthClient
import AuthShared

/// A test double for ``TokenStore`` that tracks guest refresh token operations.
///
/// Unlike ``InMemoryTokenStore``, this mock exposes `savedGuestRefreshToken` so tests
/// can assert that ``AuthManager`` correctly persists and clears the guest token slot
/// on guest logout, new guest creation, and account deletion.
final class MockTokenStore: TokenStore, @unchecked Sendable {

    // MARK: - Main token store

    private var _stored: TokenMetadata?

    func save(_ metadata: TokenMetadata) throws {
        _stored = metadata
    }

    func load() throws -> TokenMetadata? {
        _stored
    }

    func delete() throws {
        _stored = nil
    }

    // MARK: - Guest refresh token slot

    /// Mirrors the value that AuthManager writes via saveGuestRefreshToken(_:).
    /// Tests set this directly to pre-seed a saved guest token.
    var savedGuestRefreshToken: String?
}

// MARK: - GuestTokenStore conformance

extension MockTokenStore: GuestTokenStore {

    func saveGuestRefreshToken(_ token: String) {
        savedGuestRefreshToken = token
    }

    func loadGuestRefreshToken() -> String? {
        savedGuestRefreshToken
    }

    func deleteGuestRefreshToken() {
        savedGuestRefreshToken = nil
    }
}
