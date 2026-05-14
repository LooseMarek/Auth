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
}
