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

    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

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
