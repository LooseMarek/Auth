import Foundation
import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class ForgotPasswordViewSnapshotTests: XCTestCase {

    // MARK: - Light mode

    func testDefaultState() {
        snapshot(ForgotPasswordView(
            authManager: .make(),
            networkService: NoOpForgotPasswordNetworkService()
        ))
    }

    func testSuccessState() {
        snapshot(ForgotPasswordView(
            authManager: .make(),
            networkService: NoOpForgotPasswordNetworkService(),
            initialIsSuccess: true
        ))
    }

    /// Test AC-required name: verifies the success confirmation renders correctly.
    func testForgotPasswordView_successState() {
        snapshot(ForgotPasswordView(
            authManager: .make(),
            networkService: NoOpForgotPasswordNetworkService(),
            initialIsSuccess: true
        ))
    }

    // MARK: - Dark mode

    func testDefaultState_dark() {
        snapshot(ForgotPasswordView(
            authManager: .make(),
            networkService: NoOpForgotPasswordNetworkService()
        ), colorScheme: .dark)
    }

    func testSuccessState_dark() {
        snapshot(ForgotPasswordView(
            authManager: .make(),
            networkService: NoOpForgotPasswordNetworkService(),
            initialIsSuccess: true
        ), colorScheme: .dark)
    }

    // MARK: - Custom theming

    /// Snapshot with a vivid orange-red primary color — verifies submit button and back links
    /// reflect the custom brand color via AuthTheme.
    func testCustomPrimaryColor() {
        snapshot(ForgotPasswordView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpForgotPasswordNetworkService()
        ))
    }

    func testCustomPrimaryColor_dark() {
        snapshot(ForgotPasswordView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                primaryColor: Color(red: 0.8, green: 0.2, blue: 0.0)
            )),
            networkService: NoOpForgotPasswordNetworkService()
        ), colorScheme: .dark)
    }

    /// Snapshot with a custom rounded system font applied — verifies all text uses the
    /// configured font when AuthClientConfiguration.font is non-nil.
    func testCustomFont() {
        snapshot(ForgotPasswordView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpForgotPasswordNetworkService()
        ))
    }

    func testCustomFont_dark() {
        snapshot(ForgotPasswordView(
            authManager: AuthManager(configuration: AuthClientConfiguration(
                font: .system(.body, design: .rounded)
            )),
            networkService: NoOpForgotPasswordNetworkService()
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
            named: "macOS",
            testName: function
        )
#elseif canImport(UIKit)
        let controller = UIHostingController(rootView: wrappedView)
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 780)
        assertSnapshot(
            of: controller.view,
            as: .image,
            named: "iOS",
            testName: function
        )
#endif
    }
}

// MARK: - Test doubles

private struct NoOpForgotPasswordNetworkService: AuthNetworkService {
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
