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

    /// The active authentication session state.
    public private(set) var session: AuthSessionState = .unauthenticated

    /// The configuration supplied at initialisation time.
    public let configuration: AuthClientConfiguration

    public init(configuration: AuthClientConfiguration) {
        self.configuration = configuration
    }

    func signIn(response: AuthResponse) {
        session = .authenticated(response.user)
    }
}
