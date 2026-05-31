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
final class ResetPasswordViewSnapshotTests: XCTestCase {

    // MARK: - Light mode

    func testDefaultState() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService()
        ))
    }

    func testLoadingState() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialIsLoading: true
        ))
    }

    func testErrorState() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialErrorMessage: "Invalid or expired reset token. Please request a new one."
        ))
    }

    func testSuccessState() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialIsSuccess: true
        ))
    }

    // MARK: - Dark mode

    func testDefaultState_dark() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService()
        ), colorScheme: .dark)
    }

    func testLoadingState_dark() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialIsLoading: true
        ), colorScheme: .dark)
    }

    func testErrorState_dark() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialErrorMessage: "Invalid or expired reset token. Please request a new one."
        ), colorScheme: .dark)
    }

    func testSuccessState_dark() {
        snapshot(ResetPasswordView(
            authManager: .make(),
            networkService: NoOpResetPasswordNetworkService(),
            initialIsSuccess: true
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

private struct NoOpResetPasswordNetworkService: AuthNetworkService {
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
