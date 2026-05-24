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
    /// Theme: warm orange (#FF6B35), cream surface, rounded system font, and
    /// `Bundle.main` for localisation so the demo app's own `.lproj` files take
    /// precedence over Auth's built-in English strings.
    nonisolated static func makeConfiguration() -> AuthClientConfiguration {
        AuthClientConfiguration(
            allowGuestAccess: true,
            primaryColor: Color(red: 1.0, green: 0.42, blue: 0.21),
            backgroundColor: nil, // uses adaptive system background
            font: .system(.body, design: .rounded),
            localizationBundle: .main,
            surfaceColor: Color(red: 0.97, green: 0.95, blue: 0.93),
            primaryTextColor: Color(red: 0.13, green: 0.11, blue: 0.09),
            secondaryTextColor: Color(red: 0.45, green: 0.40, blue: 0.36),
            buttonTextColor: .white,
            errorColor: Color(red: 0.85, green: 0.20, blue: 0.10)
        )
    }
}
