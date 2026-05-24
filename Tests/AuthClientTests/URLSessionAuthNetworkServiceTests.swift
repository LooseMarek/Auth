import XCTest
import AuthShared
@testable import AuthClient

/// Unit tests for `URLSessionAuthNetworkService`.
///
/// All network calls are intercepted by `MockURLProtocolForNetworkService`, which
/// returns a configured (data, response, error) tuple without making real network
/// requests.
///
/// The tests verify:
/// - Correct HTTP method and path per endpoint
/// - Correct JSON body encoding
/// - `AuthResponse` decoding on 2xx
/// - Error mapping: 401 → `.invalidCredentials`, 409 → `.emailTaken`,
///   network error → `.networkUnavailable`, other non-2xx → `.serverError`

// MARK: - MockURLProtocolForNetworkService

/// URLProtocol subclass used exclusively by URLSessionAuthNetworkServiceTests.
/// Named with a unique suffix to avoid test-isolation conflicts with the similarly
/// named class in ProfileViewModelTests.
final class MockURLProtocolForNetworkService: URLProtocol, @unchecked Sendable {
    /// Set by each test to return the desired (response, data, error) tuple.
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocolForNetworkService.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data { client?.urlProtocol(self, didLoad: data) }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Helpers

private let baseURL = "http://localhost:8080"

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocolForNetworkService.self]
    return URLSession(configuration: config)
}

/// Reads the JSON body from a `URLRequest`, handling both `httpBody` (set directly)
/// and `httpBodyStream` (used by URLSession when the request goes through URLProtocol).
private func readBodyJSON(from request: URLRequest?) -> [String: Any]? {
    guard let request else { return nil }
    let data: Data?
    if let body = request.httpBody {
        data = body
    } else if let stream = request.httpBodyStream {
        stream.open()
        var bytes = [UInt8]()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 4096)
            if count > 0 { bytes.append(contentsOf: UnsafeBufferPointer(start: buffer, count: count)) }
        }
        stream.close()
        data = Data(bytes)
    } else {
        return nil
    }
    guard let d = data else { return nil }
    return try? JSONSerialization.jsonObject(with: d) as? [String: Any]
}

private func makeAuthResponseJSON(
    accessToken: String = "access-token",
    refreshToken: String = "refresh-token",
    expiresAt: String = "2030-01-01T00:00:00Z",
    userID: String = "11111111-1111-1111-1111-111111111111",
    email: String = "user@example.com"
) -> Data {
    let json = """
    {
        "accessToken": "\(accessToken)",
        "refreshToken": "\(refreshToken)",
        "expiresAt": "\(expiresAt)",
        "user": {
            "id": "\(userID)",
            "email": "\(email)",
            "displayName": null
        }
    }
    """
    return Data(json.utf8)
}

private func makeHTTPResponse(url: URL, status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
}

// MARK: - URLSessionAuthNetworkServiceTests

final class URLSessionAuthNetworkServiceTests: XCTestCase {

    private var sut: URLSessionAuthNetworkService!

    /// Static storage for the captured request — `nonisolated(unsafe)` required by
    /// Swift 6 strict concurrency because URLProtocol uses class-level static storage,
    /// and test suites run sequentially so external synchronisation is guaranteed.
    nonisolated(unsafe) static var lastCapturedRequest: URLRequest?

    override func setUp() {
        super.setUp()
        sut = URLSessionAuthNetworkService(baseURL: baseURL, session: makeMockSession())
        URLSessionAuthNetworkServiceTests.lastCapturedRequest = nil
    }

