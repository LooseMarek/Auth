import Vapor
import Fluent
import JWTKit
import AuthShared

/// Vapor `RouteCollection` that handles Sign in with Google.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: GoogleAuthController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/google` — verifies a Google identity token, finds or creates a User,
///   and returns `AuthResponse`
///
/// The host application must supply `googleJWKS` in `AuthServerConfiguration`. Fetch
/// Google's public keys from `https://www.googleapis.com/oauth2/v3/certs` at startup
/// and pass them as `JWKS` — see ADR-004 and ADR-005 for the injection pattern.
public struct GoogleAuthController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration
    private let tokenGenerator: TokenGenerator

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
        self.tokenGenerator = TokenGenerator(configuration: configuration)
    }

    /// Registers the `POST /auth/google` route.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("google", use: googleSignIn)
    }

    // MARK: - Google Sign In

    /// Verifies a Google identity token, finds or creates a matching User, and returns AuthResponse.
    ///
    /// - Throws: `Abort(.internalServerError)` when `googleJWKS` is not configured.
    /// - Throws: `Abort(.unauthorized)` when the identity token is invalid or tampered.
    /// - Returns: `AuthResponse` with a fresh JWT and refresh token.
    @Sendable
    func googleSignIn(req: Request) async throws -> AuthResponse {
        guard let jwks = configuration.googleJWKS else {
            throw Abort(.internalServerError, reason: "Google JWKS not configured — set googleJWKS in AuthServerConfiguration")
        }

        let body = try req.content.decode(SocialAuthRequest.self)

        // Verify the Google identity token against Google's public keys.
        let keys = JWTKeyCollection()
        try await keys.add(jwks: jwks)

        let googleToken: GoogleIdentityToken
        do {
            googleToken = try await keys.verify(body.identityToken, as: GoogleIdentityToken.self)
        } catch {
            throw Abort(.unauthorized, reason: "Invalid Google identity token: \(error.localizedDescription)")
        }

        // Use the stable subject claim as the unique Google account identifier.
        let providerSubject = googleToken.subject.value

        // Google typically provides the email claim; fall back to a derived identifier
        // if absent (uncommon in practice).
        let email = googleToken.email ?? "\(providerSubject)@google-account.invalid"

        let user = try await findOrCreateUser(email: email, on: req)
        return try await makeAuthResponse(for: user, on: req)
    }

    // MARK: - Shared helpers

    /// Finds an existing User by email or creates a new one with an empty password hash.
    ///
    /// Social-auth users never supply a password, so `passwordHash` is stored as an empty
    /// string. Email/password login for such accounts will always fail the hash comparison,
    /// which is the correct behaviour.
    private func findOrCreateUser(email: String, on req: Request) async throws -> User {
        if let existing = try await User.query(on: req.db)
            .filter(\.$email == email)
            .first() {
            return existing
        }
        let user = User(email: email, passwordHash: "", authProvider: "google")
        try await user.save(on: req.db)
        return user
    }

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
            displayName: nil,
            isGuest: false
        )

        return AuthResponse(
            accessToken: accessTokenResult.token,
            refreshToken: refreshTokenResult.token,
            expiresAt: accessTokenResult.expiresAt,
            user: userDTO
        )
    }
}
