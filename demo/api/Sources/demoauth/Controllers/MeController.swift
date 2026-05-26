import AuthServer
import Fluent
import JWTKit
import Vapor

/// Vapor `RouteCollection` that handles the authenticated profile endpoint.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: MeController(configuration: config))
/// ```
///
/// This registers:
/// - `GET /me` — returns `MeResponse` for the authenticated user (requires valid Bearer JWT)
struct MeController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the controller with the shared `AuthServerConfiguration`.
    init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `GET /me` route behind `JWTMiddleware`.
    func boot(routes: any RoutesBuilder) throws {
        let protected = routes.grouped(JWTMiddleware(configuration: configuration))
        protected.get("me", use: me)
    }

    // MARK: - Me

    /// Returns the authenticated user's profile and token debug information.
    ///
    /// Parses the Bearer JWT from the request, looks up the `User` in the database,
    /// and returns a `MeResponse` containing profile details and token metadata.
    ///
    /// - Throws: `Abort(.unauthorized)` when the JWT is missing or invalid (handled by `JWTMiddleware`).
    /// - Throws: `Abort(.internalServerError)` when the user record or refresh token cannot be found.
    /// - Returns: `MeResponse` with all seven profile and token debug fields.
    @Sendable
    func me(req: Request) async throws -> MeResponse {
        // Extract and verify the Bearer token to get the AuthPayload.
        guard let bearerHeader = req.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization header")
        }

        let keys = JWTKeyCollection()
        await keys.add(
            hmac: HMACKey(from: configuration.jwtSigningSecret),
            digestAlgorithm: .sha256
        )
        let payload = try await keys.verify(bearerHeader.token, as: AuthPayload.self)

        // Resolve the user UUID from the subject claim.
        guard let userID = UUID(uuidString: payload.subject.value) else {
            throw Abort(.internalServerError, reason: "Invalid subject claim in JWT")
        }

        // Look up the user record.
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.internalServerError, reason: "Authenticated user not found")
        }

        // Look up the active refresh token for this user.
        guard
            let refreshToken = try await RefreshToken.query(on: req.db)
                .filter(\.$user.$id == userID)
                .first(),
            let refreshTokenID = refreshToken.id
        else {
            throw Abort(.internalServerError, reason: "No active refresh token found for user")
        }

        // Derive provider and guest status from the user model.
        let isGuest = user.isGuest
        let authProvider = isGuest ? "guest" : "email"

        return MeResponse(
            id: userID,
            email: isGuest ? "" : user.email,
            authProvider: authProvider,
            createdAt: user.createdAt ?? Date(),
            isGuest: isGuest,
            accessTokenExpiry: payload.expiration.value,
            refreshTokenId: refreshTokenID
        )
    }
}
