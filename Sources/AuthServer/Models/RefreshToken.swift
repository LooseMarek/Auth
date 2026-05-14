import Fluent
import Foundation

public final class RefreshToken: Model, @unchecked Sendable {

    public static let schema = "refresh_tokens"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "token")
    public var token: String

    @Parent(key: "user_id")
    public var user: User

    @Field(key: "expires_at")
    public var expiresAt: Date

    public init() {}

    public init(
        id: UUID? = nil,
        token: String,
        userID: UUID,
        expiresAt: Date
    ) {
        self.id = id
        self.token = token
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
}
