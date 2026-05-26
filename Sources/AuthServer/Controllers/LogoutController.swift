import Vapor
import Fluent
import AuthShared

/// Vapor `RouteCollection` that handles session logout.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: LogoutController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/logout` — invalidates the supplied refresh token; requires a valid JWT
public struct LogoutController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `POST /auth/logout` route under the JWT-protected route group.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let protected = auth.grouped(JWTMiddleware(configuration: configuration))
        protected.post("logout", use: logout)
    }

    // MARK: - Logout

    /// Invalidates the supplied refresh token by deleting it from the database.
    ///
    /// The request must carry a valid Bearer JWT. If the refresh token is not found
    /// (already deleted or never existed) the call still returns HTTP 200 so that
    /// clients can call logout idempotently without special-casing 404.
    ///
    /// - Returns: HTTP 200 on success.
    @Sendable
    func logout(req: Request) async throws -> Response {
        let body = try req.content.decode(LogoutRequest.self)

        // Delete the matching refresh token — silently ignore if not found
        // so logout is idempotent.
        try await RefreshToken.query(on: req.db)
            .filter(\.$token == body.refreshToken)
            .delete()

        return Response(status: .ok)
    }
}
