import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The login screen of the Auth flow.
///
/// `LoginView` is the root screen of the `AuthSheetContainer` navigation stack. It provides:
/// - Email/password login (or guest-to-email upgrade when a guest session is active)
/// - Sign in with Apple
/// - Sign in with Google
/// - Optional "Continue as Guest" button (shown when `AuthClientConfiguration.allowGuestAccess` is `true`)
/// - Navigation links to `RegisterView` and `ForgotPasswordView`
///
/// Host apps do not instantiate `LoginView` directly — it is presented automatically by
/// the `.authSheet(manager:)` modifier via `AuthSheetContainer`.
public struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @State private var appleSignInHandler: AppleSignInHandler
    @State private var googleSignInHandler: GoogleSignInHandler
    private let authManager: AuthManager
    /// Closure from `AuthSheetContainer` that appends a `LoginFlowDestination` to the
    /// `NavigationStack` path, pushing the corresponding screen. When `nil` (standalone
    /// preview), tapping navigation buttons is a no-op.
    private let navigateTo: ((LoginFlowDestination) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Resolved theme for the current colour scheme and configuration.
    ///
    /// Computed directly from `authManager.configuration` and `colorScheme` rather than read
    /// from the SwiftUI environment. This ensures that LoginView's own computed properties
    /// (emailField, titleSection, etc.) use the same resolved theme that is injected into child
    /// views — the `@Environment` value on `LoginView` itself would come from its parent, which
    /// has no injected `authTheme` and would return the default (unconfigured) theme.
    private var theme: AuthTheme {
        AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
    }

    private var bundle: Bundle { authManager.configuration.localizationBundle ?? .module }

    /// `true` when at least one of the social / guest buttons is visible.
    /// Used to hide the "OR" divider when none of them would render.
    private var hasAnySocialOrGuestButton: Bool {
        authManager.configuration.allowAppleSignIn
            || authManager.configuration.allowGoogleSignIn
            || (authManager.configuration.allowGuestAccess && !authManager.session.isGuest)
    }

    /// Creates a `LoginView`.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager.
    ///   - networkService: The network layer used for login and social auth requests.
    ///   - navigateTo: Optional closure that appends a `LoginFlowDestination` to the
    ///     `NavigationStack` path, pushing the corresponding screen. Provided by
    ///     `AuthSheetContainer`; pass `nil` when presenting `LoginView` standalone.
    ///   - prefilledEmail: Optional email to pre-populate the email field (e.g. for Xcode Previews).
    ///   - prefilledPassword: Optional password to pre-populate the password field.
    ///   - initialErrorMessage: Optional inline error message to display immediately on appear
    ///     (shown below the password field — use for validation errors such as invalid credentials).
    ///   - initialToastErrorMessage: Optional toast error message to display immediately on appear
    ///     (shown at the bottom of the screen — use for network/server/provider errors).
    ///   - initialIsLoading: When `true`, the login button shows a loading indicator on appear.
    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        navigateTo: ((LoginFlowDestination) -> Void)? = nil,
        prefilledEmail: String = "",
        prefilledPassword: String = "",
        initialErrorMessage: String? = nil,
        initialToastErrorMessage: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.authManager = authManager
        self.navigateTo = navigateTo
        let vm = LoginViewModel(
            networkService: networkService,
            localizationBundle: authManager.configuration.localizationBundle,
            initialEmail: prefilledEmail,
            initialPassword: prefilledPassword,
            initialErrorMessage: initialErrorMessage,
            initialToastErrorMessage: initialToastErrorMessage,
            initialIsLoading: initialIsLoading
        )
        self._viewModel = State(wrappedValue: vm)
        self._appleSignInHandler = State(wrappedValue: AppleSignInHandler(
            authManager: authManager,
            viewModel: vm
        ))
        self._googleSignInHandler = State(wrappedValue: GoogleSignInHandler(
            authManager: authManager,
            viewModel: vm
        ))
    }

    public var body: some View {
        content
            .environment(\.authTheme, theme)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    titleSection
                    Spacer().frame(height: 24)
                    emailField
                    Spacer().frame(height: 14)
                    passwordField
                    errorRow
                    forgotPasswordLink
                    Spacer().frame(height: 24)
                    loginButton
                    if hasAnySocialOrGuestButton {
                        Spacer().frame(height: 16)
                        orDivider
                        Spacer().frame(height: 16)
                    }
                    if authManager.configuration.allowAppleSignIn {
                        appleSignInButton
                        Spacer().frame(height: 8)
                    }
                    if authManager.configuration.allowGoogleSignIn {
                        googleSignInButton
                        Spacer().frame(height: 8)
                    }
                    if authManager.configuration.allowGuestAccess && !authManager.session.isGuest {
                        guestButton
                        Spacer().frame(height: 8)
                    }
                    Spacer().frame(height: 32)
                    registerLink
                    Spacer().frame(height: 32)
                }
                .padding(.horizontal, 16)
                // Apply custom base font when configured; child modifiers override as needed.
                .font(theme.font)
                // Disable all interaction while a login request or social sign-in is in flight.
                .allowsHitTesting(
                    !viewModel.isLoading
                    && !viewModel.isGuestLoading
                    && !appleSignInHandler.isLoading
                    && !googleSignInHandler.isLoading
                )
            }

            // Full-screen loading overlay shown while a social sign-in server call is in flight.
            // Under accessibilityReduceTransparency an opaque background is used instead of the
            // semi-transparent one — per design-system.md §12 and §10.10.
            if appleSignInHandler.isLoading || googleSignInHandler.isLoading {
                (reduceTransparency ? theme.backgroundColor : theme.backgroundColor.opacity(0.8))
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
            }

            // Toast overlay for non-validation errors (network, server, provider).
            // Pinned to the bottom of the screen; tapping it dismisses the error.
            if viewModel.toastErrorMessage != nil {
                toastOverlay
            }
        }
        // Fill all space proposed by NavigationStack so no gaps appear below content.
        // ignoresSafeArea() extends the background behind the Dynamic Island and home indicator.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.ignoresSafeArea())
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "auth.login.title", bundle: bundle))
                .font(.title.bold())
                .foregroundStyle(theme.primaryTextColor)
            Text(String(localized: "auth.login.subtitle", bundle: bundle))
                .font(.callout)
                .foregroundStyle(theme.secondaryTextColor)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailField: some View {
        TextField(String(localized: "auth.login.field.email.placeholder", bundle: bundle), text: $viewModel.email)
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
    }

    private var passwordField: some View {
        PasswordFieldView(
            text: $viewModel.password,
            onSubmit: { Task { await viewModel.login(authManager: authManager) } },
            bundle: bundle
        )
    }

    @ViewBuilder
    private var errorRow: some View {
        if let message = viewModel.inlineErrorMessage {
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
    }

    /// Toast banner shown at the bottom of the screen for non-validation errors.
    ///
    /// Displays a dismissible banner for network, server, and provider errors.
    /// Tapping the banner calls `viewModel.dismissToast()`.
    private var toastOverlay: some View {
        VStack {
            Spacer()
            if let message = viewModel.toastErrorMessage {
                Button {
                    viewModel.dismissToast()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                        Text(message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(theme.errorColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(message)
                .accessibilityHint(String(localized: "auth.toast.dismiss.hint", bundle: bundle))
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button {
                navigateTo?(.forgotPassword(prefilledEmail: viewModel.email))
            } label: {
                Text(String(localized: "auth.login.link.forgot_password", bundle: bundle))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.primaryColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private var loginButton: some View {
        Button {
            Task { await viewModel.login(authManager: authManager) }
        } label: {
            Group {
                if viewModel.isLoading {
                    // .colorScheme(.dark) renders the spinner in white on both iOS and macOS.
                    ProgressView()
                        .colorScheme(.dark)
                } else {
                    Text(String(localized: "auth.login.button.submit", bundle: bundle))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.buttonTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            // Full color when form is valid; muted when empty fields regardless of loading.
            .background(
                viewModel.canSubmit
                    ? theme.primaryColor
                    : theme.primaryDisabled
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        // Only disable for empty fields — loading is blocked by the parent .allowsHitTesting.
        // Keeping disabled off during loading preserves the full-colour spinner appearance.
        .disabled(!viewModel.canSubmit)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.primaryTextColor.opacity(0.1))
                .accessibilityHidden(true)
            Text(String(localized: "auth.separator.or", bundle: bundle))
                .font(.footnote)
                .foregroundStyle(theme.secondaryTextColor)
                .textCase(.uppercase)
                .accessibilityHidden(true)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.primaryTextColor.opacity(0.1))
                .accessibilityHidden(true)
        }
    }

    private var appleSignInButton: some View {
        Button {
            appleSignInHandler.performSignIn()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text(String(localized: "auth.button.apple", bundle: bundle))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.appleButtonLabel)
            }
            .foregroundColor(theme.appleButtonLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(theme.appleButtonBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "auth.button.apple.accessibility", bundle: bundle))
    }

    private var googleSignInButton: some View {
        Button {
            googleSignInHandler.performSignIn()
        } label: {
            HStack(spacing: 8) {
                Image("google-logo", bundle: .module)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text(String(localized: "auth.button.google", bundle: bundle))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.primaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: theme.googleButtonStyle.height)
            .background(theme.googleButtonStyle.background)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    theme.googleButtonStyle.borderColor,
                    lineWidth: theme.googleButtonStyle.borderWidth
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "auth.button.google.accessibility", bundle: bundle))
    }

    private var guestButton: some View {
        Button {
            Task { await viewModel.loginAsGuest(authManager: authManager) }
        } label: {
            Group {
                if viewModel.isGuestLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(String(localized: "auth.login.button.guest", bundle: bundle))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(theme.primaryTextColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: theme.googleButtonStyle.height)
            .background(theme.googleButtonStyle.background)
            .clipShape(Capsule())
            // Use the same border token as the Google button so both respond consistently
            // to a customised primary colour in AuthClientConfiguration.
            .overlay(
                Capsule().strokeBorder(
                    theme.googleButtonStyle.borderColor,
                    lineWidth: theme.googleButtonStyle.borderWidth
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "auth.login.button.guest", bundle: bundle))
    }

    private var registerLink: some View {
        HStack {
            Spacer()
            Button {
                navigateTo?(.register)
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "auth.login.register_prompt", bundle: bundle))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryTextColor)
                    Text(String(localized: "auth.login.register_link", bundle: bundle))
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

private struct PasswordFieldView: View {
    @Binding var text: String
    var onSubmit: () -> Void = {}
    var bundle: Bundle = .module
    @State private var isVisible: Bool = false
    @Environment(\.authTheme) private var theme

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(
                        String(localized: "auth.login.field.password.placeholder", bundle: bundle),
                        text: $text
                    )
                    .textContentType(.password)
                    .submitLabel(.go)
                    .foregroundStyle(theme.primaryTextColor)
                    .textFieldStyle(.plain)
                    .onSubmit { onSubmit() }
                } else {
                    SecureField(
                        String(localized: "auth.login.field.password.placeholder", bundle: bundle),
                        text: $text
                    )
                    .textContentType(.password)
                    .submitLabel(.go)
                    .foregroundStyle(theme.primaryTextColor)
                    .textFieldStyle(.plain)
                    .onSubmit { onSubmit() }
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

private struct PreviewNetworkService: AuthNetworkService {
    func login(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func register(email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func forgotPassword(email: String) async throws {
        throw AuthNetworkError.serverError
    }

    func resetPassword(token: String, newPassword: String) async throws {
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

    func changePassword(currentPassword: String, newPassword: String, accessToken: String) async throws {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static var preview: AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}

#Preview("Default — empty") {
    LoginView(authManager: .preview, networkService: PreviewNetworkService())
}

#Preview("With inputs") {
    LoginView(
        authManager: .preview,
        networkService: PreviewNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "secret123"
    )
}

#Preview("Loading") {
    LoginView(
        authManager: .preview,
        networkService: PreviewNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "secret123",
        initialIsLoading: true
    )
}

#Preview("Invalid credentials") {
    LoginView(
        authManager: .preview,
        networkService: PreviewNetworkService(),
        prefilledEmail: "user@example.com",
        prefilledPassword: "wrongpass",
        initialErrorMessage: "Incorrect email or password."
    )
}

#Preview("No guest access") {
    LoginView(
        authManager: AuthManager(configuration: AuthClientConfiguration(allowGuestAccess: false)),
        networkService: PreviewNetworkService()
    )
}

#endif
