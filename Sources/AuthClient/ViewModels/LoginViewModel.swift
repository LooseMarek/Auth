import Observation
import Foundation

private enum Strings {
    static let required = "This field is required."
    static let emailFormat = "Please enter a valid email address."
    static let invalidCredentials = "Incorrect email or password."
    static let network = "No internet connection. Please try again."
    static let server = "Something went wrong. Please try again."
    static let socialTokenInvalid = "Sign-in failed. Please try again."
}

@Observable
@MainActor
public final class LoginViewModel: LoginViewModelProtocol {

    // MARK: - Bindable fields

    public var email: String = ""
    public var password: String = ""
    public var isPasswordVisible: Bool = false

    // MARK: - State

    public private(set) var isLoading: Bool = false
    public private(set) var emailError: String? = nil
    public private(set) var passwordError: String? = nil
    public private(set) var serverError: String? = nil

    // MARK: - Navigation callbacks

    public var onForgotPassword: (() -> Void)?
    public var onRegister: (() -> Void)?
    public var onGuestAccess: (() -> Void)?

    // MARK: - Computed

    public var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail(email)
    }

    // MARK: - Dependencies

    private let authManaging: any LoginAuthManaging
    public let configuration: AuthClientConfiguration

    // MARK: - Init

    public init(authManaging: any LoginAuthManaging, configuration: AuthClientConfiguration) {
        self.authManaging = authManaging
        self.configuration = configuration
    }

    // MARK: - Actions

    public func loginAction() async {
        clearErrors()

        guard validateFields() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await authManaging.login(email: email, password: password)
        } catch AuthError.invalidCredentials {
            passwordError = Strings.invalidCredentials
        } catch AuthError.networkUnavailable {
            serverError = Strings.network
        } catch AuthError.serverError {
            serverError = Strings.server
        } catch AuthError.socialTokenInvalid {
            serverError = Strings.socialTokenInvalid
        } catch {
            serverError = Strings.server
        }
    }

    // MARK: - Private helpers

    private func clearErrors() {
        emailError = nil
        passwordError = nil
        serverError = nil
    }

    /// Returns `true` if all fields are valid; sets field errors and returns `false` otherwise.
    private func validateFields() -> Bool {
        var valid = true
        if email.isEmpty {
            emailError = Strings.required
            valid = false
        } else if !isValidEmail(email) {
            emailError = Strings.emailFormat
            valid = false
        }
        if password.isEmpty {
            passwordError = Strings.required
            valid = false
        }
        return valid
    }

    private func isValidEmail(_ value: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: value)
    }
}
