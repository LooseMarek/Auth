import Foundation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

#if arch(arm64)
private let snapshotArch = "arm64"
#else
private let snapshotArch = "x86_64"
#endif

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - Light mode

    func testDefaultState() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
    }

    func testWithInputsState() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "secret123"
        ))
    }

    func testLoadingState() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "secret123",
            initialIsLoading: true
        ))
    }

    func testInvalidCredentialsState() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "wrongpass",
            initialErrorMessage: "Incorrect email or password."
        ))
    }

    func testNoGuestAccessState() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies the 'Continue as Guest' button is rendered when allowGuestAccess is true.
    func testGuestButtonVisible() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: true)),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies the 'Continue as Guest' button is absent when allowGuestAccess is false.
    func testGuestButtonHidden() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies that the custom Sign in with Apple button is visible in the default (light) login layout.
    func testAppleButtonVisible() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies that the custom Sign in with Apple button is visible in dark mode.
    func testAppleButtonVisible_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies Google button brand compliance in light mode:
    /// white background, Google G logo, dark label, light border, pill shape.
    /// The button must not change appearance when `primaryColor` is customised.
    func testGoogleButtonBrandCompliant() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                allowGuestAccess: false,
                primaryColor: .purple
            )),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies Google button brand compliance in dark mode:
    /// dark (#1F1F1F) background, light (#E8EAED) label, dark (#3C4043) border.
    func testGoogleButtonBrandCompliant_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                allowGuestAccess: false,
                primaryColor: .purple
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Dark mode

    func testDefaultState_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    func testWithInputsState_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "secret123"
        ), colorScheme: .dark)
    }

    func testLoadingState_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "secret123",
            initialIsLoading: true
        ), colorScheme: .dark)
    }

    func testInvalidCredentialsState_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "wrongpass",
            initialErrorMessage: "Incorrect email or password."
        ), colorScheme: .dark)
    }

    func testNoGuestAccessState_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    func testGuestButtonVisible_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: true)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    func testGuestButtonHidden_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Custom theming

    /// Snapshot with a vivid orange-red primary color applied — verifies all primary buttons,
    /// links, and focus rings reflect the custom brand color via AuthTheme.
    func testCustomPrimaryColor() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpNetworkService()
        ))
    }

    func testCustomPrimaryColor_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Snapshot with a custom rounded system font applied — verifies all text uses the
    /// configured font when AuthClientConfiguration.font is non-nil.
    func testCustomFont() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpNetworkService()
        ))
    }

    func testCustomFont_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Snapshot verifying Google button uses themed transparent style (clear background,
    /// primary-tinted border) and NOT Google's brand-mandated white background.
    /// Purple primary color makes the border tint clearly non-default in the snapshot.
    func testGoogleButtonTransparentStyle() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: .purple
            )),
            networkService: NoOpNetworkService()
        ))
    }

    func testGoogleButtonTransparentStyle_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: .purple
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Full color token set (Task #71)

    /// Verifies no visual regression with all new color tokens at nil (defaults).
    func testLoginViewDefaultTheme() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
    }

    func testLoginViewDefaultTheme_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies custom surfaceColor renders in text field backgrounds with good contrast in both schemes.
    ///
    /// Uses `AuthColorTokens` to supply scheme-appropriate token sets — warm cream surface with
    /// dark text in light mode; dark warm surface with light text in dark mode — so that all
    /// labels, placeholders, icons, and buttons remain legible regardless of the active scheme.
    func testLoginViewCustomSurfaceColor() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                light: AuthColorTokens(
                    backgroundColor: Color(red: 0.98, green: 0.97, blue: 0.94),
                    surfaceColor: Color(red: 1.0, green: 0.9, blue: 0.7),
                    primaryTextColor: Color(red: 0.10, green: 0.10, blue: 0.10),
                    secondaryTextColor: Color(red: 0.45, green: 0.40, blue: 0.35)
                ),
                dark: AuthColorTokens(
                    backgroundColor: Color(red: 0.10, green: 0.08, blue: 0.04),
                    surfaceColor: Color(red: 0.28, green: 0.20, blue: 0.08),
                    primaryTextColor: Color(red: 0.95, green: 0.90, blue: 0.75),
                    secondaryTextColor: Color(red: 0.65, green: 0.58, blue: 0.45)
                )
            )),
            networkService: NoOpNetworkService()
        ))
    }

    func testLoginViewCustomSurfaceColor_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                light: AuthColorTokens(
                    backgroundColor: Color(red: 0.98, green: 0.97, blue: 0.94),
                    surfaceColor: Color(red: 1.0, green: 0.9, blue: 0.7),
                    primaryTextColor: Color(red: 0.10, green: 0.10, blue: 0.10),
                    secondaryTextColor: Color(red: 0.45, green: 0.40, blue: 0.35)
                ),
                dark: AuthColorTokens(
                    backgroundColor: Color(red: 0.10, green: 0.08, blue: 0.04),
                    surfaceColor: Color(red: 0.28, green: 0.20, blue: 0.08),
                    primaryTextColor: Color(red: 0.95, green: 0.90, blue: 0.75),
                    secondaryTextColor: Color(red: 0.65, green: 0.58, blue: 0.45)
                )
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies custom errorColor renders on the error row.
    func testLoginViewCustomErrorColor() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                errorColor: Color.orange
            )),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "wrongpass",
            initialErrorMessage: "Incorrect email or password."
        ))
    }

    func testLoginViewCustomErrorColor_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                errorColor: Color.orange
            )),
            networkService: NoOpNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "wrongpass",
            initialErrorMessage: "Incorrect email or password."
        ), colorScheme: .dark)
    }

    // MARK: - Localisation

    /// Verifies that default English localisation strings are rendered correctly
    /// in the login screen — title, subtitle, placeholders, buttons, and links.
    func testDefaultStrings() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
    }

    func testDefaultStrings_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Accessibility Large Text

    /// Verifies that LoginView remains usable at the largest iOS Dynamic Type category
    /// (accessibilityExtraExtraExtraLarge). All text must scale and the ScrollView must
    /// prevent content from being clipped — per design-system.md §12.
    ///
    /// On iOS the trait collection is overridden to `.accessibilityExtraExtraExtraLarge`.
    /// On macOS (no equivalent Dynamic Type system) the standard scale is captured at the
    /// same taller frame height used for the iOS variant.
    func testAccessibilityLargeText_iOS() {
#if canImport(UIKit)
        snapshotLargeText(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
#elseif canImport(AppKit)
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), frameHeight: 1200)
#endif
    }

    /// macOS-side companion to `testAccessibilityLargeText_iOS`. On macOS there is no
    /// iOS-style Dynamic Type category, so this captures the view at the taller frame
    /// used for large-text testing (1200pt) to verify no layout breakage at extended heights.
    func testAccessibilityLargeText_macOS() {
#if canImport(AppKit)
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), frameHeight: 1200)
#elseif canImport(UIKit)
        snapshotLargeText(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
#endif
    }

    // MARK: - Toast error state

    /// Verifies the toast error banner appears at the bottom of the screen for non-validation errors
    /// (e.g. network/server/provider errors from guest, Google, or Apple sign-in).
    func testToastErrorVisible() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            initialToastErrorMessage: "No internet connection. Please try again."
        ))
    }

    func testToastErrorVisible_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService(),
            initialToastErrorMessage: "No internet connection. Please try again."
        ), colorScheme: .dark)
    }

    // MARK: - Guest button hidden during guest session

    /// Verifies that the 'Continue as Guest' button is hidden when the current session
    /// is already .guest, even when allowGuestAccess is true.
    /// A guest tapping "Log in" to upgrade their account should not see a guest button —
    /// they are already a guest and can simply close the sheet.
    func testGuestButtonHidden_guestSession() {
        let manager = AuthManager(
            configuration: AuthClientConfiguration(allowGuestAccess: true),
            networkService: NoOpNetworkService(),
            tokenStore: InMemoryTokenStore()
        )
        manager.setGuestSession(uuid: UUID())
        snapshot(LoginView(
            authManager: manager,
            networkService: NoOpNetworkService()
        ))
    }

    func testGuestButtonHidden_guestSession_dark() {
        let manager = AuthManager(
            configuration: AuthClientConfiguration(allowGuestAccess: true),
            networkService: NoOpNetworkService(),
            tokenStore: InMemoryTokenStore()
        )
        manager.setGuestSession(uuid: UUID())
        snapshot(LoginView(
            authManager: manager,
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Dual light/dark theme (issue #102)

    /// Verifies that when a custom light token set is supplied, the Login view renders with
    /// the custom light colours (vivid green primary, pale yellow background) in light mode.
    func testCustomTheme_lightMode() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                light: AuthColorTokens(
                    primaryColor: Color(red: 0.0, green: 0.7, blue: 0.3),
                    backgroundColor: Color(red: 1.0, green: 0.98, blue: 0.88)
                ),
                dark: AuthColorTokens(
                    primaryColor: Color(red: 0.0, green: 0.9, blue: 0.5),
                    backgroundColor: Color(red: 0.08, green: 0.10, blue: 0.12)
                )
            )),
            networkService: NoOpNetworkService()
        ))
    }

    /// Verifies that when a custom dark token set is supplied, the Login view renders with
    /// the custom dark colours (vivid green primary, near-black background) in dark mode.
    func testCustomTheme_darkMode() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                light: AuthColorTokens(
                    primaryColor: Color(red: 0.0, green: 0.7, blue: 0.3),
                    backgroundColor: Color(red: 1.0, green: 0.98, blue: 0.88)
                ),
                dark: AuthColorTokens(
                    primaryColor: Color(red: 0.0, green: 0.9, blue: 0.5),
                    backgroundColor: Color(red: 0.08, green: 0.10, blue: 0.12)
                )
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Prompt spacing (issue #101)

    /// Verifies the register prompt row renders with correct visual spacing between the
    /// prompt text and the "Register" link — spacing is supplied by layout, not a string space.
    func testPromptSpacingPreserved() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ))
    }

    func testPromptSpacingPreserved_dark() {
        snapshot(LoginView(
            authManager: .make(),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Social sign-in flags (Task #121)

    /// Verifies the Sign in with Apple button is absent when allowAppleSignIn is false.
    func testLoginView_appleSignInHidden() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowAppleSignIn: false)),
            networkService: NoOpNetworkService()
        ))
    }

    func testLoginView_appleSignInHidden_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowAppleSignIn: false)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies the Sign in with Google button is absent when allowGoogleSignIn is false.
    func testLoginView_googleSignInHidden() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGoogleSignIn: false)),
            networkService: NoOpNetworkService()
        ))
    }

    func testLoginView_googleSignInHidden_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(allowGoogleSignIn: false)),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies both Apple and Google buttons are absent when both flags are false.
    /// The OR divider should also be absent since no social or guest button is visible.
    func testLoginView_bothProvidersHidden() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                allowGuestAccess: false,
                allowAppleSignIn: false,
                allowGoogleSignIn: false
            )),
            networkService: NoOpNetworkService()
        ))
    }

    func testLoginView_bothProvidersHidden_dark() {
        snapshot(LoginView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                allowGuestAccess: false,
                allowAppleSignIn: false,
                allowGoogleSignIn: false
            )),
            networkService: NoOpNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Snapshot helper

    private func snapshot(
        _ view: some View,
        colorScheme: ColorScheme = .light,
        frameHeight: CGFloat = 700,
        function: String = #function
    ) {
        let wrappedView = view.preferredColorScheme(colorScheme)

#if canImport(AppKit)
        let hosting = NSHostingView(rootView: wrappedView.frame(width: 440))
        hosting.appearance = NSAppearance(
            named: colorScheme == .dark ? .darkAqua : .aqua
        )
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: frameHeight)
        assertSnapshot(
            of: hosting,
            as: .image,
            named: "macOS-\(snapshotArch)",
            testName: function
        )
