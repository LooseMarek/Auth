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

    /// UserDefaults key used to record that the user explicitly tapped "Logout".
    ///
    /// When `true`, `restoreSession()` skips all token restoration and returns
    /// `.unauthenticated` immediately, even when a guest refresh token is present.
    /// The flag is cleared by any successful authentication action.
    static let explicitLogoutKey = "auth.explicitLogout"

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

    /// The `UserDefaults` suite used to persist the explicit-logout flag.
    ///
    /// Injected via `init` so tests can supply a clean, isolated instance.
    private let userDefaults: UserDefaults

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
    ///   - userDefaults: The `UserDefaults` suite used to persist the explicit-logout flag.
    ///     Defaults to `UserDefaults.standard`. Pass a custom suite in tests to keep
    ///     them isolated from each other and from the host app's defaults.
    public init(
        configuration: AuthClientConfiguration,
        networkService: any AuthNetworkService,
        tokenStore: any TokenStore,
        userDefaults: UserDefaults = .standard
    ) {
        self.configuration = configuration
        self.networkService = networkService
        self.tokenStore = tokenStore
        self.userDefaults = userDefaults
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
        // ── 0. If the user explicitly logged out, skip all token restoration. ──
        // The explicit-logout flag is set by logout() and cleared by any successful
        // auth action. While set, restoreSession() always returns .unauthenticated —
        // even when a guest refresh token is present in GuestTokenStore.
        if userDefaults.bool(forKey: Self.explicitLogoutKey) {
            session = .unauthenticated
            return
        }

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
                // The refresh response carries isGuest from the server, so we can
                // distinguish a guest token that was stored in the main slot (which
                // happens when the app is killed while a guest session is active)
                // from a real authenticated session.
                if response.user.isGuest {
                    restoreGuestSession(from: response)
                } else {
                    session = .authenticated(response.user)
                }
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
        // Clear the explicit-logout flag: the user has actively resumed or created a guest
        // session, so future restoreSession() calls should auto-restore it.
        userDefaults.set(false, forKey: Self.explicitLogoutKey)
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
        // Clear the explicit-logout flag: a successful sign-in means the user is
        // intentionally authenticated — future restoreSession() calls should work.
        userDefaults.set(false, forKey: Self.explicitLogoutKey)
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

    /// Signs the user out locally and, for non-guest accounts, invalidates the refresh
    /// token on the server.
    ///
    /// **Guest sessions:** The current guest refresh token is saved to the ``GuestTokenStore``
    /// slot so that a subsequent call to ``loginAsGuest()`` can silently resume the same
    /// guest account (same UUID / app data). The explicit-logout flag is set to prevent
    /// ``restoreSession()`` from auto-restoring the guest session on the next app launch —
    /// the user must actively tap "Continue as Guest" to resume. The server logout call is
    /// intentionally **skipped** for guest sessions: the token must remain valid on the
    /// server so ``loginAsGuest()`` can use it to resume the same session. Authenticated
    /// (non-guest) logout does NOT touch the guest slot.
    ///
    /// Local Keychain clearance and state reset always succeed, even if the server call
    /// fails (network unavailable, server error). This satisfies the UX contract:
    /// logout must always succeed locally.
    public func logout() async {
        // Capture whether this is a guest session before clearing local state.
        let wasGuest = session.isGuest

        // Load the refresh token before clearing the store.
        let refreshToken = (try? tokenStore.load())?.refreshToken

        // If the current session is guest, SAVE the guest refresh token to the guest slot
        // so that loginAsGuest() can resume the same account after logout. The explicit-logout
        // flag (set below) prevents restoreSession() from auto-restoring the session.
        if wasGuest,
           let guestStore = tokenStore as? (any GuestTokenStore),
           let currentRefreshToken = refreshToken {
            guestStore.saveGuestRefreshToken(currentRefreshToken)
        }

        // Set the explicit-logout flag so restoreSession() skips all token restoration.
        // This is cleared by any subsequent successful authentication action.
        userDefaults.set(true, forKey: Self.explicitLogoutKey)

        // Always clear local state first.
        try? tokenStore.delete()
        session = .unauthenticated

        // Best-effort server invalidation — only for real (non-guest) accounts.
        // Guest tokens must remain valid on the server so loginAsGuest() can resume
        // the same session. Server-side invalidation is critical for user accounts
        // (security) but actively prevents guest session resumption.
        if !wasGuest, let refreshToken {
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
        // Clear the explicit-logout flag: a deleted account is gone forever, so the next
        // "Continue as Guest" must create a fresh account (not resume the deleted one).
        userDefaults.set(false, forKey: Self.explicitLogoutKey)
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
