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
    private(set) var errorMessage: String? = nil
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
        initialIsLoading: Bool = false
    ) {
        self.networkService = networkService
        self.localizationBundle = localizationBundle
        self.onNavigateToLogin = onNavigateToLogin
        self.email = initialEmail
        self.password = initialPassword
        self.confirmPassword = initialConfirmPassword
        self.confirmPasswordError = initialConfirmPasswordError
        self.isLoading = initialIsLoading
    }

    /// Navigates back to the Login view by invoking the `onNavigateToLogin` callback.
    ///
    /// The callback is provided by the hosting `RegisterView` and calls
    /// `@Environment(\.dismiss)` to pop the view off the navigation stack.
    func navigateToLogin() {
        onNavigateToLogin?()
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
            emailError = localizedString("auth.register.error.email_taken")
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = localizedString("auth.error.network")
        } catch {
            errorMessage = localizedString("auth.error.server")
        }
    }
}
