import Fluent
import Foundation

/// Fluent model representing an authenticated user account in the `users` table.
///
/// Guest users are stored as `User` records with a synthetic email
/// `guest+{UUID}@auth.internal` and an empty `passwordHash`. The synthetic
/// email satisfies the NOT NULL and UNIQUE constraints while clearly identifying
/// the row as a guest. When upgraded, the real email and password hash replace them.
public final class User: Model, @unchecked Sendable {

    public static let schema = "users"

    /// The user's unique UUID primary key.
    @ID(key: .id)
    public var id: UUID?

    /// The user's email address.
    ///
    /// Guest users have a synthetic email `guest+{UUID}@auth.internal`. This satisfies
    /// the NOT NULL and UNIQUE constraints on the `users` table while distinguishing
    /// guests from real accounts. After upgrade via `UpgradeController`, this field
    /// holds the user's real email address.
    @Field(key: "email")
    public var email: String

    /// The BCrypt hash of the user's password. Empty string for social-only or guest accounts.
    @Field(key: "password_hash")
    public var passwordHash: String

    /// The date the record was first inserted into the database.
    @Timestamp(key: "created_at", on: .create)
    public var createdAt: Date?

    /// The date the record was last updated in the database.
    @Timestamp(key: "updated_at", on: .update)
    public var updatedAt: Date?

    /// The identity provider used to create this account.
    ///
    /// One of `"email"`, `"apple"`, `"google"`, or `"guest"`. Nil for rows that
    /// pre-date the `AddAuthProviderToUser` migration (treat as `"email"`).
    @OptionalField(key: "auth_provider")
    public var authProvider: String?

    /// Required by Fluent for model hydration.
    public init() {}

    /// Creates a `User` with the given credentials.
    ///
    /// - Parameters:
    ///   - id: Optional UUID. Pass `nil` to let the database generate one.
    ///   - email: The user's email. For guests, use `User.guestEmail(for:)`.
    ///   - passwordHash: The BCrypt-hashed password. Empty string for social-only or guest users.
    ///   - authProvider: The identity provider (`"email"`, `"apple"`, `"google"`, `"guest"`).
    public init(
        id: UUID? = nil,
        email: String,
        passwordHash: String,
        authProvider: String? = nil
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.authProvider = authProvider
    }

    // MARK: - Guest helpers

    /// The domain suffix used for synthetic guest emails.
    static let guestEmailDomain = "@auth.internal"

    /// Returns the synthetic guest email for the given UUID.
    ///
    /// Format: `guest+{uuid-lowercase}@auth.internal`
    public static func guestEmail(for id: UUID) -> String {
        "guest+\(id.uuidString.lowercased())\(guestEmailDomain)"
    }

    /// Whether this user record is still an unupgraded guest.
    public var isGuest: Bool { email.hasSuffix(Self.guestEmailDomain) }
}
