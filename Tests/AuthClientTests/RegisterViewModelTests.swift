import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class RegisterViewModelTests: XCTestCase {

    func testPasswordMismatchSetsError() async {
        let mock = MockRegisterNetworkService(result: .success(makeAuthResponse()))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "password1"
        viewModel.confirmPassword = "password2"
        await viewModel.register(authManager: authManager)

        XCTAssertNotNil(viewModel.confirmPasswordError, "confirmPasswordError should be set on mismatch")
        XCTAssertEqual(viewModel.confirmPasswordError, "Passwords do not match.")
        XCTAssertFalse(mock.registerCalled, "No network call should be made when passwords mismatch")
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated, got \(authManager.session)")
            return
        }
    }

    func testSuccessfulRegistrationUpdatesAuthManager() async {
        let response = makeAuthResponse()
        let mock = MockRegisterNetworkService(result: .success(response))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "secret123"
        viewModel.confirmPassword = "secret123"
        await viewModel.register(authManager: authManager)

        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.confirmPasswordError)
    }

    func testDuplicateEmailSetsError() async {
        let mock = MockRegisterNetworkService(result: .failure(AuthNetworkError.emailTaken))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "existing@example.com"
        viewModel.password = "secret123"
        viewModel.confirmPassword = "secret123"
        await viewModel.register(authManager: authManager)

        XCTAssertNotNil(viewModel.emailError, "emailError should be set on 409 duplicate email")
        XCTAssertEqual(viewModel.emailError, "An account with this email already exists.")
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated, got \(authManager.session)")
            return
        }
    }
}

// MARK: - Helpers

private func makeAuthResponse() -> AuthResponse {
    AuthResponse(
        accessToken: "access-token",
        refreshToken: "refresh-token",
        expiresAt: .distantFuture,
        user: UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
    )
}

// MARK: - Test doubles

private final class MockRegisterNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<AuthResponse, Error>
    private(set) var registerCalled = false

    init(result: Result<AuthResponse, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        registerCalled = true
        switch result {
        case .success(let response): return response
        case .failure(let error): throw error
        }
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
}
