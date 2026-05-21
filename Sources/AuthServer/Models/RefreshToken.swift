import Fluent
import Foundation

/// Fluent model representing a persisted refresh token in the `refresh_tokens` table.
///
/// Each successful authentication issues one `RefreshToken`. It is stored server-side
/// so the server can invalidate sessions (logout, account deletion). Tokens are deleted
/// on logout or when they are exchanged for a new access token.
public final class RefreshToken: Model, @unchecked Sendable {

    public static let schema = "refresh_tokens"

    /// The token's unique UUID primary key.
    @ID(key: .id)
    public var id: UUID?

    /// The opaque token string (UUID-based) presented by the client to obtain new access tokens.
    @Field(key: "token")
    public var token: String

    /// The user this refresh token belongs to. Deleting the user cascades to this record.
    @Parent(key: "user_id")
    public var user: User

    /// The date at which this refresh token expires and should be rejected.
    @Field(key: "expires_at")
    public var expiresAt: Date

    /// Required by Fluent for model hydration.
    public init() {}

    /// Creates a `RefreshToken` with the given token string and ownership details.
    ///
    /// - Parameters:
    ///   - id: Optional UUID. Pass `nil` to let the database generate one.
    ///   - token: The opaque refresh token string (typically a UUID string).
    ///   - userID: The UUID of the user this token belongs to.
    ///   - expiresAt: The date at which this token expires.
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
