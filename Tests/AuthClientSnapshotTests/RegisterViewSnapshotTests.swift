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
