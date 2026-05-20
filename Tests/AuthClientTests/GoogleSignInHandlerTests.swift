import XCTest
import AuthShared
@testable import AuthClient

/// Unit tests for `GoogleSignInHandler`.
///
/// These tests verify the three key behaviours of the Google sign-in flow:
///  - A successful credential forwards the identity token to the server and updates state.
///  - A cancellation leaves `AuthManager` state unchanged and no error is shown.
///  - A network error from POST /auth/google surfaces as an error message on the ViewModel.
///
/// `GIDSignIn` cannot be invoked in tests (requires a real UIViewController / NSWindow),
/// so `GoogleSignInHandler` depends on a `GoogleIDTokenProvider` protocol that the
/// tests inject with a mock implementation.
@MainActor
final class GoogleSignInHandlerTests: XCTestCase {

    // MARK: - testSuccessfulTokenForwardsToServer

    func testSuccessfulTokenForwardsToServer() async {
        // Given: a mock token provider that returns a valid identity token
        let identityToken = "mock-google-identity-token"
        let tokenProvider = MockGoogleIDTokenProvider(result: .success(identityToken))

        let mockResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: .distantFuture,
            user: UserDTO(id: "user-1", email: "google@example.com", displayName: "Google User")
        )
        let networkService = MockGoogleAuthNetworkService(signInWithGoogleResult: .success(mockResponse))
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = GoogleSignInHandler(
            authManager: authManager,
            viewModel: viewModel,
            tokenProvider: tokenProvider
        )

        // When: sign-in completes with a valid token
        await handler.handleSignIn()

        // Then: POST /auth/google was called with the identity token
        XCTAssertEqual(networkService.signInWithGoogleCallCount, 1)
        XCTAssertEqual(networkService.lastSignInWithGoogleToken, identityToken)

        // And: AuthManager state is .authenticated
        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
    }

    // MARK: - testCancellationDoesNotChangeState

    func testCancellationDoesNotChangeState() async {
        // Given: a token provider that returns a cancellation
        let tokenProvider = MockGoogleIDTokenProvider(result: .failure(GoogleSignInCancellationError()))
        let networkService = MockGoogleAuthNetworkService(
            signInWithGoogleResult: .failure(AuthNetworkError.serverError)
        )
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = GoogleSignInHandler(
            authManager: authManager,
            viewModel: viewModel,
            tokenProvider: tokenProvider
        )

        // When: the Google auth sheet is cancelled
        await handler.handleSignIn()

        // Then: state is still .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated after cancellation, got \(authManager.session)")
            return
        }

        // And: no error message is shown
        XCTAssertNil(viewModel.errorMessage, "Cancellation must not set an error message")

        // And: the network service was never called
        XCTAssertEqual(networkService.signInWithGoogleCallCount, 0)
    }

    // MARK: - testNetworkErrorSetsErrorOnViewModel

    func testNetworkErrorSetsErrorOnViewModel() async {
        // Given: a token provider that returns a valid token, but the network service errors
        let identityToken = "mock-google-identity-token"
        let tokenProvider = MockGoogleIDTokenProvider(result: .success(identityToken))
        let networkService = MockGoogleAuthNetworkService(
            signInWithGoogleResult: .failure(AuthNetworkError.networkUnavailable)
        )
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: networkService,
            tokenStore: InMemoryTokenStore()
        )
        let viewModel = LoginViewModel(networkService: networkService)
        let handler = GoogleSignInHandler(
            authManager: authManager,
            viewModel: viewModel,
            tokenProvider: tokenProvider
        )

        // When: the token is received but the server call fails
        await handler.handleSignIn()

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

/// A mock token provider that returns a configurable result (token or error).
final class MockGoogleIDTokenProvider: GoogleIDTokenProvider, @unchecked Sendable {
    var result: Result<String, Error>

    init(result: Result<String, Error>) {
        self.result = result
    }

    func fetchIDToken() async throws -> String {
        return try result.get()
    }
}

/// A mock network service that records calls to `signInWithGoogle` and returns
/// a configurable result. All other methods throw `serverError`.
final class MockGoogleAuthNetworkService: AuthNetworkService, @unchecked Sendable {

    // MARK: - Configurable behaviour

    var signInWithGoogleResult: Result<AuthResponse, Error>

    // MARK: - Recorded calls

    var signInWithGoogleCallCount = 0
    var lastSignInWithGoogleToken: String?
    var upgradeGuestWithGoogleCallCount = 0
    var lastUpgradeGuestToken: String?

    init(signInWithGoogleResult: Result<AuthResponse, Error> = .failure(AuthNetworkError.serverError)) {
        self.signInWithGoogleResult = signInWithGoogleResult
    }

    // MARK: - AuthNetworkService

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        signInWithGoogleCallCount += 1
        lastSignInWithGoogleToken = identityToken
        return try signInWithGoogleResult.get()
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, identityToken: String) async throws -> AuthResponse {
        upgradeGuestWithGoogleCallCount += 1
        lastUpgradeGuestToken = identityToken
        return try signInWithGoogleResult.get()
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse {
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
}
