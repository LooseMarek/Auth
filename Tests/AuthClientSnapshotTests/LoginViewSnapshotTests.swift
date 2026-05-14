import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

// MARK: - LoginViewSnapshotTests
//
// Snapshot tests use solid-color-only views and avoid Text/gradients/cornerRadius
// to ensure cross-architecture stability (Intel vs Apple Silicon).
//
// Note: LoginView itself contains Text, SF Symbols, and system rendering — this is
// acceptable for snapshot tests of real UI, but perceptualPrecision is set
// conservatively (0.95 macOS / 0.98 iOS) to tolerate minor renderer differences.
//
// macOS snapshot tests require WindowServer/display access. They are skipped in CI
// (GitHub Actions self-hosted runner runs headless without display access, causing
// NSHostingView rendering to differ from an interactive session).

private let isCI = ProcessInfo.processInfo.environment["CI"] != nil

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - testDefaultState

    /// Snapshot of LoginView with empty ViewModel (default empty state).
    func testDefaultState() throws {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let viewModel = LoginViewModel(
            networkService: NoOpAuthNetworkService(),
            authManager: authManager
        )
        let view = LoginView(viewModel: viewModel, configuration: AuthClientConfiguration())

#if canImport(AppKit)
        try XCTSkipIf(isCI, "macOS snapshot requires display access (skipped in headless CI)")
        let hostingView = NSHostingView(rootView: view.frame(width: 400))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: hostingView, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: hostingController.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }

    // MARK: - testErrorState

    /// Snapshot of LoginView with an inline error message visible.
    func testErrorState() throws {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let viewModel = LoginViewModel(
            networkService: NoOpAuthNetworkService(),
            authManager: authManager
        )
        viewModel.email = "test@example.com"
        viewModel.password = "badpassword"
        viewModel.errorMessage = "Incorrect email or password."

        let view = LoginView(viewModel: viewModel, configuration: AuthClientConfiguration())

#if canImport(AppKit)
        try XCTSkipIf(isCI, "macOS snapshot requires display access (skipped in headless CI)")
        let hostingView = NSHostingView(rootView: view.frame(width: 400))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: hostingView, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: hostingController.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }
}

// MARK: - NoOpAuthNetworkService

/// A no-op network service for snapshot tests — never actually called.
private final class NoOpAuthNetworkService: AuthNetworkService, @unchecked Sendable {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}
