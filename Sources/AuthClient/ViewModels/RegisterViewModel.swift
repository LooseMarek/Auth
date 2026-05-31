import Foundation
import Observation
import AuthShared

@Observable
@MainActor
final class RegisterViewModel {
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    private(set) var emailError: String? = nil
    private(set) var passwordError: String? = nil
    private(set) var confirmPasswordError: String? = nil

    /// Toast error shown at the bottom of the screen.
    ///
    /// Used for all non-validation errors: network unavailability and server errors.
    /// Field-level validation errors (email taken, password mismatch, etc.) use the
    /// inline ``emailError``, ``passwordError``, and ``confirmPasswordError`` slots.
    private(set) var toastErrorMessage: String? = nil

    private(set) var isLoading: Bool = false

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }

    private let networkService: any AuthNetworkService
    private let localizationBundle: Bundle?
    /// Navigation callback injected by the hosting view.
    ///
    /// In production, `RegisterView` sets this to a closure that calls
    /// `@Environment(\.dismiss)` so the view pops off the navigation stack.
    /// In tests, a spy closure is injected directly to verify the callback fires.
    var onNavigateToLogin: (() -> Void)?

    init(
        networkService: any AuthNetworkService,
        localizationBundle: Bundle? = nil,
        onNavigateToLogin: (() -> Void)? = nil,
        initialEmail: String = "",
        initialPassword: String = "",
        initialConfirmPassword: String = "",
        initialConfirmPasswordError: String? = nil,
        initialToastErrorMessage: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.onNavigateToLogin = onNavigateToLogin
        self.email = initialEmail
        self.password = initialPassword
        self.confirmPassword = initialConfirmPassword
        self.confirmPasswordError = initialConfirmPasswordError
        self.toastErrorMessage = initialToastErrorMessage
        self.isLoading = initialIsLoading
    }

    /// Navigates back to the Login view by invoking the `onNavigateToLogin` callback.
    ///
    /// The callback is provided by the hosting `RegisterView` and calls
    /// `@Environment(\.dismiss)` to pop the view off the navigation stack.
    func navigateToLogin() {
        onNavigateToLogin?()
    }

    /// Dismisses the current toast error, leaving the Register view ready for retry.
    func dismissToast() {
        toastErrorMessage = nil
    }

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
    }

    func register(authManager: AuthManager) async {
        // Clear previous errors.
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        toastErrorMessage = nil

        // Client-side validation: password must meet the minimum length.
        guard PasswordValidator.isValidLength(password) else {
            passwordError = localizedString("auth.register.error.password_too_short")
            return
        }

        // Client-side validation: passwords must match.
        guard password == confirmPassword else {
            confirmPasswordError = localizedString("auth.register.error.password_mismatch")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: AuthResponse
            if case .guest(let guestUUID) = authManager.session {
                // Guest upgrading via the register form — preserve the existing UUID
                // by calling the upgrade endpoint instead of creating a new account.
                response = try await authManager.withFreshToken { accessToken in
                    try await networkService.upgradeGuestWithEmail(
                        guestUUID: guestUUID,
                        accessToken: accessToken,
                        email: email,
                        password: password
                    )
                }
            } else {
                response = try await networkService.register(email: email, password: password)
            }
            authManager.signIn(response: response)
        } catch AuthNetworkError.emailTaken {
            // Field-level validation error — shown inline below the email field.
            emailError = localizedString("auth.register.error.email_taken")
        } catch AuthNetworkError.accountAlreadyExists {
            // Guest upgrade: the email is already tied to a full account.
            emailError = localizedString("auth.upgrade.error.account_already_exists")
        } catch AuthNetworkError.networkUnavailable {
            // Non-validation error — shown as a toast.
            toastErrorMessage = localizedString("auth.error.network")
        } catch {
            // Non-validation error — shown as a toast.
            toastErrorMessage = localizedString("auth.error.server")
        }
    }
}
