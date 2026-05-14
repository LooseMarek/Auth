import Fluent

public struct CreateRefreshToken: AsyncMigration {

    public init() {}

    public func prepare(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema)
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
            .field("expires_at", .datetime, .required)
            .unique(on: "token")
            .create()
    }

    public func revert(on database: any Database) async throws {
        try await database.schema(RefreshToken.schema).delete()
    }
}
