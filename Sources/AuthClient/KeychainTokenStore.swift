import Foundation
import Security
import AuthShared

/// Persists and retrieves ``TokenMetadata`` in the system Keychain using
/// `Security.framework` directly — no third-party wrapper.
///
/// Each instance is scoped to a unique `service` identifier so multiple
/// apps or test runs can coexist without collisions.
public struct KeychainTokenStore: Sendable {

    // MARK: - Properties

    /// The Keychain service identifier used to namespace all items.
    private let service: String

    /// The fixed account key under which the encoded token blob is stored.
    private static let account = "auth.token-metadata"

    // MARK: - Init

    /// Creates a store scoped to the given service identifier.
    ///
    /// - Parameter service: A reverse-DNS-style string that namespaces the
    ///   Keychain item, e.g. `"com.myapp.auth"`. Defaults to a sensible
    ///   package-level identifier.
    public init(service: String = "com.auth.token-store") {
        self.service = service
    }

    // MARK: - Public API

    /// Encodes `metadata` and writes it to the Keychain.
    ///
    /// If an item already exists for this service it is updated in place;
    /// otherwise a new item is added.
    ///
    /// - Parameter metadata: The ``TokenMetadata`` value to persist.
    /// - Throws: ``KeychainError`` if the Security framework returns an error.
    public func save(_ metadata: TokenMetadata) throws {
        let data = try encode(metadata)

        if try exists() {
            try update(data: data)
        } else {
            try add(data: data)
        }
    }

    /// Loads and decodes ``TokenMetadata`` from the Keychain.
    ///
    /// - Returns: The saved ``TokenMetadata``, or `nil` when no item exists.
    /// - Throws: ``KeychainError`` if the Security framework returns an error
    ///   other than `errSecItemNotFound`, or if decoding fails.
    public func load() throws -> TokenMetadata? {
        let query = baseQuery().merging([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]) { _, new in new }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.unexpectedData
            }
            return try decode(data)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.securityError(status)
        }
    }

    /// Removes the stored ``TokenMetadata`` item from the Keychain.
    ///
    /// Calling `delete` when no item exists is a no-op (not an error).
    ///
    /// - Throws: ``KeychainError`` if the Security framework returns an error
    ///   other than `errSecItemNotFound`.
    public func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.securityError(status)
        }
    }

    // MARK: - Private Helpers

    /// Returns the base query dictionary shared by all Keychain operations.
    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: Self.account,
        ]
    }

    /// Returns `true` when an item already exists in the Keychain.
    private func exists() throws -> Bool {
        let query = baseQuery().merging([
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]) { _, new in new }

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw KeychainError.securityError(status)
        }
    }

    /// Adds a new Keychain item with the encoded `data`.
    private func add(data: Data) throws {
        let attributes = baseQuery().merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]) { _, new in new }

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.securityError(status)
        }
    }

    /// Updates the existing Keychain item with the encoded `data`.
    private func update(data: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]
        let status = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.securityError(status)
        }
    }

    /// Encodes `metadata` to `Data` using `JSONEncoder`.
    private func encode(_ metadata: TokenMetadata) throws -> Data {
        try JSONEncoder().encode(metadata)
    }

    /// Decodes `TokenMetadata` from raw `Data` using `JSONDecoder`.
    private func decode(_ data: Data) throws -> TokenMetadata {
        try JSONDecoder().decode(TokenMetadata.self, from: data)
    }
}

// MARK: - KeychainError

/// Errors that `KeychainTokenStore` operations can throw.
public enum KeychainError: Error, Sendable {
    /// The Security framework returned an unexpected status code.
    case securityError(OSStatus)
    /// The data returned by the Keychain could not be interpreted.
    case unexpectedData
}
