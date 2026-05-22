import Foundation
import Observation

@Observable
@MainActor
final class RegisterViewModel {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    private(set) var emailError: String? = nil
    private(set) var passwordError: String? = nil
    private(set) var confirmPasswordError: String? = nil
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    private let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        initialEmail: String = "",
        initialPassword: String = "",
        initialConfirmPassword: String = "",
        initialConfirmPasswordError: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.email = initialEmail
        self.password = initialPassword
        self.confirmPassword = initialConfirmPassword
        self.confirmPasswordError = initialConfirmPasswordError
        self.isLoading = initialIsLoading
    }

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
    }

    func register(authManager: AuthManager) async {
        // Clear previous errors.
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil

        // Client-side validation: passwords must match.
        guard password == confirmPassword else {
            confirmPasswordError = localizedString("auth.register.error.password_mismatch")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await networkService.register(email: email, password: password)
            authManager.signIn(response: response)
        } catch AuthNetworkError.emailTaken {
            emailError = localizedString("auth.register.error.email_taken")
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = localizedString("auth.error.network")
        } catch {
            errorMessage = localizedString("auth.error.server")
        }
    }
}
