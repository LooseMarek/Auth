import JWTKit

/// JWT payload for a Google identity token (ID token) returned by Google Sign-In.
///
/// Google's token contains a stable `sub` claim (the user's Google account ID)
/// and typically an `email` claim.
public struct GoogleIdentityToken: JWTPayload, Sendable {

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
