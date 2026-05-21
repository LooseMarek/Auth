import JWTKit

/// JWT payload used for access tokens issued by AuthServer.
public struct AuthPayload: JWTPayload, Sendable {

    /// The subject claim (`sub`) — the authenticated user's UUID string.
    public var subject: SubjectClaim

    /// The expiration claim (`exp`) — the date after which the token must be rejected.
    public var expiration: ExpirationClaim

    public init(subject: SubjectClaim, expiration: ExpirationClaim) {
        self.subject = subject
        self.expiration = expiration
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
