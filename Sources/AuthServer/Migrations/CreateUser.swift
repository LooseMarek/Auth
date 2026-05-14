import Fluent

public struct CreateUser: AsyncMigration {

    public init() {}

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

    public func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
