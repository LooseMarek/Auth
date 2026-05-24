import SwiftUI
import AuthClient

/// The shared root view used by both DemoAuthDefault and DemoAuthCustom targets.
///
/// Owns the `AuthManager` instance and attaches the `.authSheet(manager:)` modifier
/// so that the SPM-provided auth sheet is presented whenever the user is unauthenticated.
/// All eight auth flows (email login, email register, forgot password, Apple, Google,
/// guest, guest-upgrade, and logout) are handled by the sheet — this view only gates
/// the content behind successful authentication.
struct AppRootView: View {

    // MARK: - Constants

    /// Base URL for the demo Auth API server (local development).
    ///
    /// Wire this into a concrete `AuthNetworkService` implementation when adding real
    /// network calls in a follow-up task.
    static let demoAPIBaseURL = "http://localhost:8080"

    // MARK: - State

    @State private var authManager = AuthManager(configuration: AuthClientConfiguration())

    // MARK: - Body

    var body: some View {
        content
            .authSheet(manager: authManager)
            .onAppear {
                if case .unauthenticated = authManager.session {
                    authManager.presentAuthFlow()
                }
            }
    }

    // MARK: - Private

    @ViewBuilder
    private var content: some View {
        switch authManager.session {
        case .unauthenticated:
            // The auth sheet covers the screen; show an empty background behind it.
            Color.clear
        case .guest, .authenticated:
            ProfileView(
                authManager: authManager,
                apiBaseURL: Self.demoAPIBaseURL
            )
        }
    }
}
