import SwiftUI

/// The primary email/password sign-in screen.
///
/// Rendered as the initial screen inside the `.authSheet` bottom sheet.
/// All user-facing strings use localisation keys defined in `Localizable.strings`.
/// All colours and spacing use design system tokens sourced from `AuthClientConfiguration`.
public struct LoginView: View {

    // MARK: - Dependencies

    @State private var viewModel: LoginViewModel
    @Environment(AuthManager.self) private var authManager

    // MARK: - Init

    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                screenTitle
                    .padding(.bottom, AuthSpacing.lg)

                emailField
                    .padding(.bottom, viewModel.errorMessage != nil ? AuthSpacing.xs : AuthSpacing.xs)

                passwordField
                    .padding(.bottom, AuthSpacing.xs)

                if let errorMessage = viewModel.errorMessage {
                    inlineErrorView(message: errorMessage)
                        .padding(.bottom, AuthSpacing.sm)
                }

                forgotPasswordLink
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, AuthSpacing.lg)

                loginButton
                    .padding(.bottom, AuthSpacing.lg)

                orSeparator
                    .padding(.bottom, AuthSpacing.lg)

                signInWithAppleButton
                    .padding(.bottom, AuthSpacing.sm)

                signInWithGoogleButton
                    .padding(.bottom, AuthSpacing.sm)

                if authManager.configuration.allowGuestAccess {
                    continueAsGuestButton
                        .padding(.bottom, AuthSpacing.sm)
                }

                Spacer(minLength: AuthSpacing.xl)

                registerLink
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, AuthSpacing.xl)
            }
            .padding(.horizontal, AuthSpacing.md)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Screen Title

    private var screenTitle: some View {
        Text("auth.login.title", bundle: .module)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.primary)
    }

    // MARK: - Email Field

    private var emailField: some View {
        AuthTextField(
            text: $viewModel.email,
            placeholder: String(localized: "auth.login.field.email.placeholder", bundle: .module),
            isError: false
        )
#if canImport(UIKit)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
#endif
        .autocorrectionDisabled()
        .accessibilityLabel(String(localized: "auth.login.field.email.placeholder", bundle: .module))
    }

    // MARK: - Password Field

    private var passwordField: some View {
        AuthSecureField(
            text: $viewModel.password,
            isVisible: $viewModel.isPasswordVisible,
            placeholder: String(localized: "auth.login.field.password.placeholder", bundle: .module),
            isError: false
        )
#if canImport(UIKit)
        .textContentType(.password)
#endif
        .onSubmit {
            Task { await viewModel.login() }
        }
        .accessibilityLabel(String(localized: "auth.login.field.password.placeholder", bundle: .module))
    }

    // MARK: - Inline Error

    private func inlineErrorView(message: String) -> some View {
        Label {
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color(red: 1, green: 0.231, blue: 0.188)) // system red — color.error token
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color(red: 1, green: 0.231, blue: 0.188))
        }
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Forgot Password

    private var forgotPasswordLink: some View {
        Button {
            // Navigation to ForgotPasswordView — will be wired in the nav task
        } label: {
            Text("auth.login.link.forgot_password", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        AuthPrimaryButton(
            label: String(localized: "auth.login.button.submit", bundle: .module),
            isLoading: viewModel.isLoading,
            isEnabled: viewModel.canSubmit
        ) {
            Task { await viewModel.login() }
        }
        .accessibilityLabel(String(localized: "auth.login.button.submit", bundle: .module))
    }

    // MARK: - Or Separator

    private var orSeparator: some View {
        AuthOrSeparator()
    }

    // MARK: - Sign In with Apple

    private var signInWithAppleButton: some View {
        // SignInWithAppleButton requires AuthenticationServices — implemented in a separate task.
        // Placeholder uses a styled button to keep the layout complete.
        AuthSocialAppleButton {
            // Apple sign-in — wired in the Apple auth task
        }
    }

    // MARK: - Sign In with Google

    private var signInWithGoogleButton: some View {
        AuthSocialGoogleButton {
            // Google sign-in — wired in the Google auth task
        }
    }

    // MARK: - Continue as Guest

    private var continueAsGuestButton: some View {
        Button {
            // Guest session — wired in the guest auth task
        } label: {
            Text("auth.login.button.guest", bundle: .module)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(Color.accentColor)
        }
        .accessibilityLabel(String(localized: "auth.login.button.guest", bundle: .module))
    }

    // MARK: - Register Link

    private var registerLink: some View {
        Button {
            // Navigation to RegisterView — wired in the nav task
        } label: {
            Text("auth.login.link.register", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
        }
    }
}
