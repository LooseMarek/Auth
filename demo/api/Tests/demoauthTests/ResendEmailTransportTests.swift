@testable import demoauth
import Foundation
import Testing

// MARK: - Mock URLProtocol

/// URLProtocol subclass used exclusively by ResendEmailTransportTests.
/// Intercepts all requests and calls a configurable handler.
final class MockURLProtocolForResend: URLProtocol, @unchecked Sendable {
    /// Set by each test to return the desired (response, data, error) tuple.
    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data?))?
    /// Last request seen by the mock — set before calling the handler so it can be inspected.
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocolForResend.lastRequest = request
        guard let handler = MockURLProtocolForResend.requestHandler else {
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

private func makeMockResendSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocolForResend.self]
    return URLSession(configuration: config)
}

/// Reads JSON body bytes from a request, handling both `httpBody` (set directly) and
/// `httpBodyStream` (used when the request flows through URLProtocol).
private func readBodyJSON(from request: URLRequest?) -> [String: String]? {
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
    return try? JSONDecoder().decode([String: String].self, from: d)
}

// MARK: - Tests

@Suite("ResendEmailTransport Tests", .serialized)
struct ResendEmailTransportTests {

    // MARK: - Request construction

    @Test("makeResendEmailTransport sends POST to https://api.resend.com/emails")
    func testResendTransportPostsToCorrectURL() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "test-key", fromEmail: "from@example.com", session: session)
        try await transport("to@example.com", "Test Subject", "Test body")

        let capturedURL = MockURLProtocolForResend.lastRequest?.url?.absoluteString
        #expect(capturedURL == "https://api.resend.com/emails", "transport must POST to https://api.resend.com/emails")
    }

    @Test("makeResendEmailTransport sets Authorization Bearer header")
    func testResendTransportSetsAuthorizationHeader() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "my-secret-key", fromEmail: "from@example.com", session: session)
        try await transport("to@example.com", "Test Subject", "Test body")

        let authHeader = MockURLProtocolForResend.lastRequest?.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer my-secret-key", "Authorization header must be 'Bearer <apiKey>'")
    }

    @Test("makeResendEmailTransport sets Content-Type application/json header")
    func testResendTransportSetsContentTypeHeader() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "test-key", fromEmail: "from@example.com", session: session)
        try await transport("to@example.com", "Test Subject", "Test body")

        let contentType = MockURLProtocolForResend.lastRequest?.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType == "application/json", "Content-Type header must be 'application/json'")
    }

    @Test("makeResendEmailTransport encodes from, to, subject, and text in JSON body")
    func testResendTransportEncodesCorrectJSONBody() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "test-key", fromEmail: "sender@example.com", session: session)
        try await transport("recipient@example.com", "Welcome!", "Click here to reset")

        let body = readBodyJSON(from: MockURLProtocolForResend.lastRequest)
        #expect(body?["from"] == "sender@example.com", "JSON body 'from' must match fromEmail")
        #expect(body?["to"] == "recipient@example.com", "JSON body 'to' must match recipient parameter")
        #expect(body?["subject"] == "Welcome!", "JSON body 'subject' must match subject parameter")
        #expect(body?["text"] == "Click here to reset", "JSON body 'text' must match body parameter")
    }

    // MARK: - Error handling

    @Test("makeResendEmailTransport throws ResendEmailError on non-2xx response")
    func testResendTransportThrowsOnNon2xxResponse() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 422,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "test-key", fromEmail: "from@example.com", session: session)

        await #expect(throws: ResendEmailError.self) {
            try await transport("to@example.com", "Subject", "Body")
        }
    }

    @Test("makeResendEmailTransport does not throw on 201 response")
    func testResendTransportSucceedsOn201() async throws {
        MockURLProtocolForResend.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://api.resend.com/emails")!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        let session = makeMockResendSession()
        let transport = makeResendEmailTransport(apiKey: "test-key", fromEmail: "from@example.com", session: session)

        // Must not throw — 201 is within 200..<300
        try await transport("to@example.com", "Subject", "Body")
    }
}
