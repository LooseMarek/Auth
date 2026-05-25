import Foundation
import Observation

/// View model for the delete-account confirmation and execution flow.
///
/// Call ``deleteAccount(authManager:)`` after the user confirms the deletion dialog.
/// On failure, call ``retry(authManager:)`` to re-issue `DELETE /account` — not any
/// other endpoint.
///
/// Exposes ``errorMessage`` for inline error display, and ``isLoading`` for a
/// progress indicator.
@Observable
@MainActor
public final class DeleteAccountViewModel {

    // MARK: - Public state

    /// Set to a human-readable description when the delete request fails.
    public private(set) var errorMessage: String?

    /// `true` while the delete request is in flight.
    public private(set) var isLoading: Bool = false

    // MARK: - Private

    private let localizationBundle: Bundle?

    // MARK: - Init

    /// Creates a `DeleteAccountViewModel`.
    ///
    /// - Parameter localizationBundle: Override the bundle used for localised strings.
    ///   Defaults to `nil`, which resolves to `Bundle.module` (the AuthClient module bundle).
    ///   Pass a custom bundle in unit tests to assert on specific string values.
    public init(localizationBundle: Bundle? = nil) {
        self.localizationBundle = localizationBundle
    }

    // MARK: - Actions

    /// Permanently deletes the account by calling ``AuthManager/deleteAccount()``.
    ///
    /// On success, `AuthManager.session` transitions to `.unauthenticated` and
    /// `errorMessage` is `nil`.
    /// On failure, `errorMessage` is set to a human-readable localised string.
    public func deleteAccount(authManager: AuthManager) async {
        await performDelete(authManager: authManager)
    }

    /// Re-issues `DELETE /account` — the same operation that was attempted before.
    ///
    /// Must be called when the user taps "Retry" after a failed deletion.
    /// Always retries the delete, never GET /me or any other endpoint.
    public func retry(authManager: AuthManager) async {
        await performDelete(authManager: authManager)
    }

    // MARK: - Private helpers

    private func localizedString(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: localizationBundle ?? .module)
    }

    private func performDelete(authManager: AuthManager) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await authManager.deleteAccount()
        } catch AuthNetworkError.networkUnavailable {
            errorMessage = localizedString("auth.error.network")
        } catch {
            errorMessage = localizedString("auth.error.server")
        }
    }
}
