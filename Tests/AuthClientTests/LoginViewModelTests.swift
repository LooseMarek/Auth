import Foundation
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class LoginViewModelTests: XCTestCase {

    func testSuccessfulLoginUpdatesAuthManager() async {
        let mockResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: .distantFuture,
            user: UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
        )
        let mock = LoginMockAuthNetworkService(result: .success(mockResponse))
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "secret123"
        await viewModel.login(authManager: authManager)

        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
        XCTAssertEqual(user.email, "test@example.com")
    }

    func testFailedLoginSetsErrorMessage() async {
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.invalidCredentials))
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "wrong-password"
        await viewModel.login(authManager: authManager)

        XCTAssertNotNil(viewModel.errorMessage)
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated after failed login, got \(authManager.session)")
            return
        }
    }

    func testLoadingStateDuringRequest() async {
        let (stream, continuation) = AsyncThrowingStream<AuthResponse, Error>.makeStream()
        let mock = SuspendingMockAuthNetworkService(stream: stream)
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "secret123"

        let loginTask = Task { await viewModel.login(authManager: authManager) }
        // Yield so the login task can start and set isLoading = true before its first await.
        await Task.yield()
        XCTAssertTrue(viewModel.isLoading, "isLoading should be true while request is in flight")

        let mockResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: .distantFuture,
            user: UserDTO(id: "user-1", email: "test@example.com", displayName: "Test User")
        )
        continuation.yield(mockResponse)
        continuation.finish()

        await loginTask.value
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after request completes")
    }
}

// MARK: - Test doubles

private final class LoginMockAuthNetworkService: AuthNetworkService, @unchecked Sendable {
    let result: Result<AuthResponse, Error>

    init(result: Result<AuthResponse, Error>) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        switch result {
        case .success(let response): return response
        case .failure(let error): throw error
        }
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

private final class SuspendingMockAuthNetworkService: AuthNetworkService, @unchecked Sendable {
    let stream: AsyncThrowingStream<AuthResponse, Error>

    init(stream: AsyncThrowingStream<AuthResponse, Error>) {
        self.stream = stream
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        for try await response in stream {
            return response
        }
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
