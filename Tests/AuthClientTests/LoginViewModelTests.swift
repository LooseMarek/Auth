import XCTest
import Observation
import SwiftUI
@testable import AuthClient

@MainActor
final class LoginViewModelTests: XCTestCase {

    class MockAuthClient: AuthClientProtocol {
        var didLogin = false
        var loggedInEmail: String? = nil
        var loggedInPassword: String? = nil
        var shouldFail = false

        func login(email: String, password: String) async throws {
            didLogin = true
            loggedInEmail = email
            loggedInPassword = password
            if shouldFail {
                throw NSError(domain: "Test", code: 1, userInfo: nil)
            }
        }
    }

    func testInitialState() {
        let client = MockAuthClient()
        let vm = LoginViewModel(client: client)
        XCTAssertEqual(vm.email, "")
        XCTAssertEqual(vm.password, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoginSuccess() async {
        let client = MockAuthClient()
        let vm = LoginViewModel(client: client)
        vm.email = "test@example.com"
        vm.password = "password"

        await vm.login()

        XCTAssertTrue(client.didLogin)
        XCTAssertEqual(client.loggedInEmail, "test@example.com")
        XCTAssertEqual(client.loggedInPassword, "password")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testLoginFailure() async {
        let client = MockAuthClient()
        client.shouldFail = true
        let vm = LoginViewModel(client: client)
        vm.email = "user@example.com"
        vm.password = "secret"

        await vm.login()

        XCTAssertTrue(client.didLogin)
        XCTAssertEqual(client.loggedInEmail, "user@example.com")
        XCTAssertEqual(client.loggedInPassword, "secret")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNotNil(vm.errorMessage)
    }
}
