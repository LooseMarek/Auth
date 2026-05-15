import AuthShared

public enum AuthNetworkError: Error, Sendable {
    case invalidCredentials
    case networkUnavailable
    case serverError
}

public protocol AuthNetworkService: Sendable {
    func login(email: String, password: String) async throws -> AuthResponse
}
