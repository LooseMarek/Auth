import Foundation
import AuthShared

/// The current authentication session state exposed by `AuthManager`.
public enum AuthSessionState: Sendable {
    /// No user is signed in.
    case unauthenticated
    /// A guest session is active, identified by the given UUID.
    case guest(UUID)
    /// A fully authenticated session is active for the given user.
    case authenticated(UserDTO)

    /// Returns `true` when the session is `.guest(_)`, otherwise `false`.
    ///
    /// Convenience property used by UI components to suppress guest-upgrade
    /// entry points when the user is already signed in as a guest.
    public var isGuest: Bool {
        if case .guest = self { return true }
        return false
    }
}
