import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    var email: String = ""
    var password: String = ""

    /// Inline error shown directly below the password field.
    ///
    /// Only field-level validation errors (e.g. wrong email/password) use this slot.
    /// All other errors (network, server, provider) appear via ``toastErrorMessage``.
    private(set) var inlineErrorMessage: String? = nil

    /// Toast error shown at the bottom of the screen.
    ///
    /// Used for all non-validation errors: network unavailability, server errors,
    /// and errors from guest, Google, and Apple sign-in flows.
    private(set) var toastErrorMessage: String? = nil

    private(set) var isLoading: Bool = false
    private(set) var isGuestLoading: Bool = false

    var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        initialEmail: String = "",
        initialPassword: String = "",
        initialErrorMessage: String? = nil,
        initialToastErrorMessage: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.email = initialEmail
        self.password = initialPassword
        // Legacy init parameter: initial error messages go to the inline slot so
        // existing snapshot tests (e.g. "Invalid credentials" preview) still work.
        self.inlineErrorMessage = initialErrorMessage
        self.toastErrorMessage = initialToastErrorMessage
        self.isLoading = initialIsLoading
    }

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
    }

    // MARK: - Computed backward-compatibility accessor

    /// Returns the currently active inline error message.
    ///
    /// This exists for backward-compatibility with code that reads `errorMessage`
    /// (e.g. existing snapshot previews). New code should read ``inlineErrorMessage``
    /// or ``toastErrorMessage`` directly.
    var errorMessage: String? { inlineErrorMessage }

    // MARK: - Actions

    func login(authManager: AuthManager) async {
        inlineErrorMessage = nil
        toastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            // If the current session is a guest, upgrade rather than performing a fresh login.
            if case .guest(let guestUUID) = authManager.session {
                let response = try await authManager.withFreshToken { accessToken in
                    try await networkService.upgradeGuestWithEmail(
                        guestUUID: guestUUID,
                        accessToken: accessToken,
                        email: email,
                        password: password
                    )
                }
                authManager.signIn(response: response)
            } else {
                let response = try await networkService.login(email: email, password: password)
                authManager.signIn(response: response)
            }
        } catch AuthNetworkError.invalidCredentials {
            // Validation error — shown inline below the password field.
            inlineErrorMessage = localizedString("auth.login.error.invalid_credentials")
        } catch AuthNetworkError.networkUnavailable {
            // Non-validation error — shown as a toast.
            toastErrorMessage = localizedString("auth.error.network")
        } catch {
            // Non-validation error — shown as a toast.
            toastErrorMessage = localizedString("auth.error.server")
        }
    }

    /// Starts an anonymous guest session via POST /auth/guest.
    ///
    /// Shows a loading indicator on the guest button, calls `authManager.loginAsGuest()`,
    /// and surfaces any error as a toast message at the bottom of the screen.
    func loginAsGuest(authManager: AuthManager) async {
        inlineErrorMessage = nil
        toastErrorMessage = nil
        isGuestLoading = true
        defer { isGuestLoading = false }
        do {
            try await authManager.loginAsGuest()
        } catch AuthNetworkError.networkUnavailable {
            toastErrorMessage = localizedString("auth.error.network")
        } catch {
            toastErrorMessage = localizedString("auth.error.server")
        }
    }

    /// Dismisses the current toast error, leaving the Login view ready for retry.
    func dismissToast() {
        toastErrorMessage = nil
    }

    /// Sets a toast error message for a failed Apple sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setAppleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            toastErrorMessage = localizedString("auth.error.network")
        default:
            toastErrorMessage = localizedString("auth.error.server")
        }
    }

    /// Sets a toast error message for a failed Google sign-in attempt.
    ///
    /// Cancellations must not call this method — pass the error only for network or server failures.
    func setGoogleSignInError(_ error: AuthNetworkError) {
        switch error {
        case .networkUnavailable:
            toastErrorMessage = localizedString("auth.error.network")
        default:
            toastErrorMessage = localizedString("auth.error.server")
        }
    }
}
