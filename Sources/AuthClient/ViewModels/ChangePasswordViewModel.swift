import Foundation
import Observation

/// View model for the in-app change-password flow.
///
/// Only applicable to email-auth users. Call ``submit()`` after populating
/// ``currentPassword``, ``newPassword``, and ``confirmPassword``.
///
/// Use ``authManager`` when creating this in production — it provides
/// the access token automatically via ``AuthManager/withFreshToken(_:)``.
/// In unit tests you may pass `nil` for `authManager`; the mock network
/// service will ignore the access-token argument.
@Observable
@MainActor
final class ChangePasswordViewModel {

    // MARK: - Published state

    var currentPassword: String = ""
    var newPassword: String = ""
    var confirmPassword: String = ""
    private(set) var isLoading: Bool = false
    private(set) var isSuccess: Bool = false
    /// Inline field-level error message (reserved for future field validation errors).
    /// Not set by `submit()` — server/network errors are directed to `toastErrorMessage`.
    private(set) var errorMessage: String? = nil
    /// Toast error message shown as a dismissable banner at the bottom of the screen.
    /// Set by `submit()` for all server and network errors.
    private(set) var toastErrorMessage: String? = nil

    // MARK: - Derived state

    /// `true` when all three fields are non-empty and `newPassword == confirmPassword`.
    var canSubmit: Bool {
        !currentPassword.isEmpty
            && !newPassword.isEmpty
            && !confirmPassword.isEmpty
            && newPassword == confirmPassword
    }

    // MARK: - Navigation callback

    /// Called by ``backToSignIn()`` to pop back to the root screen.
    var onBackToSignIn: (() -> Void)?

    // MARK: - Dependencies

    private let networkService: any AuthNetworkService
    /// Optional `AuthManager` used to obtain a fresh access token before submitting.
    /// Pass `nil` only in unit tests where the mock service ignores the token.
    private weak var authManager: AuthManager?

    // MARK: - Init

    /// Creates a `ChangePasswordViewModel`.
    ///
    /// - Parameters:
    ///   - networkService: The network layer implementation.
    ///   - authManager: The shared `AuthManager` used to obtain a fresh access token.
    ///     Pass `nil` in unit tests (the mock service ignores the token parameter).
    ///   - initialIsSuccess: When `true`, pre-populates the success state (for previews).
    ///   - initialErrorMessage: Pre-populates the inline error message (for previews).
    ///   - initialToastErrorMessage: Pre-populates the toast error message (for snapshot test previews).
    init(
        networkService: any AuthNetworkService,
        authManager: AuthManager? = nil,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil,
        initialToastErrorMessage: String? = nil
    ) {
        self.networkService = networkService
        self.authManager = authManager
        self.isSuccess = initialIsSuccess
        self.errorMessage = initialErrorMessage
        self.toastErrorMessage = initialToastErrorMessage
    }

    // MARK: - Actions

    /// Submits the change-password request to the server.
    ///
    /// Sets ``isLoading`` to `true` during the request. On success, sets ``isSuccess``
    /// to `true`. On failure, sets ``toastErrorMessage`` to a human-readable description
    /// shown as a dismissable toast banner at the bottom of the screen.
    func submit() async {
        toastErrorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            // Obtain a fresh access token if an AuthManager is available (production path).
            // In unit tests authManager is nil and the mock ignores the token.
            let accessToken: String
            if let authManager {
                accessToken = try await authManager.withFreshToken { token in token }
            } else {
                accessToken = ""
            }
            try await networkService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                accessToken: accessToken
            )
            isSuccess = true
        } catch {
            toastErrorMessage = error.localizedDescription
        }
    }

    /// Dismisses the toast error banner by clearing ``toastErrorMessage``.
    func dismissToast() {
        toastErrorMessage = nil
    }

    /// Navigates back to the sign-in screen by invoking ``onBackToSignIn``.
    func backToSignIn() {
        onBackToSignIn?()
    }
}
