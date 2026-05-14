import XCTest
@testable import AuthShared

final class AuthProviderTests: XCTestCase {

    // MARK: - Encoding

    func testEmailEncodesToCorrectRawString() throws {
        let data = try JSONEncoder().encode(AuthProvider.email)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(json, "\"email\"")
    }

    func testAppleEncodesToCorrectRawString() throws {
        let data = try JSONEncoder().encode(AuthProvider.apple)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(json, "\"apple\"")
    }

    func testGoogleEncodesToCorrectRawString() throws {
        let data = try JSONEncoder().encode(AuthProvider.google)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(json, "\"google\"")
    }

    // MARK: - Decoding

    func testEmailStringDecodesToEmailCase() throws {
        let data = Data("\"email\"".utf8)
        let provider = try JSONDecoder().decode(AuthProvider.self, from: data)
        XCTAssertEqual(provider, .email)
    }

    func testAppleStringDecodesToAppleCase() throws {
        let data = Data("\"apple\"".utf8)
        let provider = try JSONDecoder().decode(AuthProvider.self, from: data)
        XCTAssertEqual(provider, .apple)
    }

    func testGoogleStringDecodesToGoogleCase() throws {
        let data = Data("\"google\"".utf8)
        let provider = try JSONDecoder().decode(AuthProvider.self, from: data)
        XCTAssertEqual(provider, .google)
    }

    // MARK: - Unknown value

    func testUnrecognisedStringThrowsDecodingError() {
        let data = Data("\"facebook\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AuthProvider.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "Expected DecodingError, got \(type(of: error))")
        }
    }
}
