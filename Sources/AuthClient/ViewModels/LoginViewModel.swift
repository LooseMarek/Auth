import Observation
import Foundation
import AuthShared

// MARK: - LoginViewModel

/// ViewModel backing `LoginView`.
///
/// Handles field state, validation, network calls, and updates `AuthManager` on success.
/// Uses the `@Observable` macro per ADR-002.
@Observable
@MainActor
public final class LoginViewModel {

    // MARK: - Observable state

    /// The email address entered by the user.
    public var email: String = ""

    /// The password entered by the user.
    public var password: String = ""

    /// `true` while a login network request is in flight.
    public var isLoading: Bool = false

    /// An inline error message to display when login fails. `nil` when no error is present.
    public var errorMessage: String? = nil

    // MARK: - Dependencies

    private let networkService: AuthNetworkService
    private let authManager: AuthManager

    // MARK: - Initialiser

    public init(networkService: AuthNetworkService, authManager: AuthManager) {
        self.networkService = networkService
        self.authManager = authManager
    }

    // MARK: - Actions

    /// Validates fields and, if valid, performs the login network request.
    ///
    /// Sets `isLoading` during the request and updates `authManager.session` on success.
    /// On failure, sets `errorMessage` with a user-facing string.
    public func login() async {
        errorMessage = nil

        guard validate() else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await networkService.login(email: email, password: password)
            authManager.updateSession(.authenticated(response.user))
        } catch AuthNetworkError.invalidCredentials {
            errorMessage = String(localized: "auth.login.error.invalid_credentials",
                                  defaultValue: "Incorrect email or password.")
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = String(localized: "auth.error.network",
                                  defaultValue: "No internet connection. Please try again.")
        } catch {
            errorMessage = String(localized: "auth.error.server",
                                  defaultValue: "Something went wrong. Please try again.")
        }
    }

    // MARK: - Private helpers

    /// Validates email and password fields. Sets `errorMessage` and returns `false` on failure.
    private func validate() -> Bool {
        if email.isEmpty {
            errorMessage = String(localized: "auth.error.required",
                                  defaultValue: "This field is required.")
            return false
        }
        if password.isEmpty {
            errorMessage = String(localized: "auth.error.required",
                                  defaultValue: "This field is required.")
            return false
        }
        return true
    }
}
