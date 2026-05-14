/// A data transfer object representing an authenticated user.
public struct UserDTO: Codable, Sendable {
    /// The unique identifier of the user (UUID as string).
    public let id: String
    /// The user's email address. `nil` for guest users.
    public let email: String?
    /// The user's display name. `nil` when not set.
    public let displayName: String?

    public init(id: String, email: String?, displayName: String?) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}
