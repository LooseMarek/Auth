import Vapor
import Fluent
import AuthShared

/// Vapor `RouteCollection` that handles anonymous guest authentication.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: GuestAuthController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/guest` — creates a new anonymous user tied to a device identifier
///   and returns `AuthResponse`
///
/// Guest users have an empty `email` and `passwordHash`. The stable identifier for
/// the session is the user's UUID returned in `AuthResponse.user.id`. The host app
/// should persist this UUID alongside the guest JWT in Keychain so the session
/// survives app launches.
///
/// To attach credentials to a guest session later, use `UpgradeController`
/// (`POST /auth/upgrade`).
public struct GuestAuthController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration
    private let tokenGenerator: TokenGenerator

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
        self.tokenGenerator = TokenGenerator(configuration: configuration)
    }

    /// Registers the `POST /auth/guest` route.
    public func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("guest", use: guestSignIn)
    }

    // MARK: - Guest Sign In

    /// Creates a new anonymous user record and returns an `AuthResponse`.
    ///
    /// Each call creates a distinct user — there is no de-duplication by `deviceID`.
    /// If the device already has a valid guest JWT in Keychain, the client should
    /// reuse it rather than calling this endpoint again.
    ///
    /// - Returns: `AuthResponse` with a fresh JWT, refresh token, and the new user's UUID.
    @Sendable
    func guestSignIn(req: Request) async throws -> AuthResponse {
        // Decode the request body — deviceID is recorded but not used for de-duplication.
        _ = try req.content.decode(GuestAuthRequest.self)

        // Create a guest user with no email or password credentials.
        let user = User(email: "", passwordHash: "")
        try await user.save(on: req.db)

        return try await makeAuthResponse(for: user, on: req)
    }

    // MARK: - Shared helpers

    /// Generates a JWT + refresh token, persists the refresh token, and builds the `AuthResponse`.
    private func makeAuthResponse(for user: User, on req: Request) async throws -> AuthResponse {
        guard let userID = user.id else {
            throw Abort(.internalServerError, reason: "User has no identifier")
        }

        let accessTokenResult = try await tokenGenerator.makeAccessToken(userID: userID)
        let refreshTokenResult = tokenGenerator.makeRefreshToken(userID: userID)

        let refreshToken = RefreshToken(
            token: refreshTokenResult.token,
            userID: userID,
            expiresAt: refreshTokenResult.expiresAt
        )
        try await refreshToken.save(on: req.db)

        let userDTO = UserDTO(
            id: userID.uuidString,
            email: user.email,
            displayName: nil
        )

        return AuthResponse(
            accessToken: accessTokenResult.token,
            refreshToken: refreshTokenResult.token,
            expiresAt: accessTokenResult.expiresAt,
            user: userDTO
        )
    }
}
