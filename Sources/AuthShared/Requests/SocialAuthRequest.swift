/// A request to authenticate via a social identity provider (Apple or Google).
public struct SocialAuthRequest: Codable, Sendable {
    /// The identity provider for this request.
    ///
    /// Only `.apple` and `.google` are valid for social authentication.
    /// `.email` is expressible here by type but does not correspond to a social
    /// auth flow — use the dedicated email login endpoint instead.
    public let provider: AuthProvider
    /// The identity token returned by the social provider's SDK.
    public let identityToken: String

    public init(provider: AuthProvider, identityToken: String) {
        self.provider = provider
        self.identityToken = identityToken
    }
}
