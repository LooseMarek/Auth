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
    /// Set to `true` by calling ``presentAuthFlow(style:)`` and back to `false` by
    /// ``dismissAuthFlow()`` or when the user dismisses the sheet via gesture.
    public private(set) var isPresentingAuthFlow: Bool = false

    /// The presentation style for the currently-active (or most-recently-dismissed) auth flow.
    ///
    /// Defaults to `.sheet`. Updated every time ``presentAuthFlow(style:)`` is called.
    /// Resets to `.sheet` when ``dismissAuthFlow()`` is called.
    public private(set) var authPresentationStyle: AuthPresentationStyle = .sheet

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

    /// Triggers the auth flow to be presented with the given style.
    ///
    /// - Parameter style: `.fullScreen` for a non-dismissible full-screen cover (used
    ///   when gating app content behind authentication on launch); `.sheet` for a
    ///   user-dismissible sheet (used for contextual flows such as guest upgrade).
    ///   Defaults to `.sheet`.
    ///
    /// Sets `isPresentingAuthFlow` to `true` and records `authPresentationStyle`.
    /// The `.authSheet(manager:)` modifier observes both to choose the correct
    /// presentation API.
    public func presentAuthFlow(style: AuthPresentationStyle = .sheet) {
        authPresentationStyle = style
        isPresentingAuthFlow = true
    }

    /// Dismisses the auth flow.
    ///
    /// Sets `isPresentingAuthFlow` to `false` and resets `authPresentationStyle` to
    /// `.sheet`. Called automatically when the user dismisses the sheet via a drag
    /// gesture (iOS) or Cmd-W / close button (macOS), or when authentication
    /// completes successfully.
    public func dismissAuthFlow() {
        isPresentingAuthFlow = false
        authPresentationStyle = .sheet
    }

    // MARK: - Session restoration

    /// Attempts to restore a previously authenticated session on app launch.
    ///
    /// Call this method once when the app starts — for example in the root view's
    /// `.task` modifier or during `App.init` — to silently resume a logged-in
    /// session without requiring the user to log in again.
    ///
    /// **Restoration flow:**
    /// 1. **Email / social session:** If a `TokenMetadata` is found in the main token
    ///    store, a silent `refreshToken` call is made. On success, `session` transitions
    ///    to `.authenticated(user)`. On failure, the stale token is cleared.
    /// 2. **Guest session:** If no main token is found but the token store conforms to
    ///    ``GuestTokenStore`` and a guest refresh token is saved, a silent refresh is
    ///    attempted. On success, `session` transitions to `.guest(uuid)`. On failure,
    ///    the stale guest token is cleared.
    /// 3. If neither restoration succeeds, `session` remains `.unauthenticated`.
    ///
    /// This approach always refreshes — even for non-expired tokens — to ensure the
    /// `UserDTO` / guest UUID is available and the server acknowledges the session is
    /// still active.
    public func restoreSession() async {
        // ── 1. Try to restore an email / social session from the main token store. ──
        if let storedMetadata = try? tokenStore.load() {
            do {
                let response = try await networkService.refreshToken(refreshToken: storedMetadata.refreshToken)
                let newMetadata = TokenMetadata(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken,
                    expiresAt: response.expiresAt
                )
                try? tokenStore.save(newMetadata)
                session = .authenticated(response.user)
                return
            } catch {
                // Refresh failed — clear the stale token and fall through.
                try? tokenStore.delete()
            }
        }

        // ── 2. Try to restore a guest session from the guest refresh token slot. ──
        guard let guestStore = tokenStore as? (any GuestTokenStore),
              let savedGuestRefreshToken = guestStore.loadGuestRefreshToken() else {
            // No guest token either — fresh install or post-logout.
            session = .unauthenticated
            return
        }

        do {
            let response = try await networkService.refreshToken(refreshToken: savedGuestRefreshToken)
            restoreGuestSession(from: response)
        } catch {
            // Guest refresh failed — clear the stale guest token.
            guestStore.deleteGuestRefreshToken()
            session = .unauthenticated
        }
    }

    // MARK: - Guest session

    /// Creates or resumes an anonymous guest session.
    ///
    /// **Resume flow:** If a previously-saved guest refresh token exists in the token store
    /// (persisted during a prior guest logout), this method attempts a silent token refresh
    /// via `POST /auth/token/refresh` to restore the old guest session. On success the
    /// session resumes without creating a new guest account, preserving any app data linked
    /// to the original guest UUID.
    ///
    /// **New-guest flow:** If no saved guest token exists, or the refresh call fails (token
    /// expired or revoked), a new guest account is created via `POST /auth/guest`. The stale
    /// saved token (if any) is cleared before falling back.
    ///
    /// On success, tokens are persisted to the token store and `session` transitions
    /// to `.guest(uuid)` where `uuid` is the stable guest identifier returned by the server.
    ///
    /// - Throws: Any ``AuthNetworkError`` returned by the server when creating a new guest account.
    public func loginAsGuest() async throws {
        // Attempt to resume an existing guest session via the saved refresh token.
        if let guestStore = tokenStore as? (any GuestTokenStore),
           let savedRefreshToken = guestStore.loadGuestRefreshToken() {
            do {
                let response = try await networkService.refreshToken(refreshToken: savedRefreshToken)
                restoreGuestSession(from: response)
                return
            } catch {
                // Refresh failed — clear the stale token and fall through to create a new guest.
                guestStore.deleteGuestRefreshToken()
            }
        }

        // No saved token or refresh failed: create a new guest account.
        let response = try await networkService.loginAsGuest()
        restoreGuestSession(from: response)
    }

    /// Applies an `AuthResponse` from either a refresh or a fresh guest sign-in as a guest session.
    private func restoreGuestSession(from response: AuthResponse) {
        let uuid = UUID(uuidString: response.user.id) ?? UUID()
        let metadata = TokenMetadata(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
        try? tokenStore.save(metadata)
        session = .guest(uuid)
        dismissAuthFlow()
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
        dismissAuthFlow()
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
    /// **Guest sessions:** Before clearing the main token store, the current refresh token
    /// is saved to the guest slot (via ``GuestTokenStore``) so the session can be silently
    /// resumed on the next "Continue as Guest" tap. Authenticated (non-guest) logout does
    /// NOT touch the guest slot.
    ///
    /// Local Keychain clearance and state reset always succeed, even if the server call
    /// fails (network unavailable, server error). This satisfies the UX contract:
    /// logout must always succeed locally.
    public func logout() async {
        // Load the refresh token before clearing the store.
        let refreshToken = (try? tokenStore.load())?.refreshToken

        // If the current session is guest, persist the refresh token to the guest slot
        // so it can be used to resume the session on the next loginAsGuest() call.
        if session.isGuest,
           let guestStore = tokenStore as? (any GuestTokenStore),
           let refreshToken {
            guestStore.saveGuestRefreshToken(refreshToken)
        }

        // Always clear local state first.
        try? tokenStore.delete()
        session = .unauthenticated

        // Best-effort server invalidation — only when a refresh token exists.
        if let refreshToken {
            try? await networkService.logout(refreshToken: refreshToken)
        }
    }

    // MARK: - Account deletion

    /// Permanently deletes the authenticated account.
    ///
    /// Calls `DELETE /auth/account` with the current access token. On success, the
    /// local Keychain is cleared, any saved guest refresh token is also removed, and
    /// the session resets to `.unauthenticated`.
    ///
    /// Unlike `logout()`, errors from the server are **not** swallowed — the caller
    /// is responsible for presenting an error to the user.
    ///
    /// - Throws: Any `AuthNetworkError` returned by the server.
    public func deleteAccount() async throws {
        let accessToken = try await withFreshToken { token in token }
        try await networkService.deleteAccount(accessToken: accessToken)
        try? tokenStore.delete()
        // Also clear the guest token slot so the deleted account cannot be resumed.
        (tokenStore as? (any GuestTokenStore))?.deleteGuestRefreshToken()
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

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}
