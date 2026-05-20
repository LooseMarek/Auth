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

    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static func make() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
