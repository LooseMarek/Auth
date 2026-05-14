import Fluent
import Foundation

public final class PasswordResetToken: Model, @unchecked Sendable {

    public static let schema = "password_reset_tokens"

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

    /// Returns `true` when the token's expiry has already passed.
    public var isExpired: Bool {
        expiresAt < Date()
    }
}
