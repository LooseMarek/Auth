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

    init(
        networkService: any AuthNetworkService,
        initialEmail: String = "",
        initialPassword: String = "",
        initialConfirmPassword: String = "",
        initialConfirmPasswordError: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.email = initialEmail
        self.password = initialPassword
        self.confirmPassword = initialConfirmPassword
        self.confirmPasswordError = initialConfirmPasswordError
        self.isLoading = initialIsLoading
    }

    func register(authManager: AuthManager) async {
        // Clear previous errors.
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        errorMessage = nil

        // Client-side validation: passwords must match.
        guard password == confirmPassword else {
            confirmPasswordError = "Passwords do not match."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await networkService.register(email: email, password: password)
            authManager.signIn(response: response)
        } catch AuthNetworkError.emailTaken {
            emailError = "An account with this email already exists."
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = "No internet connection. Please try again."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
