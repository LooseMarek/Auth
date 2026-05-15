import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    class MockAuthClient: AuthClientProtocol {
        func login(email: String, password: String) async throws {
            // No-op
        }
    }

    func testLoginViewSnapshot() {
        let config = AuthClientConfiguration()
        let viewModel = LoginViewModel(client: MockAuthClient())
        let view = LoginView(viewModel: viewModel, configuration: config)
        #if canImport(AppKit)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 300, height: 250)
        assertSnapshot(of: hosting, as: .image(perceptualPrecision: 0.95), named: "macOS")
        #elseif canImport(UIKit)
        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = CGRect(x: 0, y: 0, width: 300, height: 250)
        assertSnapshot(of: hosting.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
        #endif
    }
}
