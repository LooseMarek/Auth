import SwiftUI
import AuthClient

/// The shared profile page view displayed after successful authentication.
///
/// Used by both `DemoAuthDefault` and `DemoAuthCustom` targets via the shared
/// `DemoAuth/` source folder. Displays user profile data fetched from `GET /me`,
/// an expandable token debug panel, and action buttons.
struct ProfileView: View {

    // MARK: - State

    private let authManager: AuthManager
    private let apiBaseURL: String
    @State private var viewModel: ProfileViewModel

    // MARK: - Init

    init(authManager: AuthManager, apiBaseURL: String) {
        self.authManager = authManager
        self.apiBaseURL = apiBaseURL
        _viewModel = State(
            initialValue: ProfileViewModel(
                authManager: authManager,
                apiBaseURL: apiBaseURL
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading profile…")
                } else {
                    profileContent
                }
            }
            .navigationTitle("Profile")
            .task(id: authManager.session.isGuest) {
                await viewModel.fetchMe()
            }
            .alert("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete your account? This cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showChangePassword) {
                ChangePasswordView(
                    authManager: authManager,
                    networkService: URLSessionAuthNetworkService(baseURL: apiBaseURL),
                    popToRoot: { viewModel.showChangePassword = false }
                )
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var profileContent: some View {
        List {
            // MARK: Fetch-me error banner
            if let errorMessage = viewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await viewModel.fetchMe() }
                        }
                    }
                }
            }

            // MARK: Delete-account error banner
            // Shown separately so "Retry" re-issues DELETE /account, not GET /me.
            if let deleteErrorMessage = viewModel.deleteAccountViewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(deleteErrorMessage)
                            .foregroundStyle(.red)
                        Button("Retry") {
                            Task { await viewModel.retryDeleteAccount() }
                        }
                    }
                }
            }

            // MARK: User fields
            Section("User Info") {
                if let userID = viewModel.userID {
                    ProfileRow(label: "User ID", value: userID.uuidString)
                }
                ProfileRow(label: "Email", value: viewModel.email.isEmpty ? "—" : viewModel.email)
                ProfileRow(label: "Auth Provider", value: viewModel.authProvider.isEmpty ? "—" : viewModel.authProvider)
                if let createdAt = viewModel.createdAt {
                    ProfileRow(label: "Member Since", value: createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                ProfileRow(label: "Guest Account", value: viewModel.isGuest ? "Yes" : "No")
            }

            // MARK: Token debug
            Section {
                DisclosureGroup("Token Debug") {
                    if let expiry = viewModel.accessTokenExpiry {
                        ProfileRow(label: "Access Token Expires", value: expiry.formatted())
                    }
                    if let refreshID = viewModel.refreshTokenID {
                        ProfileRow(label: "Refresh Token ID", value: refreshID.uuidString)
                    }
                }
            }

            // MARK: Actions
            Section {
                if viewModel.isGuest {
                    Button("Upgrade Account") {
                        viewModel.upgradeAccount()
                    }
                }

                if viewModel.authProvider == "email" {
                    Button("Change Password") {
                        viewModel.changePassword()
                    }
                }

                Button("Logout") {
                    Task { await viewModel.logout() }
                }

                Button("Delete Account", role: .destructive) {
                    viewModel.confirmDeleteAccount()
                }
            }
        }
    }
}

// MARK: - ProfileRow

/// A simple label/value row for the profile list.
private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
