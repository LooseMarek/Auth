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
    /// Simulators share the Mac's network stack, so `localhost` resolves directly.
    /// Real devices on the LAN connect via the Mac's mDNS hostname, which Bonjour
    /// advertises automatically — no DHCP or router configuration required.
    ///
    /// See `DemoConfiguration` for hostname update instructions.
    #if targetEnvironment(simulator)
    static let demoAPIBaseURL = DemoConfiguration.fallbackBaseURL
    #else
    // mDNS hostname — resolves automatically on LAN.
    // Update DemoConfiguration.defaultBaseURL if Mac hostname changes
    // (System Settings > General > Sharing).
    static let demoAPIBaseURL = DemoConfiguration.defaultBaseURL
    #endif

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

    // MARK: - Window sizing (macOS)

    #if os(macOS)
    /// Minimum window width (pt).
    ///
    /// The auth sheet panel is 440pt wide. Adding 40pt (20pt per side) ensures the
    /// floating panel is never clipped by the host window edge.
    static let minimumWindowWidth: CGFloat = 480

    /// Minimum window height (pt).
    ///
    /// The auth sheet panel has a minimum height of 540pt. Adding 40pt accounts for
    /// the macOS title bar (~28pt) and a small bottom margin, ensuring the full
    /// `LoginView` (including the register link) is visible without scrolling.
    static let minimumWindowHeight: CGFloat = 580
    #endif

    // MARK: - Body

    var body: some View {
        content
            .authSheet(manager: authManager)
#if os(macOS)
            .frame(minWidth: Self.minimumWindowWidth, minHeight: Self.minimumWindowHeight)
#endif
            .task {
                // Attempt to restore a persisted session (email or guest) before
                // falling back to showing the auth flow.
                await authManager.restoreSession()
                if isSessionUnauthenticated {
                    authManager.presentAuthFlow(style: .fullScreen)
                }
            }
            .onChange(of: isSessionUnauthenticated) { _, nowUnauthenticated in
                if nowUnauthenticated {
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
