import Vapor
import Fluent
import AuthShared

/// Vapor `RouteCollection` that handles access token refresh.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: RefreshTokenController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/refresh` — exchanges a valid, non-expired refresh token for a new
///   `AuthResponse` containing a fresh access token and a rotated refresh token
public struct RefreshTokenController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration
    private let tokenGenerator: TokenGenerator

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
        self.tokenGenerator = TokenGenerator(configuration: configuration)
    }

    /// Registers the `POST /auth/refresh` route.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("refresh", use: refresh)
    }

    // MARK: - Refresh

    /// Exchanges a refresh token for a new `AuthResponse`.
    ///
    /// The supplied refresh token is validated (exists in DB and has not expired),
    /// then deleted. A new access token and a rotated refresh token are issued and
    /// the new refresh token is persisted before the response is returned.
    ///
    /// - Throws: `Abort(.unauthorized)` when the refresh token is not found or has expired.
    /// - Returns: `AuthResponse` with a fresh access token and rotated refresh token.
    @Sendable
    func refresh(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(RefreshTokenRequest.self)

        // Look up the refresh token record.
        guard let storedToken = try await RefreshToken.query(on: req.db)
            .filter(\.$token == body.refreshToken)
            .with(\.$user)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid or expired refresh token")
        }

        // Reject expired tokens.
        guard storedToken.expiresAt > Date() else {
            try await storedToken.delete(on: req.db)
            throw Abort(.unauthorized, reason: "Invalid or expired refresh token")
        }

        let user = storedToken.user

        guard let userID = user.id else {
            throw Abort(.internalServerError, reason: "User has no identifier")
        }

        // Delete the used refresh token (rotate — one-time use).
        try await storedToken.delete(on: req.db)

        // Issue a new access token and a rotated refresh token.
        let accessTokenResult = try await tokenGenerator.makeAccessToken(userID: userID)
        let refreshTokenResult = tokenGenerator.makeRefreshToken(userID: userID)

        let newRefreshToken = RefreshToken(
            token: refreshTokenResult.token,
            userID: userID,
            expiresAt: refreshTokenResult.expiresAt
        )
        try await newRefreshToken.save(on: req.db)

        let userDTO = UserDTO(
            id: userID.uuidString,
            email: user.isGuest ? nil : user.email,
            displayName: nil,
            isGuest: user.isGuest
        )

        return AuthResponse(
            accessToken: accessTokenResult.token,
            refreshToken: refreshTokenResult.token,
            expiresAt: accessTokenResult.expiresAt,
            user: userDTO
        )
    }
}
