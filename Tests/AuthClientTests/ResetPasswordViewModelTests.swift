import Foundation
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class ResetPasswordViewModelTests: XCTestCase {

    // MARK: - canSubmit validation

    func testValidFields_enablesSubmit() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "some-token"
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        XCTAssertTrue(viewModel.canSubmit, "canSubmit should be true when all fields are valid")
    }

    func testPasswordMismatch_disablesSubmit() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "tok"
        viewModel.newPassword = "abc12345"
        viewModel.confirmPassword = "different"

        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when passwords do not match")
    }

    func testEmptyToken_disablesSubmit() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = ""
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when token is empty")
    }

    func testShortPassword_disablesSubmit() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "tok"
        viewModel.newPassword = "short"
        viewModel.confirmPassword = "short"

        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when password is shorter than 8 characters")
    }

    // MARK: - Error clearing on field input

    func testTokenChange_clearsError() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(
            networkService: mock,
            initialErrorMessage: "Something went wrong. Please try again."
        )

        XCTAssertNotNil(viewModel.errorMessage, "Precondition: errorMessage should be set before typing")

        viewModel.token = "new-token"

        XCTAssertNil(viewModel.errorMessage, "Typing in the token field should clear errorMessage")
    }

    func testPasswordChange_clearsError() {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(
            networkService: mock,
            initialErrorMessage: "Something went wrong. Please try again."
        )

        viewModel.newPassword = "NewPassword1"

        XCTAssertNil(viewModel.errorMessage, "Typing in the password field should clear errorMessage")
    }

    // MARK: - submit — success

    func testSubmit_onSuccess_setsIsSuccess() async {
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "valid-token"
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        await viewModel.submit()

        XCTAssertTrue(viewModel.isSuccess, "isSuccess should be true after a successful reset")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on success")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    // MARK: - submit — errors

    func testSubmit_onInvalidToken_setsErrorMessage() async {
        let mock = MockResetPasswordNetworkService(result: .failure(AuthNetworkError.invalidResetToken))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "expired-token"
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        await viewModel.submit()

        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set when token is invalid or expired")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on invalidResetToken error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testSubmit_onNetworkError_setsErrorMessage() async {
        let mock = MockResetPasswordNetworkService(result: .failure(AuthNetworkError.networkUnavailable))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "some-token"
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        await viewModel.submit()

        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set on network error")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on network error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testSubmit_onServerError_setsErrorMessage() async {
        let mock = MockResetPasswordNetworkService(result: .failure(AuthNetworkError.serverError))
        let viewModel = ResetPasswordViewModel(networkService: mock)

        viewModel.token = "some-token"
        viewModel.newPassword = "NewP@ss1"
        viewModel.confirmPassword = "NewP@ss1"

        await viewModel.submit()

        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set on server error")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on server error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    // MARK: - back navigation

    func testBackToSignIn_invokesCallback() {
        var navigatedBack = false
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(
            networkService: mock,
            onBackToSignIn: { navigatedBack = true }
        )

        viewModel.backToSignIn()

        XCTAssertTrue(navigatedBack, "backToSignIn() should invoke the onBackToSignIn callback")
    }

    // MARK: - dismissToRoot wiring

    /// When `ResetPasswordView` is pushed from `ForgotPasswordView`'s success state,
    /// the view passes ForgotPasswordView's own `dismiss` closure as `dismissToRoot`
    /// into `ResetPasswordView.init`. The view wires `viewModel.onBackToSignIn` to that
    /// closure on `.onAppear`, so tapping "Back to log in" dismisses *both* levels
    /// (ResetPasswordView and ForgotPasswordView), returning directly to LoginView.
    ///
    /// At the ViewModel level this means: when `onBackToSignIn` is replaced with
    /// a custom root-dismiss closure, `backToSignIn()` fires that closure — not the
    /// original one.
    func testBackToSignIn_withReplacedDismissToRoot_invokesNewCallback() {
        // Given: a ViewModel initially configured with one callback…
        var originalFired = false
        var rootDismissFired = false
        let mock = MockResetPasswordNetworkService(result: .success(()))
        let viewModel = ResetPasswordViewModel(
            networkService: mock,
            onBackToSignIn: { originalFired = true }
        )

        // When: the view wires a "dismissToRoot" closure (simulating .onAppear logic)
        viewModel.onBackToSignIn = { rootDismissFired = true }
        viewModel.backToSignIn()

        // Then: only the replacement closure fires — confirming the wiring pattern used
        // by ResetPasswordView.body.onAppear to thread dismissToRoot through to the ViewModel.
        XCTAssertFalse(originalFired, "The original callback should NOT fire after onBackToSignIn is replaced")
        XCTAssertTrue(rootDismissFired, "The root-dismiss closure wired by the view should fire")
    }
}

// MARK: - Test doubles

private final class MockResetPasswordNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<Void, Error>

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func resetPassword(token: String, newPassword: String) async throws {
        switch result {
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
