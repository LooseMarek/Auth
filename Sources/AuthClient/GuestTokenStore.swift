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
    /// Called by ``AuthManager/logout()`` when the current session is `.guest`.
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
