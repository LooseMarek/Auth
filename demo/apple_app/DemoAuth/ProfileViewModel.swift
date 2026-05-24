import Foundation
import Observation
import AuthClient

/// View model for the profile page.
///
/// Fetches `GET /me` using the stored access token from `AuthManager`, exposes the
/// user's profile fields, and handles logout and account deletion.
///
/// Inject a custom `URLSession` (e.g. one backed by `MockURLProtocol`) for unit tests.
@Observable
@MainActor
final class ProfileViewModel {

    // MARK: - Dependencies

    private let authManager: AuthManager
    private let apiBaseURL: String
    private let urlSession: URLSession

    // MARK: - User fields

    /// The authenticated user's unique identifier.
    var userID: UUID?

    /// The user's email address.
    var email: String = ""

    /// The authentication provider (e.g. "email", "apple", "google", "guest").
    var authProvider: String = ""

    /// The date the user account was created.
    var createdAt: Date?

    /// Whether this is a guest (anonymous) account.
    var isGuest: Bool = false

    // MARK: - Token debug fields

    /// The expiry date of the current access token.
    var accessTokenExpiry: Date?

    /// The unique identifier of the active refresh token.
    var refreshTokenID: UUID?

    // MARK: - UI state

    /// True while the `GET /me` network call is in flight.
    var isLoading: Bool = false

    /// Set to a human-readable description when the `GET /me` call fails.
    var errorMessage: String?

    /// Controls the delete-account confirmation alert.
    var showDeleteConfirmation: Bool = false

    // MARK: - Init

    /// Creates a `ProfileViewModel` with the given dependencies.
    ///
    /// - Parameters:
    ///   - authManager: The shared `AuthManager` instance.
    ///   - apiBaseURL: Base URL for the demo Auth API (e.g. `"http://localhost:8080"`).
    ///   - urlSession: The URL session to use for network calls. Defaults to `.shared`.
    init(
        authManager: AuthManager,
        apiBaseURL: String,
        urlSession: URLSession = .shared
    ) {
        self.authManager = authManager
        self.apiBaseURL = apiBaseURL
        self.urlSession = urlSession
    }

    // MARK: - Network

    /// Fetches the user profile from `GET /me` using a fresh access token.
    ///
    /// On success, populates all user and token debug fields.
    /// On failure, sets `errorMessage` with a human-readable description.
    func fetchMe() async {
        isLoading = true
        errorMessage = nil

        do {
            try await authManager.withFreshToken { [weak self] token in
                guard let self else { return }
                let response = try await self.performMeRequest(accessToken: token)
                await MainActor.run {
                    self.populate(from: response)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Actions

    /// Logs the user out by delegating to `AuthManager.logout()`.
    ///
    /// Clears local session state and causes `AppRootView` to present the auth sheet.
    func logout() async {
        await authManager.logout()
    }

    /// Presents the delete-account confirmation alert.
    ///
    /// Call `deleteAccount()` after the user confirms.
    func confirmDeleteAccount() {
        showDeleteConfirmation = true
    }

    /// Permanently deletes the account by delegating to `AuthManager.deleteAccount()`.
    ///
    /// On success, the session resets to `.unauthenticated`.
    /// On failure, `errorMessage` is set.
    func deleteAccount() async {
        do {
            try await authManager.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
        showDeleteConfirmation = false
    }

    /// Triggers the guest-upgrade flow by presenting the auth sheet.
    func upgradeAccount() {
        authManager.presentAuthFlow()
    }

    // MARK: - Private helpers

    private func performMeRequest(accessToken: String) async throws -> MeResponse {
        guard let url = URL(string: "\(apiBaseURL)/me") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let (data, httpResponse) = try await urlSession.data(for: request)

        guard let http = httpResponse as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode(MeResponse.self, from: data)
    }

    private func populate(from response: MeResponse) {
        userID = response.id
        email = response.email
        authProvider = response.authProvider
        createdAt = response.createdAt
        isGuest = response.isGuest
        accessTokenExpiry = response.accessTokenExpiry
        refreshTokenID = response.refreshTokenId
    }
}
