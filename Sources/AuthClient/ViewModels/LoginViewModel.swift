import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false

    var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    let networkService: any AuthNetworkService

    init(
        networkService: any AuthNetworkService,
        initialEmail: String = "",
        initialPassword: String = "",
        initialErrorMessage: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.email = initialEmail
        self.password = initialPassword
        self.errorMessage = initialErrorMessage
        self.isLoading = initialIsLoading
    }

    func login(authManager: AuthManager) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await networkService.login(email: email, password: password)
            authManager.signIn(response: response)
        } catch AuthNetworkError.invalidCredentials {
            errorMessage = "Incorrect email or password."
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = "No internet connection. Please try again."
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    /// Sets an inline error message for a failed Apple sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setAppleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            errorMessage = "No internet connection. Please try again."
        default:
            errorMessage = "Something went wrong. Please try again."
        }
    }

    /// Sets an inline error message for a failed Google sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setGoogleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            errorMessage = "No internet connection. Please try again."
        default:
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
