import XCTest
import AuthShared
@testable import AuthClient

/// Unit tests for `AppleSignInHandler`.
///
/// These tests verify the three key behaviours of the Apple sign-in flow:
///  - A successful credential forwards the identity token to the server and updates state.
///  - A cancellation (`ASAuthorizationError.canceled`) leaves `AuthManager` state unchanged.
///  - A network error from POST /auth/apple surfaces as an error message on the ViewModel.
@MainActor
final class AppleSignInHandlerTests: XCTestCase {

    // MARK: - testSuccessfulTokenForwardsToServer

    func testSuccessfulTokenForwardsToServer() async {
        // Given: a mocked credential that returns a valid identity token
        let identityToken = "mock-apple-identity-token"
        let mockCredential = MockAppleIDCredential(identityTokenString: identityToken, fullName: nil)

        let mockResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: .distantFuture,
            user: UserDTO(id: "user-1", email: "apple@example.com", displayName: "Apple User")
        )
        let networkService = MockAppleAuthNetworkService(signInWithAppleResult: .success(mockResponse))
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = AppleSignInHandler(authManager: authManager, viewModel: viewModel)

        // When: a credential is received
        await handler.handleCredential(mockCredential)

        // Then: POST /auth/apple was called with the identity token
        XCTAssertEqual(networkService.signInWithAppleCallCount, 1)
        XCTAssertEqual(networkService.lastSignInWithAppleToken, identityToken)

        // And: AuthManager state is .authenticated
        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
    }

    // MARK: - testCancellationDoesNotChangeState

    func testCancellationDoesNotChangeState() async {
        // Given: an unauthenticated AuthManager
        let networkService = MockAppleAuthNetworkService(signInWithAppleResult: .failure(AuthNetworkError.serverError))
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = AppleSignInHandler(authManager: authManager, viewModel: viewModel)

        // When: the Apple auth sheet is cancelled
        await handler.handleCancellation()

        // Then: state is still .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated after cancellation, got \(authManager.session)")
            return
        }

        // And: no error message is shown
        XCTAssertNil(viewModel.errorMessage, "Cancellation must not set an error message")

        // And: the network service was never called
        XCTAssertEqual(networkService.signInWithAppleCallCount, 0)
    }

    // MARK: - testNetworkErrorSetsErrorOnViewModel

    func testNetworkErrorSetsErrorOnViewModel() async {
        // Given: a credential with a valid token but a network service that returns an error
        let identityToken = "mock-apple-identity-token"
        let mockCredential = MockAppleIDCredential(identityTokenString: identityToken, fullName: nil)

        let networkService = MockAppleAuthNetworkService(
            signInWithAppleResult: .failure(AuthNetworkError.networkUnavailable)
        )
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = AppleSignInHandler(authManager: authManager, viewModel: viewModel)

        // When: the credential is received but the server call fails
        await handler.handleCredential(mockCredential)

        // Then: an inline error message is set on the ViewModel
        XCTAssertNotNil(viewModel.errorMessage, "A network error must set an error message on the ViewModel")

        // And: AuthManager session is still .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated after network error, got \(authManager.session)")
            return
        }
    }
}

// MARK: - Test doubles

/// A mock that records calls to `signInWithApple` and returns a configurable result.
final class MockAppleAuthNetworkService: AuthNetworkService, @unchecked Sendable {

    // MARK: - Configurable behaviour

    var signInWithAppleResult: Result<AuthResponse, Error>

    // MARK: - Recorded calls

    var signInWithAppleCallCount = 0
    var lastSignInWithAppleToken: String?
    var upgradeGuestWithAppleCallCount = 0
    var lastUpgradeGuestToken: String?

    init(signInWithAppleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)) {
        self.signInWithAppleResult = signInWithAppleResult
    }

    // MARK: - AuthNetworkService

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        signInWithAppleCallCount += 1
        lastSignInWithAppleToken = identityToken
        return try signInWithAppleResult.get()
    }

    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse {
        upgradeGuestWithAppleCallCount += 1
        lastUpgradeGuestToken = identityToken
        return try signInWithAppleResult.get()
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

/// A minimal stand-in for `ASAuthorizationAppleIDCredential` that avoids importing
/// AuthenticationServices in the test double (the real type cannot be instantiated in tests).
struct MockAppleIDCredential: AppleIDCredentialProtocol {
    let identityTokenString: String?
    let fullName: PersonNameComponents?
}
