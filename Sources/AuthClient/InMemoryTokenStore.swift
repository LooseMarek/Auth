import AuthShared

public final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private var _stored: TokenMetadata?

    public init() {}

    public func save(_ metadata: TokenMetadata) throws {
        _stored = metadata
    }

    public func load() throws -> TokenMetadata? {
        _stored
    }

    public func delete() throws {
        _stored = nil
    }
}
