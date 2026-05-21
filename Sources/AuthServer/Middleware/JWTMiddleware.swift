import JWTKit
import Vapor

/// Vapor middleware that validates a Bearer JWT on every protected request.
///
/// Attach this middleware to a route group to require a valid, non-expired JWT:
/// ```swift
/// let protected = app.grouped(JWTMiddleware(configuration: config))
/// protected.get("profile") { req in ... }
/// ```
///
/// Returns HTTP 401 when:
/// - The `Authorization` header is missing or malformed (not `Bearer <token>`)
/// - The token signature is invalid
/// - The token has expired
public struct JWTMiddleware: AsyncMiddleware, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the middleware with the shared `AuthServerConfiguration` used to verify JWT signatures.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Verifies the Bearer JWT on the incoming request before forwarding it to the next responder.
    ///
    /// - Throws: `Abort(.unauthorized)` when the `Authorization` header is missing, the token
    ///   signature is invalid, or the token has expired.
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard
            let bearerHeader = request.headers.bearerAuthorization
        else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization header")
        }

        let keys = JWTKeyCollection()
        await keys.add(
            hmac: HMACKey(from: configuration.jwtSigningSecret),
            digestAlgorithm: .sha256
        )

        do {
            _ = try await keys.verify(bearerHeader.token, as: AuthPayload.self)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }

        return try await next.respond(to: request)
    }
}
