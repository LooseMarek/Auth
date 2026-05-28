import Foundation
import AuthShared

/// A concrete ``AuthNetworkService`` implementation that communicates with
/// the Auth server over HTTP using `URLSession`.
///
/// Create one instance per `AuthManager` and pass it to
/// `AuthManager.init(configuration:networkService:tokenStore:)`:
/// ```swift
/// let manager = AuthManager(
///     configuration: AuthClientConfiguration(),
///     networkService: URLSessionAuthNetworkService(baseURL: "http://localhost:8080"),
///     tokenStore: KeychainTokenStore()
/// )
/// ```
///
/// ## Error mapping
/// | HTTP status / URL error | Thrown error |
/// |-------------------------|--------------|
/// | 401                     | `.invalidCredentials` |
/// | 409                     | `.emailTaken` |
/// | other non-2xx           | `.serverError` |
/// | URLError `.notConnectedToInternet`, `.dataNotAllowed` | `.networkUnavailable` |
/// | URLError `.cannotConnectToHost`, `.timedOut`, `.networkConnectionLost`, other | `.serverUnreachable` |
public struct URLSessionAuthNetworkService: AuthNetworkService {

    private let baseURL: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Creates a network service that sends requests to `baseURL`.
    ///
    /// - Parameters:
    ///   - baseURL: The scheme + host + optional port (e.g. `"http://localhost:8080"`).
    ///     Do **not** include a trailing slash.
    ///   - session: The `URLSession` to use. Defaults to `.shared`. Pass a custom
    ///     session with `MockURLProtocol` in unit tests.
    public init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - AuthNetworkService

    public func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        return try await post(path: "/auth/login", body: body)
    }

    public func register(email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password)
        return try await post(path: "/auth/register", body: body)
    }

    public func forgotPassword(email: String) async throws {
        let body = ForgotPasswordRequest(email: email)
        try await postVoid(path: "/auth/forgot-password", body: body)
    }

    public func refreshToken(refreshToken: String) async throws -> AuthResponse {
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        return try await post(path: "/auth/refresh", body: body)
    }

    public func logout(refreshToken: String) async throws {
        let body = LogoutRequest(refreshToken: refreshToken)
        try await postVoid(path: "/auth/logout", body: body)
    }

    public func deleteAccount(accessToken: String) async throws {
        try await deleteVoid(path: "/auth/account", bearerToken: accessToken)
    }

    public func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        let body = SocialAuthRequest(provider: .apple, identityToken: identityToken)
        return try await post(path: "/auth/apple", body: body)
    }

    public func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        let body = UpgradeGuestRequest(
            guestUUID: guestUUID.uuidString,
            provider: .apple,
            email: nil,
            password: nil,
            identityToken: identityToken
        )
        return try await postWithBearer(path: "/auth/upgrade", bearerToken: accessToken, body: body)
    }

    public func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        let body = SocialAuthRequest(provider: .google, identityToken: identityToken)
        return try await post(path: "/auth/google", body: body)
    }

    public func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        let body = UpgradeGuestRequest(
            guestUUID: guestUUID.uuidString,
            provider: .google,
            email: nil,
            password: nil,
            identityToken: identityToken
        )
        return try await postWithBearer(path: "/auth/upgrade", bearerToken: accessToken, body: body)
    }

    public func loginAsGuest() async throws -> AuthResponse {
        // GuestAuthRequest requires a deviceID; use a stable anonymous placeholder
        // since the server does not de-duplicate by deviceID.
        let body = GuestAuthRequest(deviceID: "demo-device")
        return try await post(path: "/auth/guest", body: body)
    }

    public func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        let body = UpgradeGuestRequest(
            guestUUID: guestUUID.uuidString,
            provider: .email,
            email: email,
            password: password,
            identityToken: nil
        )
        return try await postWithBearer(path: "/auth/upgrade", bearerToken: accessToken, body: body)
    }

    // MARK: - Private helpers

    /// Sends a POST request with a JSON-encoded body and decodes the `AuthResponse`.
    private func post<Body: Encodable>(path: String, body: Body) async throws -> AuthResponse {
        let request = try makeRequest(path: path, method: "POST", body: body)
        return try await perform(request)
    }

    /// Sends a POST request with a JSON-encoded body and Bearer token, decodes the `AuthResponse`.
    private func postWithBearer<Body: Encodable>(path: String, bearerToken: String, body: Body) async throws -> AuthResponse {
        var request = try makeRequest(path: path, method: "POST", body: body)
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        return try await perform(request)
    }

    /// Sends a POST request with a JSON-encoded body, ignoring any response body.
    private func postVoid<Body: Encodable>(path: String, body: Body) async throws {
        let request = try makeRequest(path: path, method: "POST", body: body)
        try await performVoid(request)
    }

    /// Sends a DELETE request with a Bearer token header, ignoring any response body.
    private func deleteVoid(path: String, bearerToken: String) async throws {
        var request = makeEmptyRequest(path: path, method: "DELETE")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        try await performVoid(request)
    }

    private func makeRequest<Body: Encodable>(path: String, method: String, body: Body) throws -> URLRequest {
        var request = makeEmptyRequest(path: path, method: method)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func makeEmptyRequest(path: String, method: String) -> URLRequest {
        // Force-unwrap is safe: baseURL + path are programmer-supplied constants.
        let url = URL(string: baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }

    /// Executes `request`, maps HTTP status codes to `AuthNetworkError`, and decodes `AuthResponse`.
    private func perform(_ request: URLRequest) async throws -> AuthResponse {
        let (data, response) = try await execute(request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthNetworkError.serverError
        }
        try mapStatusCode(http.statusCode, url: request.url)
        return try decoder.decode(AuthResponse.self, from: data)
    }

    /// Executes `request`, maps HTTP status codes, and discards the response body.
    private func performVoid(_ request: URLRequest) async throws {
        let (_, response) = try await execute(request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthNetworkError.serverError
        }
        try mapStatusCode(http.statusCode, url: request.url)
    }

    /// Wraps `session.data(for:)` and converts `URLError` to the appropriate
    /// ``AuthNetworkError``:
    /// - `.notConnectedToInternet` / `.dataNotAllowed` → `.networkUnavailable`
    ///   (device is genuinely offline)
    /// - All other URL errors → `.serverUnreachable`
    ///   (device has internet but the server cannot be reached)
    private func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .dataNotAllowed:
                throw AuthNetworkError.networkUnavailable
            default:
                throw AuthNetworkError.serverUnreachable
            }
        }
    }

    /// Maps HTTP status codes to `AuthNetworkError`. Passes through 2xx unchanged.
    private func mapStatusCode(_ statusCode: Int, url: URL?) throws {
        switch statusCode {
        case 200...299:
            return
        case 401:
            throw AuthNetworkError.invalidCredentials
        case 409:
            throw AuthNetworkError.emailTaken
        default:
            throw AuthNetworkError.serverError
        }
    }
}
