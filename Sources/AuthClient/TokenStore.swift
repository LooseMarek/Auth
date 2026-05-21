import AuthShared

/// A persistent store for ``TokenMetadata`` values.
///
/// Conforming types are responsible for persisting, retrieving, and deleting
/// the token metadata that `AuthManager` uses to authenticate requests and
/// perform silent token refreshes.
///
/// The production implementation is ``KeychainTokenStore``.
/// For tests, use ``InMemoryTokenStore``.
public protocol TokenStore: Sendable {
    /// Persists the given token metadata, overwriting any previously stored value.
    ///
    /// - Parameter metadata: The ``TokenMetadata`` to store.
    /// - Throws: Any error encountered during persistence (e.g. a Keychain error).
    func save(_ metadata: TokenMetadata) throws

    /// Returns the currently stored token metadata, or `nil` when none exists.
    ///
    /// - Returns: The persisted ``TokenMetadata``, or `nil` when no value has been saved.
    /// - Throws: Any error encountered during retrieval.
    func load() throws -> TokenMetadata?

    /// Removes any previously stored token metadata.
    ///
    /// Calling `delete()` when no value is stored must be a no-op (not an error).
    ///
    /// - Throws: Any error encountered during deletion.
    func delete() throws
}