#elseif canImport(UIKit)
        let controller = UIHostingController(rootView: wrappedView)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: frameHeight == 700 ? 780 : frameHeight)
        assertSnapshot(
            of: controller.view,
            as: .image,
            named: "iOS-\(snapshotArch)",
            testName: function
        )
#endif
    }

    /// Snapshot helper that applies the largest iOS Dynamic Type category
    /// (`accessibilityExtraExtraExtraLarge`) via trait collection override.
    /// On macOS (where this category doesn't apply) the standard frame is used.
    private func snapshotLargeText(
        _ view: some View,
        colorScheme: ColorScheme = .light,
        function: String = #function
    ) {
        let wrappedView = view.preferredColorScheme(colorScheme)

#if canImport(UIKit)
        let controller = UIHostingController(rootView: wrappedView)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        // Apply the largest accessibility Dynamic Type category.
        let largeTypeTraits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light),
            UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        ])
        controller.setOverrideTraitCollection(largeTypeTraits, forChild: controller)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 1200)
        assertSnapshot(
            of: controller.view,
            as: .image,
            named: "iOS-\(snapshotArch)",
            testName: function
        )
#elseif canImport(AppKit)
        let hosting = NSHostingView(rootView: wrappedView.frame(width: 440))
        hosting.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 1200)
        assertSnapshot(
            of: hosting,
            as: .image,
            named: "macOS-\(snapshotArch)",
            testName: function
        )
#endif
    }
}

// MARK: - Test doubles

private struct NoOpNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func logout(refreshToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func deleteAccount(accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static func make() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
