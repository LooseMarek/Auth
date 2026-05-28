import XCTest
@testable import AuthClient
import AuthShared

/// Tests for token persistence: verifying that tokens written to the store can
/// be read back correctly, and that an empty store returns nil.
///
/// These tests use `InMemoryTokenStore` to exercise the `TokenStore` contract
/// without touching the Keychain (which requires entitlements).
final class TokenPersistenceServiceTests: XCTestCase {

    private var store: InMemoryTokenStore!

    override func setUp() {
        super.setUp()
        store = InMemoryTokenStore()
    }

    override func tearDown() {
        try? store.delete()
        store = nil
        super.tearDown()
    }

    // MARK: - testSaveAndLoad_roundTrip

    /// Verifies tokens written to the store can be read back correctly.
    func testSaveAndLoad_roundTrip() throws {
        // Given: a TokenMetadata with known values
        let expectedAccessToken = "round-trip.access.token"
        let expectedRefreshToken = "round-trip.refresh.token"
        let expectedExpiresAt = Date(timeIntervalSinceNow: 3600)

        let metadata = TokenMetadata(
            accessToken: expectedAccessToken,
            refreshToken: expectedRefreshToken,
            expiresAt: expectedExpiresAt
        )

        // When: the metadata is saved and loaded back
        try store.save(metadata)
        let loaded = try store.load()

        // Then: the loaded value matches what was saved
        XCTAssertNotNil(loaded, "Loaded token should not be nil after saving")
        XCTAssertEqual(loaded?.accessToken, expectedAccessToken,
                       "Access token must round-trip correctly")
        XCTAssertEqual(loaded?.refreshToken, expectedRefreshToken,
                       "Refresh token must round-trip correctly")
        XCTAssertEqual(
            loaded?.expiresAt.timeIntervalSince1970 ?? 0,
            expectedExpiresAt.timeIntervalSince1970,
            accuracy: 0.001,
            "Expiry date must round-trip correctly"
        )
    }

    // MARK: - testLoad_noStoredToken_returnsNil

    /// Verifies nil is returned when no token exists in the store.
    func testLoad_noStoredToken_returnsNil() throws {
        // Given: a fresh, empty store (setUp creates one)

        // When: load is called without any prior save
        let loaded = try store.load()

        // Then: nil is returned
        XCTAssertNil(loaded, "load() must return nil when no token has been saved")
    }
}
