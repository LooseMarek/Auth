import Foundation

/// An optional extension of ``TokenStore`` that supports persisting a guest refresh token
/// under a separate Keychain key so the guest session can be silently resumed after logout.
///
/// `AuthManager` checks whether the active ``TokenStore`` conforms to `GuestTokenStore`
/// at runtime. If it does not conform (e.g. ``InMemoryTokenStore`` in unit tests that
/// don't exercise guest persistence), guest-token operations are silently skipped.
///
/// - ``KeychainTokenStore`` conforms to this protocol in production.
/// - ``MockTokenStore`` conforms in AuthClientTests so guest-persistence tests can assert
///   on `savedGuestRefreshToken`.
/// - ``InMemoryTokenStore`` does **not** conform — unit tests that don't need guest
///   persistence continue to work unchanged.
public protocol GuestTokenStore: TokenStore {

    /// Persists the guest refresh token under a separate Keychain key.
    ///
    /// Called by ``AuthManager/loginAsGuest()`` after a new guest account is created
    /// and by ``AuthManager/logout()`` when the active session is a guest, so the same
    /// guest account can be resumed via ``AuthManager/loginAsGuest()`` after an explicit
    /// logout. The ``AuthManager/logout()`` method also sets the explicit-logout flag,
    /// which prevents ``AuthManager/restoreSession()`` from auto-resuming the session
    /// on the next app launch — the user must actively tap "Continue as Guest".
    func saveGuestRefreshToken(_ token: String)

    /// Returns the previously saved guest refresh token, or `nil` when none exists.
    ///
    /// Called by ``AuthManager/loginAsGuest()`` before creating a new guest account,
    /// so the existing session can be resumed via token refresh instead.
    func loadGuestRefreshToken() -> String?

    /// Removes the saved guest refresh token.
    ///
    /// Called by ``AuthManager/loginAsGuest()`` when the refresh fails (token expired),
    /// and by ``AuthManager/deleteAccount()`` after successful account deletion.
    func deleteGuestRefreshToken()
}
