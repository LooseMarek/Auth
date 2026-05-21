/// A request to attach credentials to an existing guest session, preserving the guest UUID.
///
/// Exactly one of the credential groups should be supplied:
/// - Email upgrade: provide `email` and `password`; set `identityToken` to `nil`
/// - Social upgrade: provide `provider` and `identityToken`; `email` and `password` may be `nil`
public struct UpgradeGuestRequest: Codable, Sendable {
    /// The UUID of the existing guest session to upgrade.
    public let guestUUID: String
    /// The identity provider being attached. Use `AuthProvider.email`, `.apple`, or `.google`.
    public let provider: AuthProvider
    /// The user's email address (required for email upgrades).
    public let email: String?
    /// The user's password (required for email upgrades).
    public let password: String?
    /// The identity token returned by a social provider's SDK (required for social upgrades).
    public let identityToken: String?

    /// Creates a guest-upgrade request.
    ///
    /// Supply exactly one credential group:
    /// - For an email upgrade: provide `email` and `password`; set `identityToken` to `nil`.
    /// - For a social upgrade: provide `provider` and `identityToken`; `email` and `password` may be `nil`.
    ///
    /// - Parameters:
    ///   - guestUUID: The UUID of the existing guest session to upgrade.
    ///   - provider: The identity provider being attached.
    ///   - email: The email address for the new credentials (required for email upgrades).
    ///   - password: The plaintext password (required for email upgrades; hashed server-side).
    ///   - identityToken: The JWT identity token from the social provider's SDK (required for social upgrades).
    public init(
        guestUUID: String,
        provider: AuthProvider,
        email: String?,
        password: String?,
        identityToken: String?
    ) {
        self.guestUUID = guestUUID
        self.provider = provider
        self.email = email
        self.password = password
        self.identityToken = identityToken
    }
}
