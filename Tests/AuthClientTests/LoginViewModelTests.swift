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

    // MARK: - Error routing (toast vs inline)

    func testGuestSignInError_showsToast_notInlineError() async {
        // Given: a network service that throws on loginAsGuest
        let mock = FailingGuestNetworkService(error: AuthNetworkError.serverError)
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: mock,
            tokenStore: InMemoryTokenStore()
        )

        // When: loginAsGuest is called and fails
        await viewModel.loginAsGuest(authManager: authManager)

        // Then: toast error is set, inline error remains nil
        XCTAssertNotNil(viewModel.toastErrorMessage, "Guest sign-in error should appear as toast")
        XCTAssertNil(viewModel.inlineErrorMessage, "Guest sign-in error must not appear inline")
    }

    func testGoogleSignInError_showsToast_notInlineError() {
        // Given: a view model
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.serverError))
        let viewModel = LoginViewModel(networkService: mock)

        // When: setGoogleSignInError is called
        viewModel.setGoogleSignInError(.serverError)

        // Then: toast error is set, inline error remains nil
        XCTAssertNotNil(viewModel.toastErrorMessage, "Google sign-in error should appear as toast")
        XCTAssertNil(viewModel.inlineErrorMessage, "Google sign-in error must not appear inline")
    }

    func testAppleSignInError_showsToast_notInlineError() {
        // Given: a view model
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.serverError))
        let viewModel = LoginViewModel(networkService: mock)

        // When: setAppleSignInError is called
        viewModel.setAppleSignInError(.serverError)

        // Then: toast error is set, inline error remains nil
        XCTAssertNotNil(viewModel.toastErrorMessage, "Apple sign-in error should appear as toast")
        XCTAssertNil(viewModel.inlineErrorMessage, "Apple sign-in error must not appear inline")
    }

    func testValidationError_showsInlineError_notToast() async {
        // Given: a network service that rejects credentials
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.invalidCredentials))
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        viewModel.email = "test@example.com"
        viewModel.password = "wrong-password"

        // When: login is called and throws invalidCredentials
        await viewModel.login(authManager: authManager)

        // Then: inline error is set, toast remains nil
        XCTAssertNotNil(viewModel.inlineErrorMessage, "Invalid credentials should appear inline")
        XCTAssertNil(viewModel.toastErrorMessage, "Invalid credentials must not appear as toast")
    }

    func testNetworkError_showsToast_notInlineError() async {
        // Given: a network service that throws networkUnavailable
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.networkUnavailable))
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())
        viewModel.email = "test@example.com"
        viewModel.password = "secret123"

        // When: login is called and throws networkUnavailable
        await viewModel.login(authManager: authManager)

        // Then: toast error is set, inline error remains nil
        XCTAssertNotNil(viewModel.toastErrorMessage, "Network error should appear as toast")
        XCTAssertNil(viewModel.inlineErrorMessage, "Network error must not appear inline")
    }

    func testDismissToast_clearsToastError() {
        // Given: a view model with an active toast error
        let mock = LoginMockAuthNetworkService(result: .failure(AuthNetworkError.serverError))
        let viewModel = LoginViewModel(networkService: mock)
        viewModel.setGoogleSignInError(.serverError)
        XCTAssertNotNil(viewModel.toastErrorMessage, "Precondition: toast error should be set")

        // When: dismissToast() is called
        viewModel.dismissToast()

        // Then: toast error is cleared
        XCTAssertNil(viewModel.toastErrorMessage, "Toast error should be nil after dismiss")
    }

    func testGuestLoadingStateDuringRequest() async {
        let (stream, continuation) = AsyncThrowingStream<AuthResponse, Error>.makeStream()
        let mock = SuspendingGuestMockAuthNetworkService(stream: stream)
        let viewModel = LoginViewModel(networkService: mock)
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: mock,
            tokenStore: InMemoryTokenStore()
        )

        let guestTask = Task { await viewModel.loginAsGuest(authManager: authManager) }
        await Task.yield()
        XCTAssertTrue(viewModel.isGuestLoading, "isGuestLoading should be true while guest request is in flight")

        let mockResponse = AuthResponse(
            accessToken: "guest-access-token",
            refreshToken: "guest-refresh-token",
            expiresAt: .distantFuture,
            user: UserDTO(id: "00000000-0000-0000-0000-000000000001", email: nil, displayName: nil)
        )
        continuation.yield(mockResponse)
        continuation.finish()

        await guestTask.value
        XCTAssertFalse(viewModel.isGuestLoading, "isGuestLoading should be false after guest request completes")
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

private final class FailingGuestNetworkService: AuthNetworkService, @unchecked Sendable {
    let error: Error

    init(error: Error) {
        self.error = error
    }

    func loginAsGuest() async throws -> AuthResponse { throw error }
    func login(email: String, password: String) async throws -> AuthResponse { throw error }
    func register(email: String, password: String) async throws -> AuthResponse { throw error }
    func forgotPassword(email: String) async throws { throw error }
    func refreshToken(refreshToken: String) async throws -> AuthResponse { throw error }
    func logout(refreshToken: String) async throws { throw error }
    func deleteAccount(accessToken: String) async throws { throw error }
    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse { throw error }
    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse { throw error }
    func signInWithGoogle(identityToken: String) async throws -> AuthResponse { throw error }
    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse { throw error }
    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse { throw error }
}

private final class SuspendingGuestMockAuthNetworkService: AuthNetworkService, @unchecked Sendable {
    let stream: AsyncThrowingStream<AuthResponse, Error>

    init(stream: AsyncThrowingStream<AuthResponse, Error>) {
        self.stream = stream
    }

    func loginAsGuest() async throws -> AuthResponse {
        for try await response in stream {
            return response
        }
        throw AuthNetworkError.serverError
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

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}
