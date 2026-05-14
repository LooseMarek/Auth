import AuthShared

public protocol TokenStore: Sendable {
    func save(_ metadata: TokenMetadata) throws
    func load() throws -> TokenMetadata?
    func delete() throws
}
