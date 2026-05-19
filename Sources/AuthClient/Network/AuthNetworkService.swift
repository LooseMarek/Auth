import AuthShared

public enum AuthNetworkError: Error, Sendable {
    case invalidCredentials
    case emailTaken
    case networkUnavailable
    case serverError
}

public protocol AuthNetworkService: Sendable {
    func login(email: String, password: String) async throws -> AuthResponse
    func register(email: String, password: String) async throws -> AuthResponse
    func forgotPassword(email: String) async throws

    /// Exchanges a refresh token for a new ``AuthResponse`` containing fresh tokens.
    func refreshToken(refreshToken: String) async throws -> AuthResponse

    /// Invalidates the given refresh token server-side (POST /auth/logout).
    func logout(refreshToken: String) async throws

    /// Deletes the authenticated account server-side (DELETE /auth/account).
    func deleteAccount(accessToken: String) async throws
}
