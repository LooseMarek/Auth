import Fluent
import Foundation

/// Fluent model representing a one-time password-reset token in the `password_reset_tokens` table.
///
/// A `PasswordResetToken` is created by `ForgotPasswordController` and consumed by
/// `ResetPasswordController`. Each token is valid for one hour (configurable via
/// `ForgotPasswordController.resetTokenTTL`) and is deleted after use or when a new
/// reset is requested for the same user.
public final class PasswordResetToken: Model, @unchecked Sendable {

    public static let schema = "password_reset_tokens"

    /// The token's unique UUID primary key.
    @ID(key: .id)
    public var id: UUID?

    /// The opaque reset token string delivered to the user via email.
    @Field(key: "token")
    public var token: String

    /// The user whose password this token authorises resetting.
    @Parent(key: "user_id")
    public var user: User

    /// The date at which this reset token expires and should be rejected.
    @Field(key: "expires_at")
    public var expiresAt: Date

    /// Required by Fluent for model hydration.
    public init() {}

    /// Creates a `PasswordResetToken` with the given token string and ownership details.
    ///
    /// - Parameters:
    ///   - id: Optional UUID. Pass `nil` to let the database generate one.
    ///   - token: The opaque reset token string (typically a UUID string).
    ///   - userID: The UUID of the user this token is for.
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

    /// Returns `true` when the token's expiry has already passed.
    public var isExpired: Bool {
        expiresAt < Date()
    }
}
