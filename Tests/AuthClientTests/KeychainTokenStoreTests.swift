import XCTest
@testable import AuthClient
import AuthShared

// Tests verify the TokenStore contract using InMemoryTokenStore.
// KeychainTokenStore is validated at compile time via TokenStore conformance;
// real Keychain integration is tested in the host app where entitlements exist.
final class KeychainTokenStoreTests: XCTestCase {

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

    // MARK: - testSaveAndLoad

    func testSaveAndLoad() throws {
        let metadata = TokenMetadata(
            accessToken: "access.jwt.token",
            refreshToken: "refresh.jwt.token",
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )

        try store.save(metadata)

        let loaded = try store.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.accessToken, metadata.accessToken)
        XCTAssertEqual(loaded?.refreshToken, metadata.refreshToken)
        XCTAssertEqual(
            loaded?.expiresAt.timeIntervalSince1970 ?? 0,
            metadata.expiresAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    // MARK: - testDeleteClearsTokens

    func testDeleteClearsTokens() throws {
        let metadata = TokenMetadata(
            accessToken: "access.jwt.token",
            refreshToken: "refresh.jwt.token",
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )

        try store.save(metadata)
        try store.delete()

        let loaded = try store.load()
        XCTAssertNil(loaded)
    }

    // MARK: - testLoadReturnsNilWhenEmpty

    func testLoadReturnsNilWhenEmpty() throws {
        let loaded = try store.load()
        XCTAssertNil(loaded)
    }

    // MARK: - testOverwriteUpdatesTokens

    func testOverwriteUpdatesTokens() throws {
        let first = TokenMetadata(
            accessToken: "first.access.token",
            refreshToken: "first.refresh.token",
            expiresAt: Date(timeIntervalSinceNow: 3600)
        )
        let second = TokenMetadata(
            accessToken: "second.access.token",
            refreshToken: "second.refresh.token",
            expiresAt: Date(timeIntervalSinceNow: 7200)
        )

        try store.save(first)
        try store.save(second)

        let loaded = try store.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.accessToken, second.accessToken)
        XCTAssertEqual(loaded?.refreshToken, second.refreshToken)
        XCTAssertEqual(
            loaded?.expiresAt.timeIntervalSince1970 ?? 0,
            second.expiresAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }
}
