import Observation
import Foundation
import AuthShared

/// Single source of truth for authentication state in the host app.
///
/// Initialise once with an `AuthClientConfiguration` and observe `session` from any
/// SwiftUI view. Use `@Observable` (iOS 17.0+ / macOS 14.0+) — not `ObservableObject`.
@Observable
@MainActor
public final class AuthManager: LoginAuthManaging {

    /// The active authentication session state.
    public private(set) var session: AuthSessionState = .unauthenticated

    /// The configuration supplied at initialisation time.
    public let configuration: AuthClientConfiguration

    public init(configuration: AuthClientConfiguration) {
        self.configuration = configuration
    }

    /// Authenticate with email and password against the configured API endpoint.
    /// On success, tokens are persisted and `session` transitions to `.authenticated`.
    public func login(email: String, password: String) async throws {
        let url = configuration.baseURL.appendingPathComponent("auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.serverError
        }

        switch http.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let authResponse = try decoder.decode(AuthResponse.self, from: data)
            let metadata = TokenMetadata(
                accessToken: authResponse.accessToken,
                refreshToken: authResponse.refreshToken,
                expiresAt: authResponse.expiresAt
            )
            try configuration.tokenStore.save(metadata)
            session = .authenticated(authResponse.user)
        case 401:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.serverError
        }
    }
}
