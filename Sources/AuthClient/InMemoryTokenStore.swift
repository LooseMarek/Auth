import AuthShared

/// A non-persistent, in-memory implementation of ``TokenStore``.
///
/// Stores the most recently saved ``TokenMetadata`` in a private instance variable.
/// There is no Keychain or disk I/O — all data is lost when the instance is deallocated.
///
/// Use `InMemoryTokenStore` in unit tests to avoid Keychain access and to seed
/// or inspect token state without going through the real persistence layer.
public final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var _stored: TokenMetadata?

    /// Creates an empty in-memory token store.
    public init() {}

    /// Stores `metadata` in memory, replacing any previously stored value.
    ///
    /// - Parameter metadata: The ``TokenMetadata`` to store.
    public func save(_ metadata: TokenMetadata) throws {
        _stored = metadata
    }

    /// Returns the in-memory token metadata, or `nil` when nothing has been saved.
    ///
    /// - Returns: The last value passed to `save(_:)`, or `nil`.
    public func load() throws -> TokenMetadata? {
        _stored
    }

    /// Clears the in-memory token metadata.
    public func delete() throws {
        _stored = nil
    }
}
