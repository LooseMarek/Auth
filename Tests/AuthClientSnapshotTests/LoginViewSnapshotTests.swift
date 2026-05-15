import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - States

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

    // MARK: - Snapshot helper

    /// Renders `view` as a snapshot on both macOS and iOS (whichever platform this run targets).
    /// Appearance is forced to light mode so baselines are consistent regardless of system setting.
    /// File name: `{testFunctionName}.{macOS|iOS}.png`
    private func snapshot(
        _ view: some View,
        function: String = #function   // captured at call site — yields the test method name
    ) {
#if canImport(AppKit)
        let hosting = NSHostingView(rootView: view.frame(width: 440))
        // Force Aqua (light mode) regardless of the system appearance.
        hosting.appearance = NSAppearance(named: .aqua)
        hosting.frame = NSRect(x: 0, y: 0, width: 440, height: 700)
        assertSnapshot(
            of: hosting,
            as: .image(perceptualPrecision: 0.95),
            named: "macOS",
            testName: function
        )
#elseif canImport(UIKit)
        let controller = UIHostingController(rootView: view)
        // Force light mode so baselines don't depend on the simulator's appearance setting.
        controller.overrideUserInterfaceStyle = .light
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 780)
        assertSnapshot(
            of: controller.view,
            as: .image(perceptualPrecision: 0.98),
            named: "iOS",
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
}

private extension AuthManager {
    static func make() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}
