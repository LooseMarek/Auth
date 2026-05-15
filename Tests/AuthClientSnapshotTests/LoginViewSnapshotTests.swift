import SnapshotTesting
import SwiftUI
import XCTest
@testable import AuthClient

@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - Default state

    func test_loginView_defaultState() {
        let view = makeLoginView()
#if canImport(AppKit)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: host, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(of: host.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }

    // MARK: - Email error state

    func test_loginView_emailErrorVisible() {
        let (vm, view) = makeViewModelAndView()
        vm.emailErrorForSnapshot = "Please enter a valid email address."
#if canImport(AppKit)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: host, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(of: host.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }

    // MARK: - Server error state

    func test_loginView_serverErrorVisible() {
        let (vm, view) = makeViewModelAndView()
        vm.serverErrorForSnapshot = "Something went wrong. Please try again."
#if canImport(AppKit)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: host, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(of: host.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }

    // MARK: - Loading state

    func test_loginView_loadingState() {
        let (vm, view) = makeViewModelAndView()
        vm.isLoadingForSnapshot = true
#if canImport(AppKit)
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        assertSnapshot(of: host, as: .image(perceptualPrecision: 0.95), named: "macOS")
#elseif canImport(UIKit)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        assertSnapshot(of: host.view, as: .image(perceptualPrecision: 0.98), named: "iOS")
#endif
    }

    // MARK: - Helpers

    private func makeLoginView() -> some View {
        let stub = StubLoginAuthManaging()
        let config = AuthClientConfiguration()
        let vm = LoginViewModel(authManaging: stub, configuration: config)
        return LoginView(viewModel: vm)
    }

    private func makeViewModelAndView() -> (SnapshotLoginViewModel, LoginView<SnapshotLoginViewModel>) {
        let vm = SnapshotLoginViewModel()
        let view = LoginView(viewModel: vm)
        return (vm, view)
    }
}

// MARK: - Snapshot helpers

/// Observable wrapper that lets snapshot tests set visible state directly.
@Observable
@MainActor
final class SnapshotLoginViewModel: LoginViewModelProtocol {
    var email: String = ""
    var password: String = ""
    var isPasswordVisible: Bool = false
    var isLoading: Bool = false
    var emailError: String? = nil
    var passwordError: String? = nil
    var serverError: String? = nil
    var onForgotPassword: (() -> Void)? = nil
    var onRegister: (() -> Void)? = nil
    var onGuestAccess: (() -> Void)? = nil
    var configuration: AuthClientConfiguration = AuthClientConfiguration()
    var isFormValid: Bool { !email.isEmpty && !password.isEmpty }

    var emailErrorForSnapshot: String? {
        get { emailError }
        set { emailError = newValue }
    }

    var serverErrorForSnapshot: String? {
        get { serverError }
        set { serverError = newValue }
    }

    var isLoadingForSnapshot: Bool {
        get { isLoading }
        set { isLoading = newValue }
    }

    func loginAction() async {}
}

@MainActor
private final class StubLoginAuthManaging: LoginAuthManaging {
    func login(email: String, password: String) async throws {}
}
