import JWTKit

/// JWT payload used for access tokens issued by AuthServer.
public struct AuthPayload: JWTPayload, Sendable {

    /// The subject claim — typically the user's UUID string.
    public var subject: SubjectClaim

    /// The expiration claim.
    public var expiration: ExpirationClaim

    public init(subject: SubjectClaim, expiration: ExpirationClaim) {
        self.subject = subject
        self.expiration = expiration
    }

    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try expiration.verifyNotExpired()
    }
}
