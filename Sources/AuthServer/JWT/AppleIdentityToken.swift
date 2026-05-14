import JWTKit

/// JWT payload for an Apple identity token returned by Sign in with Apple.
///
/// Apple's token contains at minimum a stable `sub` claim (the user's unique Apple ID)
/// and an optional `email` claim (present only on the first sign-in).
public struct AppleIdentityToken: JWTPayload, Sendable {

    public var subject: SubjectClaim
    public var expiration: ExpirationClaim
    public var email: String?

    private enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case email
    }

    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}
