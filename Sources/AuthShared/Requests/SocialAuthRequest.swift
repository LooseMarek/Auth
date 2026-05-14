/// A request to authenticate via a social identity provider (Apple or Google).
public struct SocialAuthRequest: Codable, Sendable {
    /// The name of the identity provider (e.g. `"apple"` or `"google"`).
    public let provider: String
    /// The identity token returned by the social provider's SDK.
    public let identityToken: String

    public init(provider: String, identityToken: String) {
        self.provider = provider
        self.identityToken = identityToken
    }
}
