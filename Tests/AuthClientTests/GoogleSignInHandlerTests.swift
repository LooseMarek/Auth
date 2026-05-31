import XCTest
import AuthShared
@testable import AuthClient

/// Unit tests for `GoogleSignInHandler`.
///
/// These tests verify the three key behaviours of the Google sign-in flow:
///  - A successful credential forwards the identity token to the server and updates state.
///  - A cancellation leaves `AuthManager` state unchanged and no error is shown.
///  - A network error from POST /auth/google surfaces as an error message on the ViewModel.
///  - A missing GIDClientID / URL scheme degrades gracefully without crashing.
///
/// `GIDSignIn` cannot be invoked in tests (requires a real UIViewController / NSWindow),
/// so `GoogleSignInHandler` depends on a `GoogleIDTokenProvider` protocol that the
/// tests inject with a mock implementation.
@MainActor
final class GoogleSignInHandlerTests: XCTestCase {

    // MARK: - testHandleCredential_validGoogleCredential_succeeds

    /// Verifies a mocked valid Google credential produces an authenticated state.
    ///
    /// This is the primary happy-path test: a real token comes back from the provider,
    /// the network service accepts it, and `AuthManager` transitions to `.authenticated`.
    func testHandleCredential_validGoogleCredential_succeeds() async {
        // Given: a mock token provider that returns a valid identity token
        let identityToken = "valid-google-identity-token"
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

        // When: sign-in completes with a valid credential
        await handler.handleSignIn()

        // Then: POST /auth/google was called exactly once with the identity token
        XCTAssertEqual(networkService.signInWithGoogleCallCount, 1)
        XCTAssertEqual(networkService.lastSignInWithGoogleToken, identityToken)

        // And: AuthManager state is .authenticated
        guard case .authenticated(let user) = authManager.session else {
            XCTFail("Expected .authenticated, got \(authManager.session)")
            return
        }
        XCTAssertEqual(user.id, "user-1")
    }

    // MARK: - testMissingClientID_doesNotCrash

    /// Verifies the service handles a nil/missing GIDClientID gracefully without crashing.
    ///
    /// When the Google SDK's URL scheme is missing or the GIDClientID is a placeholder,
    /// `GIDSignInTokenProvider.fetchIDToken()` guards against `nil` configuration and
    /// throws `GoogleSignInCancellationError`. This test verifies that path results in a
    /// silent no-op rather than an uncaught exception or user-visible error.
    func testMissingClientID_doesNotCrash() async {
        // Given: a token provider that simulates a missing GIDClientID / URL scheme by
        // throwing GoogleSignInCancellationError — the same path the production
        // GIDSignInTokenProvider takes when GIDSignIn.sharedInstance.configuration is nil.
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

        // When: sign-in is attempted with a missing/invalid client ID
        await handler.handleSignIn()

        // Then: no error is surfaced to the user — this must be a silent no-op
        XCTAssertNil(viewModel.errorMessage, "Missing GIDClientID must not show a validation error to the user")
        XCTAssertNil(viewModel.toastErrorMessage, "Missing GIDClientID must not show a toast error to the user")

        // And: session remains .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated, got \(authManager.session)")
            return
        }

        // And: the network service was never called
        XCTAssertEqual(networkService.signInWithGoogleCallCount, 0)
    }

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

    // MARK: - testMissingGIDClientIDTreatedAsCancellation

    func testMissingGIDClientIDTreatedAsCancellation() async {
        // Given: a token provider that simulates a missing GIDClientID by throwing
        // GoogleSignInCancellationError — the same error the production
        // GIDSignInTokenProvider throws when GIDSignIn.sharedInstance.configuration is nil.
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

        // When: sign-in is attempted (simulating missing GIDClientID)
        await handler.handleSignIn()

        // Then: no error is surfaced — this must be a silent no-op
        XCTAssertNil(viewModel.errorMessage, "Missing GIDClientID must not show an error to the user")

        // And: session remains .unauthenticated
        guard case .unauthenticated = authManager.session else {
            XCTFail("Expected .unauthenticated, got \(authManager.session)")
            return
        }

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

        // Then: a toast error message is set on the ViewModel (network errors are non-validation → toast)
        XCTAssertNotNil(viewModel.toastErrorMessage, "A network error must set a toast error message on the ViewModel")

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

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        upgradeGuestWithGoogleCallCount += 1
        lastUpgradeGuestToken = identityToken
        return try signInWithGoogleResult.get()
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
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

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }
}
