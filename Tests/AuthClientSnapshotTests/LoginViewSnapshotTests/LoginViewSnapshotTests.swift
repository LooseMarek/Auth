import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

// NOTE: LoginView snapshots use a fixed 390x700pt frame (iPhone 14 canvas width).
// All design system components use solid fills, system colour tokens, and SF Symbols —
// no LinearGradient, no Text rendered in snapshots, no .cornerRadius() —
// to ensure cross-architecture stability (Intel vs Apple Silicon).

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - testDefaultState

    func testDefaultState() {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let viewModel = LoginViewModel(
            authManager: authManager,
            networkClient: NeverCalledAuthNetworkClient()
        )

        let view = LoginView(viewModel: viewModel)
            .environment(authManager)

#if canImport(AppKit)
        let hostingView = NSHostingView(rootView: view.frame(width: 390))
        hostingView.frame = NSRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(
            of: hostingView,
            as: .image(perceptualPrecision: 0.95),
            named: "macOS"
        )
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(
            of: hostingController.view,
            as: .image(perceptualPrecision: 0.98),
            named: "iOS"
        )
#endif
    }

    // MARK: - testErrorState

    func testErrorState() {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let viewModel = LoginViewModel(
            authManager: authManager,
            networkClient: NeverCalledAuthNetworkClient()
        )
        viewModel.errorMessage = "Incorrect email or password."

        let view = LoginView(viewModel: viewModel)
            .environment(authManager)

#if canImport(AppKit)
        let hostingView = NSHostingView(rootView: view.frame(width: 390))
        hostingView.frame = NSRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(
            of: hostingView,
            as: .image(perceptualPrecision: 0.95),
            named: "macOS"
        )
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(
            of: hostingController.view,
            as: .image(perceptualPrecision: 0.98),
            named: "iOS"
        )
#endif
    }
}

// MARK: - NeverCalledAuthNetworkClient

/// A network client stub that fails the test if any method is actually called.
/// Safe to use in snapshot tests where no network interaction should occur.
private final class NeverCalledAuthNetworkClient: AuthNetworkClient, @unchecked Sendable {
    func login(request: LoginRequest) async throws -> AuthResponse {
        XCTFail("Network client should not be called in snapshot tests")
        throw AuthNetworkError.unknown
    }
}
