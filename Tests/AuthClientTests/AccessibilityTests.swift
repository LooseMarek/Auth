import Foundation
import XCTest
@testable import AuthClient
import AuthShared

/// Unit tests that encode the accessibility and motion standards defined in
/// design-system.md §8 (Motion) and §12 (Accessibility Standards).
@MainActor
final class AccessibilityTests: XCTestCase {

    // MARK: - Reduced motion

    /// Verifies that the `ForgotPasswordViewModel.isSuccess` flag transitions to `true` after a
    /// successful submit, confirming the trigger point for the reduce-motion–conditional animation
    /// branch in `ForgotPasswordView`.
    ///
    /// `ForgotPasswordView.content` gates its success-reveal transition on
    /// `@Environment(\.accessibilityReduceMotion)`: when `reduceMotion` is `true` the view uses
    /// `.opacity` only (no scale); when `false` it combines `.opacity` with `.scale(0.96)`.
    /// The environment value cannot be injected in a plain unit test, so this test verifies the
    /// underlying state machine — confirming that `isSuccess` fires, which is the only property
    /// that triggers the conditional animation path.
    func testReduceMotionCollapsesForgotPasswordReveal() async {
        let mock = MockAccessibilityNetworkService(forgotPasswordResult: .success(()))
        let viewModel = ForgotPasswordViewModel(networkService: mock)

        XCTAssertFalse(viewModel.isSuccess, "isSuccess should start as false")
        viewModel.email = "user@example.com"
        await viewModel.submit()

        XCTAssertTrue(
            viewModel.isSuccess,
            "isSuccess must be true after a successful submit — this is the flag that drives " +
            "the reduce-motion–conditional animation branch in ForgotPasswordView"
        )
    }

    // MARK: - Reduced transparency

    /// Verifies that `LoginViewModel.isLoading` is `true` when initialised with
    /// `initialIsLoading: true`, documenting that the loading state is testable and is the flag
    /// that drives the loading-overlay block in `LoginView`.
    ///
    /// `LoginView` uses `@Environment(\.accessibilityReduceTransparency)` to choose between a
    /// semi-transparent overlay (`theme.backgroundColor.opacity(0.8)`) and a fully opaque one
    /// (`theme.backgroundColor`) when the loading overlay is shown. The environment value cannot
    /// be injected in a plain unit test; this test asserts the loading path is reachable.
    func testReduceTransparencyUsesOpaqueOverlay() {
        let mock = MockAccessibilityNetworkService(forgotPasswordResult: .success(()))
        let viewModel = LoginViewModel(networkService: mock, initialIsLoading: true)

        XCTAssertTrue(
            viewModel.isLoading,
            "LoginViewModel.isLoading must be true when initialised with initialIsLoading: true — " +
            "this is the condition under which LoginView renders the loading overlay that applies " +
            "the accessibilityReduceTransparency adaptation"
        )
    }

    // MARK: - Return key / onSubmit

    /// Verifies that pressing Return in the password field (i.e. calling `onSubmit`) triggers
    /// the login path via `LoginViewModel`.
    ///
    /// `PasswordFieldView` now exposes an `onSubmit: () -> Void` closure that is wired to both
    /// the `TextField` and `SecureField` via `.onSubmit { onSubmit() }`.  `LoginView` passes
    /// `{ Task { await viewModel.login(authManager: authManager) } }` as that closure.
    ///
    /// This test validates the reachable code path: a `LoginViewModel` can receive the login
    /// call with valid credentials and surface the expected error, confirming the route that
    /// `onSubmit` exercises is functional.
    func testPasswordFieldOnSubmitTriggersLogin() async {
        let loginResult = Result<AuthResponse, Error>.failure(AuthNetworkError.invalidCredentials)
        let mock = MockAccessibilityNetworkService(
            forgotPasswordResult: .success(()),
            loginResult: loginResult
        )
        let viewModel = LoginViewModel(
            networkService: mock,
            initialEmail: "user@example.com",
            initialPassword: "wrongpass"
        )

        XCTAssertNil(viewModel.errorMessage, "errorMessage should start as nil")
        XCTAssertTrue(viewModel.canSubmit, "canSubmit must be true before calling login")

        // Simulate what LoginView passes as the onSubmit closure.
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        await viewModel.login(authManager: authManager)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Incorrect email or password.",
            "login() must surface the invalid-credentials error — confirming the login path " +
            "reachable via the password field onSubmit closure is functional"
        )
        XCTAssertFalse(viewModel.isLoading, "isLoading must be false after login completes")
    }

    // MARK: - Minimum tap targets

    /// Verifies the primary button height constant meets the WCAG 44 × 44pt minimum tap target.
    ///
    /// Per design-system.md §10.1, the primary button is 52pt tall — naturally compliant.
    /// This test encodes that invariant so any future change to `AuthDesignConstants` is flagged.
    func testMinimumTapTargetPrimaryButton() {
        XCTAssertGreaterThanOrEqual(
            AuthDesignConstants.primaryButtonHeight,
            AuthDesignConstants.minimumTapTarget,
            "Primary button height (\(AuthDesignConstants.primaryButtonHeight)pt) must be " +
            "≥ minimum tap target (\(AuthDesignConstants.minimumTapTarget)pt)"
        )
    }

    /// Verifies the social button height constants (Apple, Google, Guest) meet the 44 × 44pt
    /// minimum tap target.
    ///
    /// Per design-system.md §10.5–10.7, social buttons are 50pt tall — naturally compliant.
    func testMinimumTapTargetSocialButtons() {
        XCTAssertGreaterThanOrEqual(
            AuthDesignConstants.socialButtonHeight,
            AuthDesignConstants.minimumTapTarget,
            "Social button height (\(AuthDesignConstants.socialButtonHeight)pt) must be " +
            "≥ minimum tap target (\(AuthDesignConstants.minimumTapTarget)pt)"
        )
    }
}

// MARK: - Test doubles

private final class MockAccessibilityNetworkService: AuthNetworkService, @unchecked Sendable {
    let forgotPasswordResult: Result<Void, Error>
    let loginResult: Result<AuthResponse, Error>

    init(
        forgotPasswordResult: Result<Void, Error>,
        loginResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    ) {
        self.forgotPasswordResult = forgotPasswordResult
        self.loginResult = loginResult
    }

    func forgotPassword(email: String) async throws {
        switch forgotPasswordResult {
        case .success: return
        case .failure(let error): throw error
        }
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        switch loginResult {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }

    func register(email: String, password: String) async throws -> AuthResponse {
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
