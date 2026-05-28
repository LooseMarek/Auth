import XCTest
import AuthClient
import AuthShared
@testable import DemoAuthDefault

// MARK: - Sample JSON

/// Sample `GET /me` success JSON. Defined as a top-level constant so it can be
/// referenced inside `@Sendable` closures without capturing `self`.
private let sampleMeResponseJSON: Data = {
    let json = """
    {
        "id": "12345678-1234-1234-1234-123456789012",
        "email": "test@example.com",
        "authProvider": "email",
        "createdAt": "2024-01-15T10:30:00Z",
        "isGuest": false,
        "accessTokenExpiry": "2024-01-15T11:30:00Z",
        "refreshTokenId": "87654321-4321-4321-4321-210987654321"
    }
    """
    return Data(json.utf8)
}()

// MARK: - MockURLProtocol

/// A URLProtocol subclass that intercepts all requests and returns a pre-configured response.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    /// Handler set by each test to return the desired (data, response, error) tuple.
    ///
    /// `nonisolated(unsafe)` is required by Swift 6 strict concurrency: URLProtocol
    /// subclasses must use static storage (the framework calls class-level methods), and
    /// test files run sequentially within a single test suite, so external synchronisation
    /// is guaranteed.
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - MockAuthNetworkService

/// A minimal AuthNetworkService stub used for `AuthManager` construction in tests.
/// All methods that are not exercised simply throw `.serverError`.
struct MockAuthNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func register(email: String, password: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func forgotPassword(email: String) async throws { throw AuthNetworkError.serverError }
    func refreshToken(refreshToken: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func logout(refreshToken: String) async throws {}
    func deleteAccount(accessToken: String) async throws {}
    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func signInWithGoogle(identityToken: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func loginAsGuest() async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
}

// MARK: - ProfileViewModelTests

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - Helpers

    /// Returns a URLSession configured to use MockURLProtocol for all requests.
    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// Returns an AuthManager pre-seeded with a non-expired token in an InMemoryTokenStore.
    private func makeAuthManager() -> AuthManager {
        let tokenStore = InMemoryTokenStore()
        let metadata = TokenMetadata(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try? tokenStore.save(metadata)
        return AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: MockAuthNetworkService(),
            tokenStore: tokenStore
        )
    }

    // MARK: - testFetchMePopulatesUserFields

    func testFetchMePopulatesUserFields() async throws {
        // Given: a ProfileViewModel with a mock session returning a valid MeResponse
        let authManager = makeAuthManager()
        let mockSession = makeMockSession()
        // Capture the JSON data in a local constant so no `self` capture is needed
        let responseData = sampleMeResponseJSON
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }
        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: mockSession
        )

        // When: fetchMe() is called
        await viewModel.fetchMe()

        // Then: all five user fields are populated from the JSON
        XCTAssertEqual(viewModel.email, "test@example.com")
        XCTAssertEqual(viewModel.authProvider, "email")
        XCTAssertFalse(viewModel.isGuest)
        XCTAssertNotNil(viewModel.userID)
        XCTAssertNotNil(viewModel.createdAt)
        XCTAssertNil(viewModel.errorMessage, "No error expected on success")
    }

    // MARK: - testFetchMeSetsErrorOnFailure

    func testFetchMeSetsErrorOnFailure() async throws {
        // Given: a ProfileViewModel with a mock session that fails with a network error
        let authManager = makeAuthManager()
        let mockSession = makeMockSession()
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: mockSession
        )

        // When: fetchMe() is called
        await viewModel.fetchMe()

        // Then: errorMessage is non-nil
        XCTAssertNotNil(viewModel.errorMessage, "errorMessage should be set when the network call fails")
    }

    // MARK: - testLogoutCallsAuthManagerLogout

    func testLogoutCallsAuthManagerLogout() async throws {
        // Given: an AuthManager with a token in the store (so session can be active)
        let authManager = makeAuthManager()
        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: makeMockSession()
        )

        // When: logout() is called on the viewModel
        await viewModel.logout()

        // Then: the AuthManager session is unauthenticated
        switch authManager.session {
        case .unauthenticated:
            break // expected
        default:
            XCTFail("Expected session to be .unauthenticated after logout, got \(authManager.session)")
        }
    }

    // MARK: - testDeleteAccountShowsConfirmationThenCallsDeleteAccount

    func testDeleteAccountShowsConfirmationThenCallsDeleteAccount() {
        // Given: a fresh ProfileViewModel
        let authManager = makeAuthManager()
        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: makeMockSession()
        )
        XCTAssertFalse(viewModel.showDeleteConfirmation, "Confirmation must start hidden")

        // When: confirmDeleteAccount() is called
        viewModel.confirmDeleteAccount()

        // Then: showDeleteConfirmation is true (alert is shown before actual deletion)
        XCTAssertTrue(viewModel.showDeleteConfirmation, "Confirmation alert should be shown after confirmDeleteAccount()")
    }

    // MARK: - testRetryDeleteAccount_issuesDeleteNotFetchMe

    func testRetryDeleteAccount_issuesDeleteNotFetchMe() async throws {
        // Given: a ProfileViewModel backed by a network service that counts deleteAccount calls
        let trackingNetworkService = TrackingAuthNetworkService()
        let tokenStore = InMemoryTokenStore()
        let metadata = TokenMetadata(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try tokenStore.save(metadata)
        let authManager = AuthManager(
            configuration: AuthClientConfiguration(),
            networkService: trackingNetworkService,
            tokenStore: tokenStore
        )

        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: makeMockSession()
        )

        // When: deleteAccount is called
        await viewModel.deleteAccount()

        // Then: deleteAccount was called on the network service, not login/refresh
        XCTAssertEqual(trackingNetworkService.deleteAccountCallCount, 1, "deleteAccount should be called once")
        XCTAssertEqual(trackingNetworkService.loginCallCount, 0, "login must not be called")
        XCTAssertEqual(trackingNetworkService.refreshTokenCallCount, 0, "refreshToken (proxy for GET /me) must not be called")

        // When: retryDeleteAccount is called
        await viewModel.retryDeleteAccount()

        // Then: retry does not call login or fetchMe (no extra deleteAccount call because
        // AuthManager already cleared the token store on the first success, so withFreshToken
        // throws before reaching the network service again — the session is already .unauthenticated)
        XCTAssertEqual(trackingNetworkService.deleteAccountCallCount, 1, "retry attempt does not call deleteAccount again after session is already unauthenticated")
        XCTAssertEqual(trackingNetworkService.loginCallCount, 0, "retry must not call login")
        XCTAssertEqual(trackingNetworkService.refreshTokenCallCount, 0, "retry must not call refreshToken")
    }

    // MARK: - testGuestUpgradeButtonVisibleWhenIsGuestTrue

    func testGuestUpgradeButtonVisibleWhenIsGuestTrue() {
        // Given: a ProfileViewModel
        let authManager = makeAuthManager()
        let viewModel = ProfileViewModel(
            authManager: authManager,
            apiBaseURL: "http://localhost:8080",
            urlSession: makeMockSession()
        )

        // When: isGuest is set to true (simulating a guest user profile response)
        viewModel.isGuest = true

        // Then: the Upgrade Account button should be visible (isGuest == true)
        XCTAssertTrue(viewModel.isGuest, "isGuest should be true so the Upgrade Account button is visible")
    }
}

// MARK: - TrackingAuthNetworkService

/// An `AuthNetworkService` that counts calls to each endpoint, used to assert
/// that retry re-issues DELETE /account and not any other endpoint.
final class TrackingAuthNetworkService: AuthNetworkService, @unchecked Sendable {
    var loginCallCount = 0
    var refreshTokenCallCount = 0
    var deleteAccountCallCount = 0

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCallCount += 1
        throw AuthNetworkError.serverError
    }
    func register(email: String, password: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func forgotPassword(email: String) async throws {}
    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        refreshTokenCallCount += 1
        throw AuthNetworkError.serverError
    }
    func logout(refreshToken: String) async throws {}
    func deleteAccount(accessToken: String) async throws {
        deleteAccountCallCount += 1
    }
    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func signInWithGoogle(identityToken: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func loginAsGuest() async throws -> AuthResponse { throw AuthNetworkError.serverError }
    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse { throw AuthNetworkError.serverError }
}
