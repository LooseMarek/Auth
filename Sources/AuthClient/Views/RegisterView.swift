import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The registration screen of the Auth flow.
///
/// `RegisterView` is pushed onto the `AuthSheetContainer` navigation stack from `LoginView`.
/// It collects an email address, a password, and a confirm-password field, performs
/// client-side mismatch validation, and registers a new account via the injected
/// `AuthNetworkService`.
///
/// On successful registration, `AuthManager.session` transitions to `.authenticated`.
public struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    private let authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.authTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private var bundle: Bundle { authManager.configuration.localizationBundle ?? .module }

    /// Creates a `RegisterView`.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager.
    ///   - networkService: The network layer used for the registration request.
    ///   - prefilledEmail: Optional email to pre-populate the email field (e.g. for Xcode Previews).
    ///   - prefilledPassword: Optional password to pre-populate the password field.
    ///   - prefilledConfirmPassword: Optional value to pre-populate the confirm-password field.
    ///   - initialConfirmPasswordError: Optional mismatch error to display immediately on appear.
    ///   - initialIsLoading: When `true`, the register button shows a loading indicator on appear.
    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        prefilledEmail: String = "",
        prefilledPassword: String = "",
        prefilledConfirmPassword: String = "",
        initialConfirmPasswordError: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.authManager = authManager
        self._viewModel = State(wrappedValue: RegisterViewModel(
            networkService: networkService,
            localizationBundle: authManager.configuration.localizationBundle,
            initialEmail: prefilledEmail,
            initialPassword: prefilledPassword,
            initialConfirmPassword: prefilledConfirmPassword,
            initialConfirmPasswordError: initialConfirmPasswordError,
            initialIsLoading: initialIsLoading
        ))
    }

    public var body: some View {
        content
            .environment(
                \.authTheme,
                AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
            )
            .onAppear {
                // Wire the dismiss action into the ViewModel so navigateToLogin() pops
                // this view off the NavigationStack and returns the user to LoginView.
                viewModel.onNavigateToLogin = { dismiss() }
            }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                Spacer().frame(height: 24)
                emailFieldSection
                Spacer().frame(height: 14)
                passwordFieldSection
                Spacer().frame(height: 14)
                confirmPasswordFieldSection
                Spacer().frame(height: 24)
                registerButton
                if let message = viewModel.errorMessage {
                    serverErrorRow(message: message)
                }
                Spacer().frame(height: 32)
                loginLink
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
            // Apply custom base font when configured; child modifiers override as needed.
            .font(theme.font)
            .allowsHitTesting(!viewModel.isLoading)
        }
        .background(theme.backgroundColor)
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "auth.register.title", bundle: bundle))
                .font(.title.bold())
                .foregroundStyle(theme.primaryTextColor)
            Text(String(localized: "auth.register.subtitle", bundle: bundle))
                .font(.callout)
                .foregroundStyle(theme.secondaryTextColor)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(String(localized: "auth.register.field.email.placeholder", bundle: bundle), text: $viewModel.email)
#if canImport(UIKit)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
#endif
                .textContentType(.emailAddress)
                .submitLabel(.next)
                .foregroundStyle(theme.primaryTextColor)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(theme.surfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if let error = viewModel.emailError {
                inlineErrorRow(message: error)
            }
        }
    }

    private var passwordFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RegisterPasswordFieldView(
                text: $viewModel.password,
                placeholder: String(localized: "auth.register.field.password.placeholder", bundle: bundle),
                isConfirmField: false,
                bundle: bundle
            )
            if let error = viewModel.passwordError {
                inlineErrorRow(message: error)
            }
        }
    }

    private var confirmPasswordFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            RegisterPasswordFieldView(
                text: $viewModel.confirmPassword,
                placeholder: String(localized: "auth.register.field.confirm_password.placeholder", bundle: bundle),
                isConfirmField: true,
                bundle: bundle
            )
            if let error = viewModel.confirmPasswordError {
                inlineErrorRow(message: error)
            }
        }
    }

    @ViewBuilder
    private func inlineErrorRow(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(theme.errorColor)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(theme.errorColor)
        }
        .padding(.top, 4)
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private func serverErrorRow(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(theme.errorColor)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(theme.errorColor)
        }
        .padding(.top, 8)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var registerButton: some View {
        Button {
            Task { await viewModel.register(authManager: authManager) }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .colorScheme(.dark)
                } else {
                    Text(String(localized: "auth.register.button.submit", bundle: bundle))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.buttonTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                viewModel.canSubmit
                    ? theme.primaryColor
                    : theme.primaryDisabled
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }

    private var loginLink: some View {
        HStack {
            Spacer()
            Button {
                viewModel.navigateToLogin()
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "auth.register.login_prompt", bundle: bundle))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryTextColor)
                    Text(String(localized: "auth.register.login_link", bundle: bundle))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryColor)
                }
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}

// MARK: - Supporting views

/// A password field with a show/hide toggle. Used for both the password and confirm-password fields.
/// `isConfirmField`: when true, uses `.go` submit label; when false, uses `.next`.
private struct RegisterPasswordFieldView: View {
    @Binding var text: String
    let placeholder: String
    let isConfirmField: Bool
    var bundle: Bundle = .module

    @State private var isVisible: Bool = false
    @Environment(\.authTheme) private var theme

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.newPassword)
                        .submitLabel(isConfirmField ? .go : .next)
                        .foregroundStyle(theme.primaryTextColor)
                        .textFieldStyle(.plain)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.newPassword)
                        .submitLabel(isConfirmField ? .go : .next)
                        .foregroundStyle(theme.primaryTextColor)
                        .textFieldStyle(.plain)
                }
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.secondaryTextColor)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isVisible
                    ? String(localized: "auth.field.password.hide", bundle: bundle)
                    : String(localized: "auth.field.password.show", bundle: bundle)
            )
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(theme.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Previews

#if DEBUG

private struct PreviewRegisterNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func logout(refreshToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func deleteAccount(accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }

    func signInWithApple(identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithApple(guestUUID: UUID, accessToken: String, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, accessToken: String, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, accessToken: String, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static var previewRegister: AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}

#Preview("Default — empty") {
    RegisterView(authManager: .previewRegister, networkService: PreviewRegisterNetworkService())
}

#Preview("With inputs") {
    RegisterView(
        authManager: .previewRegister,
        networkService: PreviewRegisterNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "password1",
        prefilledConfirmPassword: "password1"
    )
}

#Preview("Loading") {
    RegisterView(
        authManager: .previewRegister,
        networkService: PreviewRegisterNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "secret123",
        prefilledConfirmPassword: "secret123",
        initialIsLoading: true
    )
}

#Preview("Password mismatch error") {
    RegisterView(
        authManager: .previewRegister,
        networkService: PreviewRegisterNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "password1",
        prefilledConfirmPassword: "password2",
        initialConfirmPasswordError: "Passwords do not match."
    )
}

#endif
