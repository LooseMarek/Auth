import Observation
import Foundation
import AuthShared

/// Single source of truth for authentication state in the host app.
///
/// Initialise once with an `AuthClientConfiguration` and observe `session` from any
/// SwiftUI view. Use `@Observable` (iOS 17.0+ / macOS 14.0+) — not `ObservableObject`.
@Observable
@MainActor
public final class AuthManager {

    // MARK: - Constants

    /// Number of seconds before access-token expiry at which a silent refresh is triggered.
    static let tokenRefreshThreshold: TimeInterval = 60

    // MARK: - Public state

    /// The active authentication session state.
    public private(set) var session: AuthSessionState = .unauthenticated

    /// Whether the auth sheet is currently being presented.
    ///
    /// Set to `true` by calling ``presentAuthFlow()`` and back to `false` by
    /// ``dismissAuthFlow()`` or when the user dismisses the sheet via gesture.
    public private(set) var isPresentingAuthFlow: Bool = false

    /// The configuration supplied at initialisation time.
    public let configuration: AuthClientConfiguration

    // MARK: - Internal dependencies

    /// Package-internal so `AppleSignInHandler` can call social auth endpoints.
    let networkService: any AuthNetworkService
    private let tokenStore: any TokenStore

    // MARK: - Init

    /// Creates an `AuthManager` with explicit dependencies.
    ///
    /// Use this initialiser when you want to supply a concrete ``AuthNetworkService``
    /// and ``TokenStore`` — for example in tests or when wiring a real network layer.
    ///
    /// - Parameters:
    ///   - configuration: Developer-facing configuration for colours, fonts, and feature flags.
    ///   - networkService: The network layer implementation.
    ///   - tokenStore: Persistence for token metadata.
    public init(
        configuration: AuthClientConfiguration,
        networkService: any AuthNetworkService,
        tokenStore: any TokenStore
    ) {
        self.configuration = configuration
        self.networkService = networkService
        self.tokenStore = tokenStore
    }

    /// Convenience initialiser for host apps.
    ///
    /// Defaults to ``KeychainTokenStore`` and a no-op network stub; replace the network
    /// service with a real implementation before making authenticated requests.
    ///
    /// - Parameter configuration: Developer-facing configuration.
    public convenience init(configuration: AuthClientConfiguration) {
        self.init(
            configuration: configuration,
            networkService: NoOpAuthNetworkService(),
            tokenStore: KeychainTokenStore()
        )
    }

    // MARK: - Auth flow presentation

    /// Triggers the auth sheet to be presented.
    ///
    /// Sets `isPresentingAuthFlow` to `true`, which the `.authSheet(manager:)`
    /// modifier observes to show the sheet.
    public func presentAuthFlow() {
        isPresentingAuthFlow = true
    }

    /// Dismisses the auth sheet.
    ///
    /// Sets `isPresentingAuthFlow` to `false`. Called automatically when the
    /// user dismisses the sheet via a drag gesture (iOS) or Cmd-W / close
    /// button (macOS), or when authentication completes successfully.
    public func dismissAuthFlow() {
        isPresentingAuthFlow = false
    }

    // MARK: - Guest session

    /// Creates an anonymous guest session via POST /auth/guest.
    ///
    /// On success, tokens are persisted to the token store and `session` transitions
    /// to `.guest(uuid)` where `uuid` is the stable guest identifier returned by the server.
    ///
    /// - Throws: Any ``AuthNetworkError`` returned by the server.
    public func loginAsGuest() async throws {
        let response = try await networkService.loginAsGuest()
        let uuid = UUID(uuidString: response.user.id) ?? UUID()
        let metadata = TokenMetadata(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
        try? tokenStore.save(metadata)
        session = .guest(uuid)
    }

    // MARK: - Internal

    /// Directly sets the session to `.guest(uuid)`.
    ///
    /// Package-internal — used by tests to seed a guest state without going through the network.
    func setGuestSession(uuid: UUID) {
        session = .guest(uuid)
    }

    func signIn(response: AuthResponse) {
        let metadata = TokenMetadata(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
        try? tokenStore.save(metadata)
        session = .authenticated(response.user)
    }

    // MARK: - Silent token refresh

    /// Executes `body` with a guaranteed-fresh access token.
    ///
    /// Before calling `body`, the stored token is inspected. If it expires within
    /// `tokenRefreshThreshold` seconds, a silent refresh is performed first. If the
    /// refresh fails, the session transitions to `.unauthenticated` and the error
    /// is rethrown to the caller.
    ///
    /// - Parameter body: A closure that receives the current access token string.
    /// - Returns: Whatever `body` returns.
    /// - Throws: Rethrows any error from `body` or from a failed silent refresh.
    @discardableResult
    public func withFreshToken<T: Sendable>(_ body: (String) async throws -> T) async throws -> T {
        guard let metadata = try tokenStore.load() else {
            session = .unauthenticated
            throw AuthNetworkError.invalidCredentials
        }

        if metadata.isNearExpiry(threshold: Self.tokenRefreshThreshold) {
            do {
                let refreshed = try await networkService.refreshToken(refreshToken: metadata.refreshToken)
                let newMetadata = TokenMetadata(
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken,
                    expiresAt: refreshed.expiresAt
                )
                try tokenStore.save(newMetadata)
                return try await body(refreshed.accessToken)
            } catch {
                try? tokenStore.delete()
                session = .unauthenticated
                throw error
            }
        }

        return try await body(metadata.accessToken)
    }

    // MARK: - Logout

    /// Signs the user out locally and, if a refresh token is present, invalidates it
    /// on the server.
    ///
    /// Local Keychain clearance and state reset always succeed, even if the server call
    /// fails (network unavailable, server error). This satisfies the UX contract:
    /// logout must always succeed locally.
    public func logout() async {
        // Load the refresh token before clearing the store
        let refreshToken = (try? tokenStore.load())?.refreshToken

        // Always clear local state first
        try? tokenStore.delete()
        session = .unauthenticated

        // Best-effort server invalidation — only when a refresh token exists
        if let refreshToken {
            try? await networkService.logout(refreshToken: refreshToken)
        }
    }

    // MARK: - Account deletion

    /// Permanently deletes the authenticated account.
    ///
    /// Calls `DELETE /auth/account` with the current access token. On success, the
    /// local Keychain is cleared and the session resets to `.unauthenticated`.
    ///
    /// Unlike `logout()`, errors from the server are **not** swallowed — the caller
    /// is responsible for presenting an error to the user.
    ///
    /// - Throws: Any `AuthNetworkError` returned by the server.
    public func deleteAccount() async throws {
        let accessToken = try await withFreshToken { token in token }
        try await networkService.deleteAccount(accessToken: accessToken)
        try? tokenStore.delete()
        session = .unauthenticated
    }
}

// MARK: - NoOpAuthNetworkService

/// A do-nothing default network service used as the default dependency.
/// Host apps must replace this with a real implementation.
struct NoOpAuthNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func logout(refreshToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func deleteAccount(accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}
