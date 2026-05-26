import Fluent

/// Adds the `auth_provider` column to the `users` table.
///
/// Nullable so existing rows are unaffected; code treats nil as `"email"` for
/// backward compatibility.
public struct AddAuthProviderToUser: AsyncMigration {

    public init() {}

    public func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("auth_provider", .string)
            .update()
    }

    public func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .deleteField("auth_provider")
            .update()
    }
}
