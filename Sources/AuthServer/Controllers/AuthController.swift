import Vapor
import Fluent
import AuthShared

/// Vapor `RouteCollection` that handles email/password registration and login.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: AuthController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/register` — creates a new user account and returns `AuthResponse`
/// - `POST /auth/login`    — authenticates an existing user and returns `AuthResponse`
public struct AuthController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration
    private let tokenGenerator: TokenGenerator

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
        self.tokenGenerator = TokenGenerator(configuration: configuration)
    }

    /// Registers the `POST /auth/register` and `POST /auth/login` routes.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
    }

    // MARK: - Register

    /// Registers a new user with email and password.
    ///
    /// - Throws: `Abort(.conflict)` when the email is already taken.
    /// - Returns: `AuthResponse` with a fresh JWT and refresh token.
    @Sendable
    func register(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(RegisterRequest.self)

        // Check for duplicate email
        let existing = try await User.query(on: req.db)
            .filter(\.$email == body.email)
            .first()
        guard existing == nil else {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }

        // Hash password and persist user
        let hash = try await req.password.async.hash(body.password)
        let user = User(email: body.email, passwordHash: hash)
        try await user.save(on: req.db)

        return try await makeAuthResponse(for: user, on: req)
    }

    // MARK: - Login

    /// Authenticates an existing user with email and password.
    ///
    /// - Throws: `Abort(.unauthorized)` when the email is not found or the password is wrong.
    /// - Returns: `AuthResponse` with a fresh JWT and refresh token.
    @Sendable
    func login(req: Request) async throws -> AuthResponse {
        let body = try req.content.decode(LoginRequest.self)

        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == body.email)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        let passwordValid = try await req.password.async.verify(body.password, created: user.passwordHash)
        guard passwordValid else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

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
