import Vapor
import Fluent
import JWTKit

/// Vapor `RouteCollection` that handles account deletion.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: AccountDeletionController(configuration: config))
/// ```
///
/// This registers:
/// - `DELETE /auth/account` — deletes the authenticated user and all their refresh tokens;
///   requires a valid JWT
public struct AccountDeletionController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `DELETE /auth/account` route under the JWT-protected route group.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let protected = auth.grouped(JWTMiddleware(configuration: configuration))
        protected.delete("account", use: deleteAccount)
    }

    // MARK: - Delete Account

    /// Deletes the authenticated user and all of their associated refresh tokens.
    ///
    /// The user ID is extracted from the `sub` claim of the validated Bearer JWT.
    /// All `RefreshToken` records belonging to that user are deleted before the
    /// `User` record itself is removed.
    ///
    /// - Throws: `Abort(.unauthorized)` when the JWT subject cannot be parsed as a UUID.
    /// - Throws: `Abort(.notFound)` when no user with the derived ID exists in the DB.
    /// - Returns: HTTP 204 No Content on success.
    @Sendable
    func deleteAccount(req: Request) async throws -> Response {
        // Extract the user UUID from the verified JWT subject claim.
        guard
            let bearerHeader = req.headers.bearerAuthorization
        else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization header")
        }

        let keys = JWTKeyCollection()
        await keys.add(
            hmac: HMACKey(from: configuration.jwtSigningSecret),
            digestAlgorithm: .sha256
        )
        let payload = try await keys.verify(bearerHeader.token, as: AuthPayload.self)

        guard let userID = UUID(uuidString: payload.subject.value) else {
            throw Abort(.unauthorized, reason: "Invalid user identifier in token")
        }

        // Delete all refresh tokens for this user first.
        try await RefreshToken.query(on: req.db)
            .filter(\.$user.$id == userID)
            .delete()

        // Delete the user record.
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        try await user.delete(on: req.db)

        return Response(status: .noContent)
    }
}
