/// A request to attach credentials to an existing guest session, preserving the guest UUID.
///
/// Exactly one of the credential groups should be supplied:
/// - Email upgrade: provide `email` and `password`; set `identityToken` to `nil`
/// - Social upgrade: provide `provider` and `identityToken`; `email` and `password` may be `nil`
public struct UpgradeGuestRequest: Codable, Sendable {
    /// The UUID of the existing guest session to upgrade.
    public let guestUUID: String
    /// The identity provider being attached (e.g. `"email"`, `"apple"`, `"google"`).
    public let provider: String
    /// The user's email address (required for email upgrades).
    public let email: String?
    /// The user's password (required for email upgrades).
    public let password: String?
    /// The identity token returned by a social provider's SDK (required for social upgrades).
    public let identityToken: String?

    public init(
        guestUUID: String,
        provider: String,
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
