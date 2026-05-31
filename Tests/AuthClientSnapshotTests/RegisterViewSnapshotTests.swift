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
final class RegisterViewSnapshotTests: XCTestCase {

    // MARK: - Placeholder correctness (issue #97)

    /// Verifies the Register view renders with the correct placeholder text in all three
    /// input fields: "Email", "Password", and "Re-enter password".
    func testEmptyState_correctPlaceholders() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testEmptyState_correctPlaceholders_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Light mode

    func testDefaultState() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testPasswordMismatchError() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "password1",
            prefilledConfirmPassword: "password2",
            initialConfirmPasswordError: "Passwords do not match."
        ))
    }

    // MARK: - Dark mode

    func testDefaultState_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    func testPasswordMismatchError_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService(),
            prefilledEmail: "user@example.com",
            prefilledPassword: "password1",
            prefilledConfirmPassword: "password2",
            initialConfirmPasswordError: "Passwords do not match."
        ), colorScheme: .dark)
    }

    // MARK: - Custom theming

    /// Snapshot with a vivid orange-red primary color — verifies primary button and links
    /// reflect the custom brand color via AuthTheme.
    func testCustomPrimaryColor() {
        snapshot(RegisterView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testCustomPrimaryColor_dark() {
        snapshot(RegisterView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    /// Snapshot with a custom rounded system font applied — verifies all text uses the
    /// configured font when AuthClientConfiguration.font is non-nil.
    func testCustomFont() {
        snapshot(RegisterView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testCustomFont_dark() {
        snapshot(RegisterView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Dual light/dark theme (issue #102)

    /// Verifies that when a custom light token set is supplied, the Register view renders with
    /// the custom light colours (vivid green primary, pale yellow background) in light mode.
    func testCustomTheme_lightMode() {
        snapshot(RegisterView(
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
            networkService: NoOpRegisterNetworkService()
        ))
    }

    /// Verifies that when a custom dark token set is supplied, the Register view renders with
    /// the custom dark colours (vivid green primary, near-black background) in dark mode.
    func testCustomTheme_darkMode() {
        snapshot(RegisterView(
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
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Toast error state (issue #122)

    /// Verifies the default Register view layout has no inline server error row —
    /// only field-level inline errors (email, password, confirm-password) remain.
    func testRegisterView_default() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testRegisterView_default_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    /// Verifies the toast error banner appears at the bottom of the screen for
    /// non-validation errors (e.g. network/server errors during registration).
    func testRegisterView_toastError() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService(),
            initialToastErrorMessage: "Something went wrong. Please try again."
        ))
    }

    func testRegisterView_toastError_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService(),
            initialToastErrorMessage: "Something went wrong. Please try again."
        ), colorScheme: .dark)
    }

    // MARK: - Prompt spacing (issue #101)

    /// Verifies the login prompt row renders with correct visual spacing between the
    /// prompt text and the "Log in" link — spacing is supplied by layout, not a string space.
    func testPromptSpacingPreserved() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ))
    }

    func testPromptSpacingPreserved_dark() {
        snapshot(RegisterView(
            authManager: .make(),
            networkService: NoOpRegisterNetworkService()
        ), colorScheme: .dark)
    }

    // MARK: - Snapshot helper

    private func snapshot(
        _ view: some View,
        colorScheme: ColorScheme = .light,
        function: String = #function
    ) {
        let wrappedView = view.preferredColorScheme(colorScheme)

#if canImport(AppKit)
        let hosting = NSHostingView(rootView: wrappedView.frame(width: 440))
        hosting.appearance = NSAppearance(
            named: colorScheme == .dark ? .darkAqua : .aqua
        )
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 700)
        assertSnapshot(
            of: hosting,
            as: .image,
            named: "macOS-\(snapshotArch)",
            testName: function
        )
#elseif canImport(UIKit)
        let controller = UIHostingController(rootView: wrappedView)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 780)
        assertSnapshot(
            of: controller.view,
            as: .image,
            named: "iOS-\(snapshotArch)",
            testName: function
        )
#endif
    }
}

// MARK: - Test doubles

private struct NoOpRegisterNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func resetPassword(token: String, newPassword: String) async throws {
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

    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static func make() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
