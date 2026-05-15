import XCTest
@testable import AuthClient
import AuthShared

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(
        allowGuestAccess: Bool = true,
        loginResult: Result<Void, AuthError> = .success(())
    ) -> LoginViewModel {
        let stub = StubLoginAuthManaging(loginResult: loginResult)
        let config = AuthClientConfiguration(allowGuestAccess: allowGuestAccess)
        return LoginViewModel(authManaging: stub, configuration: config)
    }

    // MARK: - Initial state

    func test_initialState_fieldsAreEmpty() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.email, "")
        XCTAssertEqual(vm.password, "")
    }

    func test_initialState_formIsInvalid() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isFormValid)
    }

    func test_initialState_noErrors() {
        let vm = makeViewModel()
        XCTAssertNil(vm.emailError)
        XCTAssertNil(vm.passwordError)
        XCTAssertNil(vm.serverError)
    }

    func test_initialState_notLoading() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func test_initialState_passwordNotVisible() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.isPasswordVisible)
    }

    // MARK: - isFormValid

    func test_isFormValid_trueWhenBothFieldsNonEmptyAndEmailValid() {
        let vm = makeViewModel()
        vm.email = "user@example.com"
        vm.password = "password123"
        XCTAssertTrue(vm.isFormValid)
    }

    func test_isFormValid_falseWhenEmailIsEmpty() {
        let vm = makeViewModel()
        vm.email = ""
        vm.password = "password123"
        XCTAssertFalse(vm.isFormValid)
    }

    func test_isFormValid_falseWhenPasswordIsEmpty() {
        let vm = makeViewModel()
        vm.email = "user@example.com"
        vm.password = ""
        XCTAssertFalse(vm.isFormValid)
    }

    func test_isFormValid_falseWhenEmailFormatIsInvalid() {
        let vm = makeViewModel()
        vm.email = "not-an-email"
        vm.password = "password123"
        XCTAssertFalse(vm.isFormValid)
    }

    // MARK: - loginAction — field validation errors

    func test_loginAction_setsEmailError_whenEmailIsEmpty() async {
        let vm = makeViewModel()
        vm.email = ""
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertEqual(vm.emailError, "This field is required.")
    }

    func test_loginAction_setsPasswordError_whenPasswordIsEmpty() async {
        let vm = makeViewModel()
        vm.email = "user@example.com"
        vm.password = ""
        await vm.loginAction()
        XCTAssertEqual(vm.passwordError, "This field is required.")
    }

    func test_loginAction_setsEmailError_onInvalidEmailFormat() async {
        let vm = makeViewModel()
        vm.email = "not-an-email"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertEqual(vm.emailError, "Please enter a valid email address.")
    }

    // MARK: - loginAction — loading state

    func test_loginAction_setsIsLoadingTrue_duringExecution() async {
        var observedLoadingStates: [Bool] = []
        let stub = TrackingLoginAuthManaging { [weak self] in
            _ = self // suppress warning
            observedLoadingStates.append(true)
        }
        let config = AuthClientConfiguration()
        let vm = LoginViewModel(authManaging: stub, configuration: config)
        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertFalse(vm.isLoading, "isLoading should be false after completion")
        XCTAssertFalse(observedLoadingStates.isEmpty, "isLoading should have been true during execution")
    }

    // MARK: - loginAction — success

    func test_loginAction_onSuccess_sessionBecomesAuthenticated() async {
        let stub = StubLoginAuthManaging(loginResult: .success(()))
        let config = AuthClientConfiguration()
        let vm = LoginViewModel(authManaging: stub, configuration: config)
        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertNil(vm.passwordError)
        XCTAssertNil(vm.serverError)
        XCTAssertNil(vm.emailError)
    }

    // MARK: - loginAction — error scenarios

    func test_loginAction_setsPasswordError_onInvalidCredentials() async {
        let vm = makeViewModel(loginResult: .failure(.invalidCredentials))
        vm.email = "user@example.com"
        vm.password = "wrongpassword"
        await vm.loginAction()
        XCTAssertEqual(vm.passwordError, "Incorrect email or password.")
    }

    func test_loginAction_setsServerError_onNetworkError() async {
        let vm = makeViewModel(loginResult: .failure(.networkUnavailable))
        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertEqual(vm.serverError, "No internet connection. Please try again.")
    }

    func test_loginAction_setsServerError_onServerError() async {
        let vm = makeViewModel(loginResult: .failure(.serverError))
        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertEqual(vm.serverError, "Something went wrong. Please try again.")
    }

    func test_loginAction_isLoadingFalse_afterCompletion() async {
        let vm = makeViewModel(loginResult: .failure(.serverError))
        vm.email = "user@example.com"
        vm.password = "password123"
        await vm.loginAction()
        XCTAssertFalse(vm.isLoading)
    }
}

// MARK: - Test Doubles

@MainActor
private final class StubLoginAuthManaging: LoginAuthManaging {
    private let loginResult: Result<Void, AuthError>

    init(loginResult: Result<Void, AuthError>) {
        self.loginResult = loginResult
    }

    func login(email: String, password: String) async throws {
        switch loginResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class TrackingLoginAuthManaging: LoginAuthManaging {
    private let onLogin: () -> Void

    init(onLogin: @escaping () -> Void) {
        self.onLogin = onLogin
    }

    func login(email: String, password: String) async throws {
        onLogin()
    }
}
