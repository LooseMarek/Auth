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
    static let demoAPIBaseURL = "http://localhost:8080"

    // MARK: - State

    @State private var authManager: AuthManager

    // MARK: - Init

    /// Creates the root view.
    ///
    /// - Parameter configuration: The `AuthClientConfiguration` to use. Defaults to
    ///   `AuthClientConfiguration()` (all Auth defaults) so that `DemoAuthDefault` and
    ///   plain `DemoAuth` targets can call `AppRootView()` with no arguments.
    init(configuration: AuthClientConfiguration = AuthClientConfiguration()) {
        _authManager = State(
            initialValue: AuthManager(
                configuration: configuration,
                networkService: URLSessionAuthNetworkService(baseURL: Self.demoAPIBaseURL),
                tokenStore: KeychainTokenStore()
            )
        )
    }

    // MARK: - Body

    var body: some View {
        content
            .authSheet(manager: authManager)
            .task(id: isSessionUnauthenticated) {
                if isSessionUnauthenticated {
                    authManager.presentAuthFlow(style: .fullScreen)
                }
            }
    }

    // MARK: - Private

    private var isSessionUnauthenticated: Bool {
        if case .unauthenticated = authManager.session { return true }
        return false
    }

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
