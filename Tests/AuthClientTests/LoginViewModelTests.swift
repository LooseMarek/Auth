import XCTest
@testable import AuthClient
import AuthShared

// MARK: - Mock AuthNetworkService

final class MockAuthNetworkService: AuthNetworkService, @unchecked Sendable {

    // Configurable result
    var loginResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)

    /// Optional delay in seconds to simulate an in-flight request.
    var delay: TimeInterval = 0

    func login(email: String, password: String) async throws -> AuthResponse {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return try loginResult.get()
    }
}

// MARK: - LoginViewModelTests

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var mockService: MockAuthNetworkService!
    private var authManager: AuthManager!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockAuthNetworkService()
        authManager = AuthManager(configuration: AuthClientConfiguration())
    }

    override func tearDown() async throws {
        mockService = nil
        authManager = nil
        try await super.tearDown()
    }

    // MARK: - testSuccessfulLoginUpdatesAuthManager

    /// Mocked network returns a success AuthResponse;
    /// authManager.session transitions to .authenticated(user).
    func testSuccessfulLoginUpdatesAuthManager() async throws {
        let user = UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
        let response = AuthResponse(
            accessToken: "access.jwt",
            refreshToken: "refresh.jwt",
            expiresAt: Date(timeIntervalSinceNow: 3600),
            user: user
        )
        mockService.loginResult = .success(response)

        let viewModel = LoginViewModel(networkService: mockService, authManager: authManager)
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        await viewModel.login()

        guard case .authenticated(let returnedUser) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(returnedUser.id, user.id)
        XCTAssertEqual(returnedUser.email, user.email)
    }

    // MARK: - testFailedLoginSetsErrorMessage

    /// Mocked network throws invalidCredentials (simulates 401);
    /// viewModel.errorMessage is set to a non-nil value.
    func testFailedLoginSetsErrorMessage() async throws {
        mockService.loginResult = .failure(AuthNetworkError.invalidCredentials)

        let viewModel = LoginViewModel(networkService: mockService, authManager: authManager)
        viewModel.email = "test@example.com"
        viewModel.password = "wrongpassword"

        await viewModel.login()

        XCTAssertNotNil(viewModel.errorMessage, "Expected errorMessage to be set on failed login")
    }

    // MARK: - testLoadingStateDuringRequest

    /// isLoading is true while the async request is in flight and false after it completes.
    func testLoadingStateDuringRequest() async throws {
        let user = UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
        let response = AuthResponse(
            accessToken: "access.jwt",
            refreshToken: "refresh.jwt",
            expiresAt: Date(timeIntervalSinceNow: 3600),
            user: user
        )
        mockService.loginResult = .success(response)
        mockService.delay = 0.05 // 50ms delay to allow observation

        let viewModel = LoginViewModel(networkService: mockService, authManager: authManager)
        viewModel.email = "test@example.com"
        viewModel.password = "password123"

        XCTAssertFalse(viewModel.isLoading, "isLoading should start as false")

        // Start login in a separate task so we can observe isLoading mid-flight
        let loginTask = Task { @MainActor in
            await viewModel.login()
        }

        // Yield briefly to allow the login task to start and set isLoading = true
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        let observedLoadingTrue = viewModel.isLoading

        await loginTask.value

        XCTAssertTrue(observedLoadingTrue, "isLoading should be true during the request")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after the request completes")
    }
}
