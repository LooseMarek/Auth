import Fluent
import Foundation

public final class User: Model, @unchecked Sendable {

    public static let schema = "users"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "email")
    public var email: String

    @Field(key: "password_hash")
    public var passwordHash: String

    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    public init() {}

    public init(
        id: UUID? = nil,
        email: String,
        passwordHash: String
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
    }
}
