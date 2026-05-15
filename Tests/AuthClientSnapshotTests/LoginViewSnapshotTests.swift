import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    func testDefaultState() {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let view = LoginView(authManager: authManager, networkService: NoOpAuthNetworkService())
        snapshotLoginView(view, named: "DefaultState")
    }

    func testErrorState() {
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        let errorService = ErrorAuthNetworkService(errorMessage: "Incorrect email or password.")
        let view = LoginView(
            authManager: authManager,
            networkService: errorService,
            prefilledEmail: "test@example.com",
            prefilledPassword: "wrongpass",
            initialErrorMessage: "Incorrect email or password."
        )
        snapshotLoginView(view, named: "ErrorState")
    }

    // MARK: - Helpers

    private func snapshotLoginView(_ view: some View, named name: String) {
#if canImport(AppKit)
        let hostingView = NSHostingView(rootView: view.frame(width: 440))
        hostingView.frame = NSRect(x: 0, y: 0, width: 440, height: 620)
        assertSnapshot(of: hostingView, as: .image(perceptualPrecision: 0.95), named: "\(name).macOS")
#elseif canImport(UIKit)
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: hostingController.view, as: .image(perceptualPrecision: 0.98), named: "\(name).iOS")
#endif
    }
}

// MARK: - Test doubles

private struct NoOpAuthNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}

private struct ErrorAuthNetworkService: AuthNetworkService {
    let errorMessage: String
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.invalidCredentials
    }
}
