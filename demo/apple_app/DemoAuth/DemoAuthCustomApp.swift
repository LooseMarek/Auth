import SwiftUI
import AuthClient

@main
struct DemoAuthCustomApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(configuration: DemoAuthCustomApp.makeConfiguration())
        }
    }

    /// Builds the custom `AuthClientConfiguration` for the `DemoAuthCustom` target.
    ///
    /// This factory method is `static` and `internal` so it can be called directly
    /// from `DemoAuthCustomTests` to verify the configuration values in unit tests
    /// without needing to instantiate the full `App` struct.
    ///
    /// Theme: warm orange brand colour with fully separate light and dark palettes,
    /// rounded system font, and `Bundle.main` for localisation so the demo app's own
    /// `.lproj` files take precedence over Auth's built-in English strings.
    ///
    /// Light palette  — warm cream background, dark warm text, orange primary.
    /// Dark palette   — near-black warm background, warm cream text, brighter orange primary.
    nonisolated static func makeConfiguration() -> AuthClientConfiguration {
        AuthClientConfiguration(
            allowGuestAccess: true,
            light: AuthColorTokens(
                primaryColor: Color(red: 1.00, green: 0.42, blue: 0.21), // #FF6B35
                backgroundColor: Color(red: 0.98, green: 0.97, blue: 0.95),
                surfaceColor: Color(red: 0.97, green: 0.95, blue: 0.93),
                primaryTextColor: Color(red: 0.13, green: 0.11, blue: 0.09),
                secondaryTextColor: Color(red: 0.45, green: 0.40, blue: 0.36),
                buttonTextColor: .white,
                errorColor: Color(red: 0.85, green: 0.20, blue: 0.10)
            ),
            dark: AuthColorTokens(
                primaryColor: Color(red: 1.00, green: 0.55, blue: 0.30), // brighter orange for dark bg
                backgroundColor: Color(red: 0.10, green: 0.08, blue: 0.06),
                surfaceColor: Color(red: 0.18, green: 0.15, blue: 0.11),
                primaryTextColor: Color(red: 0.95, green: 0.92, blue: 0.88),
                secondaryTextColor: Color(red: 0.65, green: 0.58, blue: 0.50),
                buttonTextColor: .white,
                errorColor: Color(red: 1.00, green: 0.35, blue: 0.22)
            ),
            font: .system(.body, design: .rounded),
            localizationBundle: .main
        )
    }
}
