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
/// Guest users are stored with a synthetic email `guest+{UUID}@auth.internal` and an
/// empty `passwordHash`. The synthetic email satisfies the NOT NULL + UNIQUE constraints
/// without colliding across multiple guest sign-ins. The stable identifier for the
/// session is the user's UUID returned in `AuthResponse.user.id`. The host app should
/// persist this UUID alongside the guest JWT in Keychain so the session survives app
/// launches. The `AuthResponse.user.email` is always `nil` for guests.
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
    public func boot(routes: any RoutesBuilder) throws {
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

        // Pre-assign the UUID so the synthetic guest email can embed it before the first save.
        // This guarantees uniqueness without altering the schema (email stays NOT NULL UNIQUE).
        let guestID = UUID()
        let user = User(
            id: guestID,
            email: User.guestEmail(for: guestID),
            passwordHash: ""
        )
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

        // Expose nil email in the DTO — the synthetic storage email is an implementation detail.
        let userDTO = UserDTO(
            id: userID.uuidString,
            email: user.isGuest ? nil : user.email,
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
