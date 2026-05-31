import Foundation
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class ChangePasswordViewModelTests: XCTestCase {

    // MARK: - canSubmit

    func testCanSubmit_whenAllFieldsFilledAndPasswordsMatch_returnsTrue() {
        let mock = MockChangePasswordNetworkService(result: .success(()))
        let viewModel = ChangePasswordViewModel(networkService: mock)
        viewModel.currentPassword = "OldPass1"
        viewModel.newPassword = "NewPass1"
        viewModel.confirmPassword = "NewPass1"

        XCTAssertTrue(viewModel.canSubmit, "canSubmit should be true when all fields are filled and passwords match")
    }

    func testCanSubmit_whenPasswordsMismatch_returnsFalse() {
        let mock = MockChangePasswordNetworkService(result: .success(()))
        let viewModel = ChangePasswordViewModel(networkService: mock)
        viewModel.currentPassword = "OldPass1"
        viewModel.newPassword = "NewPass1"
        viewModel.confirmPassword = "DifferentPass"

        XCTAssertFalse(viewModel.canSubmit, "canSubmit should be false when newPassword and confirmPassword do not match")
    }

    func testCanSubmit_whenAnyFieldEmpty_returnsFalse() {
        let mock = MockChangePasswordNetworkService(result: .success(()))

        // Missing currentPassword
        let vm1 = ChangePasswordViewModel(networkService: mock)
        vm1.currentPassword = ""
        vm1.newPassword = "NewPass1"
        vm1.confirmPassword = "NewPass1"
        XCTAssertFalse(vm1.canSubmit, "canSubmit should be false when currentPassword is empty")

        // Missing newPassword
        let vm2 = ChangePasswordViewModel(networkService: mock)
        vm2.currentPassword = "OldPass1"
        vm2.newPassword = ""
        vm2.confirmPassword = ""
        XCTAssertFalse(vm2.canSubmit, "canSubmit should be false when newPassword is empty")

        // Missing confirmPassword
        let vm3 = ChangePasswordViewModel(networkService: mock)
        vm3.currentPassword = "OldPass1"
        vm3.newPassword = "NewPass1"
        vm3.confirmPassword = ""
        XCTAssertFalse(vm3.canSubmit, "canSubmit should be false when confirmPassword is empty")
    }

    // MARK: - submit()

    func testSubmit_onSuccess_setsIsSuccess() async {
        let mock = MockChangePasswordNetworkService(result: .success(()))
        let viewModel = ChangePasswordViewModel(networkService: mock)
        viewModel.currentPassword = "OldPass1"
        viewModel.newPassword = "NewPass1"
        viewModel.confirmPassword = "NewPass1"

        await viewModel.submit()

        XCTAssertTrue(viewModel.isSuccess, "isSuccess should be true after a successful change password")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on success")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testSubmit_onError_setsToastErrorMessage() async {
        let mock = MockChangePasswordNetworkService(result: .failure(AuthNetworkError.invalidCredentials))
        let viewModel = ChangePasswordViewModel(networkService: mock)
        viewModel.currentPassword = "WrongPass"
        viewModel.newPassword = "NewPass1"
        viewModel.confirmPassword = "NewPass1"

        await viewModel.submit()

        XCTAssertNotNil(viewModel.toastErrorMessage, "toastErrorMessage should be set on failure")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should NOT be set from submit (toast is used instead)")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testDismissToast_clearsToastErrorMessage() {
        let mock = MockChangePasswordNetworkService(result: .success(()))
        let viewModel = ChangePasswordViewModel(
            networkService: mock,
            initialToastErrorMessage: "Some error"
        )

        viewModel.dismissToast()

        XCTAssertNil(viewModel.toastErrorMessage, "dismissToast() should clear toastErrorMessage")
    }

    // MARK: - backToSignIn()

    func testBackToSignIn_callsOnBackToSignIn() {
        let mock = MockChangePasswordNetworkService(result: .success(()))
        var callbackInvoked = false
        let viewModel = ChangePasswordViewModel(networkService: mock)
        viewModel.onBackToSignIn = { callbackInvoked = true }

        viewModel.backToSignIn()

        XCTAssertTrue(callbackInvoked, "backToSignIn() should invoke the onBackToSignIn callback")
    }
}

// MARK: - Test doubles

private final class MockChangePasswordNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<Void, Error>

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws {
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
}
