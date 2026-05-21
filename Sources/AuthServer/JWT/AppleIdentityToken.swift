import JWTKit

/// JWT payload for an Apple identity token returned by Sign in with Apple.
///
/// Apple's token contains at minimum a stable `sub` claim (the user's unique Apple ID)
/// and an optional `email` claim (present only on the first sign-in).
public struct AppleIdentityToken: JWTPayload, Sendable {

    /// The subject claim (`sub`) — the user's stable Apple ID, unique per developer team.
    public var subject: SubjectClaim

    /// The expiration claim (`exp`) — the date after which the token must be rejected.
    public var expiration: ExpirationClaim

    /// The user's email address. Apple only includes this on the very first Sign in with
    /// Apple for a given user/app pair; subsequent sign-ins omit it.
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
