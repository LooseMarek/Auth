import Foundation
import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class RegisterViewModelTests: XCTestCase {

    // MARK: - testLogInButtonTapped_navigatesToLogin

    func testLogInButtonTapped_navigatesToLogin() {
        var navigateToLoginCalled = false
        let mock = MockRegisterNetworkService(result: .success(makeAuthResponse()))
        let viewModel = RegisterViewModel(
            networkService: mock,
            onNavigateToLogin: { navigateToLoginCalled = true }
        )

        viewModel.navigateToLogin()

        XCTAssertTrue(navigateToLoginCalled, "onNavigateToLogin callback should be invoked when navigateToLogin() is called")
    }

    // MARK: - Existing tests

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

    func testGuestSession_register_callsUpgradeNotRegister() async {
        let guestUUID = UUID()
        let response = makeAuthResponse()
        let mock = MockRegisterNetworkService(upgradeResult: .success(response))
        let viewModel = RegisterViewModel(networkService: mock)
        let tokenStore = InMemoryTokenStore()
        try? tokenStore.save(TokenMetadata(
            accessToken: "guest-access-token",
            refreshToken: "guest-refresh-token",
            expiresAt: .distantFuture
        ))
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: mock,
            tokenStore: tokenStore
        )
        authManager.setGuestSession(uuid: guestUUID)

        viewModel.email = "new@example.com"
        viewModel.password = "secret123"
        viewModel.confirmPassword = "secret123"
        await viewModel.register(authManager: authManager)

        XCTAssertFalse(mock.registerCalled, "register() must NOT be called when upgrading a guest")
        XCTAssertTrue(mock.upgradeGuestCalled, "upgradeGuestWithEmail() must be called for guest sessions")
        XCTAssertEqual(mock.upgradeGuestUUID, guestUUID, "upgrade must use the existing guest UUID")
        guard case .authenticated = authManager.session else {
            XCTFail("Expected .authenticated after guest upgrade, got \(authManager.session)")
            return
        }
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

    // MARK: - Password minimum length validation

    func testPasswordTooShort_showsValidationError() async {
        let mock = MockRegisterNetworkService(result: .success(makeAuthResponse()))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "abc"        // 3 characters — below minimum
        viewModel.confirmPassword = "abc"
        await viewModel.register(authManager: authManager)

        XCTAssertNotNil(viewModel.passwordError, "passwordError should be set when password is shorter than 8 characters")
        XCTAssertEqual(viewModel.passwordError, "Password must be at least 8 characters.")
        XCTAssertFalse(mock.registerCalled, "No network call should be made when password is too short")
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated, got \(authManager.session)")
            return
        }
    }

    func testPasswordExactlyMinLength_noValidationError() async {
        let mock = MockRegisterNetworkService(result: .success(makeAuthResponse()))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "abcdefgh"   // exactly 8 characters
        viewModel.confirmPassword = "abcdefgh"
        await viewModel.register(authManager: authManager)

        XCTAssertNil(viewModel.passwordError, "passwordError must be nil when password is exactly 8 characters")
        XCTAssertTrue(mock.registerCalled, "Network call should proceed when password meets the minimum length")
    }

    func testPasswordValidationClears_whenLengthMet() async {
        // First: trigger the too-short error
        let mock = MockRegisterNetworkService(result: .success(makeAuthResponse()))
        let viewModel = RegisterViewModel(networkService: mock)
        let authManager = AuthManager(configuration: AuthClientConfiguration())

        viewModel.email = "test@example.com"
        viewModel.password = "short"       // 5 characters
        viewModel.confirmPassword = "short"
        await viewModel.register(authManager: authManager)
        XCTAssertNotNil(viewModel.passwordError, "Precondition: passwordError must be set for too-short password")

        // Then: correct the password to meet the requirement
        viewModel.password = "longenough"  // 10 characters
        viewModel.confirmPassword = "longenough"
        await viewModel.register(authManager: authManager)

        XCTAssertNil(viewModel.passwordError, "passwordError must clear when the password is corrected to 8+ characters")
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
    let upgradeResult: Result<AuthResponse, Error>
    private(set) var registerCalled = false
    private(set) var upgradeGuestCalled = false
    private(set) var upgradeGuestUUID: UUID?

    init(
        result: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError),
        upgradeResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)
    ) {
        self.result = result
        self.upgradeResult = upgradeResult
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
        upgradeGuestCalled = true
        upgradeGuestUUID = guestUUID
        switch upgradeResult {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }
}
