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
}
