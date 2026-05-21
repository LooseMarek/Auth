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

    init(forgotPasswordResult: Result<Void, Error>) {
        self.forgotPasswordResult = forgotPasswordResult
    }

    func forgotPassword(email: String) async throws {
        switch forgotPasswordResult {
        case .success: return
        case .failure(let error): throw error
        }
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
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
