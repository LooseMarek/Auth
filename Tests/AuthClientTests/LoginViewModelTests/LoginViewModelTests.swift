import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeAuthManager() -> AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }

    private func makeSuccessResponse() -> AuthResponse {
        AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date(timeIntervalSinceNow: 3600),
            user: UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
        )
    }

    // MARK: - testSuccessfulLoginUpdatesAuthManager

    func testSuccessfulLoginUpdatesAuthManager() async throws {
        let authManager = makeAuthManager()
        let mockNetwork = MockAuthNetworkClient()
        mockNetwork.loginResult = .success(makeSuccessResponse())

        let sut = LoginViewModel(authManager: authManager, networkClient: mockNetwork)
        sut.email = "test@example.com"
        sut.password = "secret123"

        await sut.login()

        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected session to be .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.email, "test@example.com")
    }

    // MARK: - testFailedLoginSetsErrorMessage

    func testFailedLoginSetsErrorMessage() async throws {
        let authManager = makeAuthManager()
        let mockNetwork = MockAuthNetworkClient()
        mockNetwork.loginResult = .failure(AuthNetworkError.invalidCredentials)

        let sut = LoginViewModel(authManager: authManager, networkClient: mockNetwork)
        sut.email = "test@example.com"
        sut.password = "wrongpassword"

        await sut.login()

        XCTAssertNotNil(sut.errorMessage, "errorMessage should be set after a failed login")
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected session to remain .unauthenticated, got \(authManager.session)")
            return
        }
    }

    // MARK: - testLoadingStateDuringRequest

    func testLoadingStateDuringRequest() async throws {
        let authManager = makeAuthManager()
        let mockNetwork = MockAuthNetworkClient()

        // Use a continuation to pause delivery of the result so we can observe isLoading == true
        var resumeContinuation: CheckedContinuation<Void, Never>?
        mockNetwork.loginHook = { continuation in
            resumeContinuation = continuation
        }
        mockNetwork.loginResult = .success(makeSuccessResponse())

        let sut = LoginViewModel(authManager: authManager, networkClient: mockNetwork)
        sut.email = "test@example.com"
        sut.password = "secret123"

        XCTAssertFalse(sut.isLoading, "isLoading should be false before login")

        let loginTask = Task { await sut.login() }

        // Yield to let login() start and block on the hook
        await Task.yield()
        await Task.yield()

        XCTAssertTrue(sut.isLoading, "isLoading should be true during request")

        // Release the network mock
        resumeContinuation?.resume()
        await loginTask.value

        XCTAssertFalse(sut.isLoading, "isLoading should be false after request completes")
    }
}

// MARK: - MockAuthNetworkClient

final class MockAuthNetworkClient: AuthNetworkClient, @unchecked Sendable {

    var loginResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.unknown)
    /// Optional hook: called with a continuation that must be resumed to unblock the mock call.
    var loginHook: ((CheckedContinuation<Void, Never>) -> Void)?

    func login(request: LoginRequest) async throws -> AuthResponse {
        if let hook = loginHook {
            await withCheckedContinuation { continuation in
                hook(continuation)
            }
        }
        switch loginResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
