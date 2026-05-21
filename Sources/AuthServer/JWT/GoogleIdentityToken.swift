import JWTKit

/// JWT payload for a Google identity token (ID token) returned by Google Sign-In.
///
/// Google's token contains a stable `sub` claim (the user's Google account ID)
/// and typically an `email` claim.
public struct GoogleIdentityToken: JWTPayload, Sendable {

    /// The subject claim (`sub`) — the user's stable Google account ID.
    public var subject: SubjectClaim

    /// The expiration claim (`exp`) — the date after which the token must be rejected.
    public var expiration: ExpirationClaim

    /// The user's email address. Google typically includes this for all sign-in flows,
    /// but it may be absent for accounts with strict privacy settings.
    public var email: String?

    private enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case email
    }

    /// Verifies the payload by checking that the expiration claim has not passed.
    ///
    /// Called automatically by `JWTKeyCollection.verify(_:as:)`.
    ///
    /// - Throws: `JWTError` when the token has expired.
    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}
