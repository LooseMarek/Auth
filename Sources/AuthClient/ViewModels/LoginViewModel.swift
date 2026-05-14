import Foundation
import Observation
import AuthShared

/// The ViewModel backing `LoginView`.
///
/// Uses the `@Observable` macro (iOS 17.0+ / macOS 14.0+) as per ADR-002.
/// Must be created and used on the `@MainActor`.
@Observable
@MainActor
public final class LoginViewModel {

    // MARK: - Observed Properties

    /// The email address entered by the user.
    public var email: String = ""

    /// The password entered by the user.
    public var password: String = ""

    /// Whether the password field is currently shown in plain text.
    public var isPasswordVisible: Bool = false

    /// Whether a login request is currently in flight.
    public var isLoading: Bool = false

    /// The inline error message to display, or `nil` when there is no error.
    public var errorMessage: String? = nil

    // MARK: - Dependencies

    private let authManager: AuthManager
    private let networkClient: any AuthNetworkClient

    // MARK: - Init

    public init(authManager: AuthManager, networkClient: any AuthNetworkClient) {
        self.authManager = authManager
        self.networkClient = networkClient
    }

    // MARK: - Derived State

    /// `true` when both email and password are non-empty and a request is not in flight.
    public var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !isLoading
    }

    // MARK: - Actions

    /// Validates inputs and, if valid, sends a login request.
    public func login() async {
        guard validateInputs() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let request = LoginRequest(email: email.trimmingCharacters(in: .whitespaces), password: password)
            let response = try await networkClient.login(request: request)
            authManager.updateSession(to: .authenticated(response.user))
        } catch let networkError as AuthNetworkError {
            errorMessage = localizedMessage(for: networkError)
        } catch {
            errorMessage = String(localized: "auth.error.server", bundle: .module)
        }

        isLoading = false
    }

    // MARK: - Private

    /// Runs client-side validation and sets `errorMessage` if any field is invalid.
    /// - Returns: `true` when all inputs are valid.
    private func validateInputs() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty {
            errorMessage = String(localized: "auth.error.required", bundle: .module)
            return false
        }

        if !isValidEmailFormat(trimmedEmail) {
            errorMessage = String(localized: "auth.error.email_format", bundle: .module)
            return false
        }

        if password.isEmpty {
            errorMessage = String(localized: "auth.error.required", bundle: .module)
            return false
        }

        return true
    }

    private func isValidEmailFormat(_ email: String) -> Bool {
        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )
        let range = NSRange(email.startIndex..., in: email)
        let matches = detector?.matches(in: email, options: [], range: range) ?? []
        return matches.first?.url?.scheme == "mailto"
    }

    private func localizedMessage(for error: AuthNetworkError) -> String {
        switch error {
        case .invalidCredentials:
            return String(localized: "auth.login.error.invalid_credentials", bundle: .module)
        case .networkUnavailable:
            return String(localized: "auth.error.network", bundle: .module)
        case .serverError:
            return String(localized: "auth.error.server", bundle: .module)
        case .socialTokenInvalid:
            return String(localized: "auth.social.error.token_invalid", bundle: .module)
        case .unknown:
            return String(localized: "auth.error.server", bundle: .module)
        }
    }
}
