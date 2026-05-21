import Fluent

/// Fluent migration that creates the `refresh_tokens` table.
///
/// Schema: `id` (UUID PK), `token` (unique, required), `user_id` (FK → `users.id`, cascade delete),
/// `expires_at` (required).
public struct CreateRefreshToken: AsyncMigration {

    public init() {}

    /// Creates the `refresh_tokens` table with a unique constraint on `token`
    /// and a cascading foreign key to `users`.
    ///
    /// - Parameter database: The database connection to run the schema change on.
    public func prepare(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema)
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()
    }

    /// Drops the `refresh_tokens` table, reversing the migration.
    ///
    /// - Parameter database: The database connection to run the schema change on.
    public func revert(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema).delete()
    }
}
