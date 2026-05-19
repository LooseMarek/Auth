import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {

    func testSuccessfulSubmitTransitionsToSuccessState() async {
        let mock = MockForgotPasswordNetworkService(result: .success(()))
        let viewModel = ForgotPasswordViewModel(networkService: mock)

        viewModel.email = "user@example.com"
        await viewModel.submit()

        XCTAssertTrue(viewModel.isSuccess, "isSuccess should be true after a successful submit")
        XCTAssertNil(viewModel.errorMessage, "errorMessage should be nil on success")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }

    func testNetworkErrorSetsErrorMessage() async {
        let mock = MockForgotPasswordNetworkService(result: .failure(AuthNetworkError.networkUnavailable))
        let viewModel = ForgotPasswordViewModel(networkService: mock)

        viewModel.email = "user@example.com"
        await viewModel.submit()

        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set on network error")
        XCTAssertFalse(viewModel.isSuccess, "isSuccess should remain false on error")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after submit completes")
    }
}

// MARK: - Test doubles

private final class MockForgotPasswordNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<Void, Error>

    init(result: Result<Void, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        switch result {
        case .success: return
        case .failure(let error): throw error
        }
    }
}
