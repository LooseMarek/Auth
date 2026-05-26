import Vapor
import Fluent
import JWTKit
import AuthShared

/// Vapor `RouteCollection` that handles upgrading a guest session to a full account.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: UpgradeController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/upgrade` — attaches credentials (email/password or social provider)
///   to the authenticated guest user; requires a valid Bearer JWT
///
/// The upgrade preserves the guest UUID — no new user record is created. Once upgraded,
/// the user can authenticate via their attached credentials without losing any app data
/// previously associated with the guest UUID.
///
/// Returns HTTP 409 if the user has already been upgraded (non-empty email on record).
/// Returns HTTP 401 if no valid JWT is present (enforced by `JWTMiddleware`).
public struct UpgradeController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration
    private let tokenGenerator: TokenGenerator

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
        self.tokenGenerator = TokenGenerator(configuration: configuration)
    }

    /// Registers the `POST /auth/upgrade` route under the JWT-protected route group.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let protected = auth.grouped(JWTMiddleware(configuration: configuration))
        protected.post("upgrade", use: upgrade)
    }

    // MARK: - Upgrade

    /// Attaches credentials to the authenticated guest user record.
    ///
    /// The user UUID is extracted from the Bearer JWT subject claim. Credentials are
    /// then attached according to the `provider` field in `UpgradeGuestRequest`:
    ///
    /// - `.email`: `email` and `password` are required; the password is BCrypt-hashed
    ///   before storage.
    /// - `.apple` / `.google`: `email` is required; `passwordHash` is left empty
    ///   (social users never authenticate with a password via AuthServer).
    ///
    /// - Throws: `Abort(.unauthorized)` when the user is not found in the database.
    /// - Throws: `Abort(.conflict)` when the user has already been upgraded.
    /// - Throws: `Abort(.badRequest)` when required fields for the chosen provider are missing.
    /// - Returns: Updated `AuthResponse` for the same UUID.
    @Sendable
    func upgrade(req: Request) async throws -> AuthResponse {
        // Extract the user UUID from the verified JWT subject claim.
        guard let bearerHeader = req.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing Authorization header")
        }

        let keys = JWTKeyCollection()
        await keys.add(hmac: HMACKey(from: configuration.jwtSigningSecret), digestAlgorithm: .sha256)
        let payload = try await keys.verify(bearerHeader.token, as: AuthPayload.self)
        let userUUIDString = payload.subject.value

        guard let userID = UUID(uuidString: userUUIDString) else {
            throw Abort(.unauthorized, reason: "Malformed user identifier in token")
        }

        // Look up the existing guest user by UUID.
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        // Reject if the user has already upgraded (email is no longer the synthetic guest email).
        guard user.isGuest else {
            throw Abort(.conflict, reason: "Account has already been upgraded")
        }

        let body = try req.content.decode(UpgradeGuestRequest.self)

        // Attach credentials based on the provider.
        switch body.provider {
        case .email:
            guard let email = body.email, let password = body.password else {
                throw Abort(.badRequest, reason: "Email and password are required for email upgrade")
            }
            let hash = try await req.password.async.hash(password)
            user.email = email
            user.passwordHash = hash
            user.authProvider = "email"

        case .apple:
            // Apple only provides email on the first sign-in. When absent, decode the
            // identity token and derive a stable synthetic address from the subject claim
            // (mirrors AppleAuthController.appleSignIn).
            let appleEmail: String
            if let provided = body.email {
                appleEmail = provided
            } else {
                guard let jwks = configuration.appleJWKS,
                      let tokenString = body.identityToken else {
                    throw Abort(.badRequest, reason: "Apple identity token is required when email is not provided")
                }
                let appleKeys = JWTKeyCollection()
                try await appleKeys.add(jwks: jwks)
                let appleToken = try await appleKeys.verify(tokenString, as: AppleIdentityToken.self)
                appleEmail = appleToken.email ?? "\(appleToken.subject.value)@privaterelay.appleid.com"
            }
            user.email = appleEmail
            user.authProvider = "apple"

        case .google:
            guard let email = body.email else {
                throw Abort(.badRequest, reason: "Email is required for Google upgrade")
            }
            user.email = email
            user.authProvider = "google"
            // Social users do not authenticate with a password via AuthServer.
            // Leave passwordHash as empty string — BCrypt comparison will always fail,
            // which is the correct behaviour for social-only accounts.

        }

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