    override func tearDown() {
        MockURLProtocolForNetworkService.requestHandler = nil
        URLSessionAuthNetworkServiceTests.lastCapturedRequest = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - login — success

    func testLoginSendsPostToAuthLogin() async throws {
        // Given: server returns a valid AuthResponse
        let responseData = makeAuthResponseJSON()
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), responseData)
        }

        // When
        _ = try await sut.login(email: "user@example.com", password: "secret")

        // Then: correct method and path
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "POST")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/login")
    }

    func testLoginEncodesEmailAndPasswordInBody() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), makeAuthResponseJSON())
        }

        // When
        _ = try await sut.login(email: "test@example.com", password: "mypassword")

        // Then: body contains email and password
        // URLSession moves httpBody to httpBodyStream before URLProtocol sees it.
        let body = readBodyJSON(from: URLSessionAuthNetworkServiceTests.lastCapturedRequest)
        XCTAssertEqual(body?["email"] as? String, "test@example.com")
        XCTAssertEqual(body?["password"] as? String, "mypassword")
    }

    func testLoginDecodesAuthResponse() async throws {
        // Given
        let responseData = makeAuthResponseJSON(accessToken: "my-access", userID: "22222222-2222-2222-2222-222222222222")
        MockURLProtocolForNetworkService.requestHandler = { request in
            (makeHTTPResponse(url: request.url!, status: 200), responseData)
        }

        // When
        let response = try await sut.login(email: "u@example.com", password: "pw")

        // Then
        XCTAssertEqual(response.accessToken, "my-access")
        XCTAssertEqual(response.user.id, "22222222-2222-2222-2222-222222222222")
    }

    // MARK: - login — error mapping

    func testLoginThrowsInvalidCredentialsOn401() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { request in
            (makeHTTPResponse(url: request.url!, status: 401), nil)
        }

        // When / Then
        do {
            _ = try await sut.login(email: "u@example.com", password: "wrong")
            XCTFail("Expected .invalidCredentials error")
        } catch AuthNetworkError.invalidCredentials {
            // expected
        }
    }

    func testLoginThrowsEmailTakenOn409() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { request in
            (makeHTTPResponse(url: request.url!, status: 409), nil)
        }

        // When / Then
        do {
            _ = try await sut.login(email: "u@example.com", password: "pw")
            XCTFail("Expected .emailTaken error")
        } catch AuthNetworkError.emailTaken {
            // expected
        }
    }

    func testLoginThrowsServerErrorOnNon2xx() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { request in
            (makeHTTPResponse(url: request.url!, status: 500), nil)
        }

        // When / Then
        do {
            _ = try await sut.login(email: "u@example.com", password: "pw")
            XCTFail("Expected .serverError")
        } catch AuthNetworkError.serverError {
            // expected
        }
    }

    func testLoginThrowsNetworkUnavailableOnURLError() async throws {
        // Given: URLProtocol throws a network connection error
        MockURLProtocolForNetworkService.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // When / Then
        do {
            _ = try await sut.login(email: "u@example.com", password: "pw")
            XCTFail("Expected .networkUnavailable error")
        } catch AuthNetworkError.networkUnavailable {
            // expected
        }
    }

    // MARK: - forgotPassword

    func testForgotPasswordSendsPostToAuthForgotPassword() async throws {
        // Given: server returns 200 with no body (success)
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.forgotPassword(email: "reset@example.com")

        // Then
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "POST")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/forgot-password")
    }

    func testForgotPasswordEncodesEmailInBody() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.forgotPassword(email: "reset@example.com")

        // Then
        let body = readBodyJSON(from: URLSessionAuthNetworkServiceTests.lastCapturedRequest)
        XCTAssertEqual(body?["email"] as? String, "reset@example.com")
    }

    // MARK: - logout

    func testLogoutSendsPostToAuthLogout() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.logout(refreshToken: "my-refresh-token")

        // Then
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "POST")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/logout")
    }

    func testLogoutEncodesRefreshTokenInBody() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.logout(refreshToken: "refresh-abc")

        // Then
        let body = readBodyJSON(from: URLSessionAuthNetworkServiceTests.lastCapturedRequest)
        XCTAssertEqual(body?["refreshToken"] as? String, "refresh-abc")
    }

    // MARK: - deleteAccount

    func testDeleteAccountSendsDeleteToAuthAccount() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.deleteAccount(accessToken: "my-access-token")

        // Then
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "DELETE")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/account")
    }

    func testDeleteAccountSetsBearerTokenHeader() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), nil)
        }

        // When
        try await sut.deleteAccount(accessToken: "bearer-token-xyz")

        // Then
        XCTAssertEqual(
            URLSessionAuthNetworkServiceTests.lastCapturedRequest?.value(forHTTPHeaderField: "Authorization"),
            "Bearer bearer-token-xyz"
        )
    }

    // MARK: - register

    func testRegisterSendsPostToAuthRegister() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), makeAuthResponseJSON())
        }

        // When
        _ = try await sut.register(email: "new@example.com", password: "newpass")

        // Then
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "POST")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/register")
    }

    // MARK: - loginAsGuest

    func testLoginAsGuestSendsPostToAuthGuest() async throws {
        // Given
        MockURLProtocolForNetworkService.requestHandler = { [self] request in
            URLSessionAuthNetworkServiceTests.lastCapturedRequest = request
            return (makeHTTPResponse(url: request.url!, status: 200), makeAuthResponseJSON())
        }

        // When
        _ = try await sut.loginAsGuest()

        // Then
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.httpMethod, "POST")
        XCTAssertEqual(URLSessionAuthNetworkServiceTests.lastCapturedRequest?.url?.path, "/auth/guest")
    }
}
