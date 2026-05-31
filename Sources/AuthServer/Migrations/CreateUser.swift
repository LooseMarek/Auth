import Fluent

/// Fluent migration that creates the `users` table.
///
/// Schema: `id` (UUID PK), `email` (unique, required), `password_hash` (required),
/// `auth_provider` (nullable), `created_at`, `updated_at`.
public struct CreateUser: AsyncMigration {

    public init() {}

    /// Creates the `users` table with all required columns and a unique constraint on `email`.
    ///
    /// `auth_provider` is nullable so that rows without an explicit provider value are treated
    /// as email-authenticated by convention (nil → `"email"`).
    ///
    /// - Parameter database: The database connection to run the schema change on.
    public func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("auth_provider", .string)
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
