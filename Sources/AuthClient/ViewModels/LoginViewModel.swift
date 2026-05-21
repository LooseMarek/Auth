import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    private(set) var errorMessage: String? = nil
    private(set) var isLoading: Bool = false
    private(set) var isGuestLoading: Bool = false

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
            // If the current session is a guest, upgrade rather than performing a fresh login.
            if case .guest(let guestUUID) = authManager.session {
                let response = try await networkService.upgradeGuestWithEmail(
                    guestUUID: guestUUID,
                    email: email,
                    password: password
                )
                authManager.signIn(response: response)
            } else {
                let response = try await networkService.login(email: email, password: password)
                authManager.signIn(response: response)
            }
        } catch AuthNetworkError.invalidCredentials {
            errorMessage = String(localized: "auth.login.error.invalid_credentials", bundle: .module)
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = String(localized: "auth.error.network", bundle: .module)
        } catch {
            errorMessage = String(localized: "auth.error.server", bundle: .module)
        }
    }

    /// Starts an anonymous guest session via POST /auth/guest.
    ///
    /// Shows a loading indicator on the guest button, calls `authManager.loginAsGuest()`,
    /// and surfaces any error as an inline message.
    func loginAsGuest(authManager: AuthManager) async {
        errorMessage = nil
        isGuestLoading = true
        defer { isGuestLoading = false }
        do {
            try await authManager.loginAsGuest()
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = String(localized: "auth.error.network", bundle: .module)
        } catch {
            errorMessage = String(localized: "auth.error.server", bundle: .module)
        }
    }

    /// Sets an inline error message for a failed Apple sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setAppleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            errorMessage = String(localized: "auth.error.network", bundle: .module)
        default:
            errorMessage = String(localized: "auth.error.server", bundle: .module)
        }
    }

    /// Sets an inline error message for a failed Google sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setGoogleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            errorMessage = String(localized: "auth.error.network", bundle: .module)
        default:
            errorMessage = String(localized: "auth.error.server", bundle: .module)
        }
    }
}
