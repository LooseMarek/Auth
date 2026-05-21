import Fluent

/// Fluent migration that creates the `users` table.
///
/// Schema: `id` (UUID PK), `email` (unique, required), `password_hash` (required),
/// `created_at`, `updated_at`.
public struct CreateUser: AsyncMigration {

    public init() {}

    /// Creates the `users` table with all required columns and a unique constraint on `email`.
    ///
    /// - Parameter database: The database connection to run the schema change on.
    public func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "email")
            .create()
    }

    /// Drops the `users` table, reversing the migration.
    ///
    /// - Parameter database: The database connection to run the schema change on.
    public func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
