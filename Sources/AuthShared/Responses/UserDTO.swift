/// A data transfer object representing an authenticated user.
public struct UserDTO: Codable, Sendable {
    /// The unique identifier of the user (UUID as string).
    public let id: String
    /// The user's email address. `nil` for guest users.
    public let email: String?
    /// The user's display name. `nil` when not set.
    public let displayName: String?
    /// Whether this user is an anonymous guest. `false` for fully-registered users.
    ///
    /// Defaults to `false` when the key is absent from the JSON payload, ensuring
    /// backward compatibility with server responses that pre-date this field.
    public let isGuest: Bool

    /// Creates a `UserDTO` with the given identifier and optional profile fields.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the user (UUID as string).
    ///   - email: The user's email address. Pass `nil` for guest users.
    ///   - displayName: The user's display name. Pass `nil` when not set.
    ///   - isGuest: Whether this user is an anonymous guest. Defaults to `false`.
    public init(id: String, email: String?, displayName: String?, isGuest: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isGuest = isGuest
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, email, displayName, isGuest
    }

    /// Custom decoder that defaults `isGuest` to `false` when the key is absent.
    ///
    /// This preserves backward compatibility with existing server responses that do not
    /// yet include the `isGuest` field.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        isGuest = try container.decodeIfPresent(Bool.self, forKey: .isGuest) ?? false
    }
}
