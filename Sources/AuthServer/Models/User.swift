import Fluent
import Foundation

/// Fluent model representing an authenticated user account in the `users` table.
///
/// A `User` is created by any registration or social sign-in flow. Guest users are
/// also stored as `User` records with an empty `email` and `passwordHash` until they
/// are upgraded via `UpgradeController`.
public final class User: Model, @unchecked Sendable {

    public static let schema = "users"

    /// The user's unique UUID primary key.
    @ID(key: .id)
    public var id: UUID?

    /// The user's email address. Empty string for guest users before upgrade.
    @Field(key: "email")
    public var email: String

    /// The BCrypt hash of the user's password. Empty string for social-only accounts.
    @Field(key: "password_hash")
    public var passwordHash: String

    /// The date the record was first inserted into the database.
    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    /// The date the record was last updated in the database.
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    /// Required by Fluent for model hydration.
    public init() {}

    /// Creates a `User` with the given credentials.
    ///
    /// - Parameters:
    ///   - id: Optional UUID. Pass `nil` to let the database generate one.
    ///   - email: The user's email address. Pass an empty string for guest users.
    ///   - passwordHash: The BCrypt-hashed password. Pass an empty string for social-only or guest users.
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
