import SwiftUI
import AuthenticationServices

private enum Layout {
    static let spacingXS: CGFloat = 8
    static let spacingSM: CGFloat = 12
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let fieldHeight: CGFloat = 50
    static let buttonHeight: CGFloat = 50
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 10
    static let googleIconSize: CGFloat = 20
    static let macOSMaxWidth: CGFloat = 400
    static let toggleTapTarget: CGFloat = 44
}

private enum Strings {
    static let title = "Welcome back"
    static let emailPlaceholder = "Email"
    static let passwordPlaceholder = "Password"
    static let submitButton = "Log in"
    static let forgotPassword = "Forgot password?"
    static let registerLink = "Don't have an account? Register"
    static let guestButton = "Continue as Guest"
    static let or = "or"
    static let showPassword = "Show password"
    static let hidePassword = "Hide password"
    static let googleButton = "Sign in with Google"
}

public struct LoginView<ViewModel: LoginViewModelProtocol>: View {

    @State var viewModel: ViewModel
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Layout.spacingMD)
#if canImport(AppKit)
                .frame(maxWidth: Layout.macOSMaxWidth)
                .frame(maxWidth: .infinity)
#endif
        }
        .background(viewModel.configuration.backgroundColor)
    }

    // MARK: - Main content stack

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
            Spacer().frame(height: Layout.spacingLG)
            emailField
            Spacer().frame(height: Layout.spacingXS)
            passwordField
            if let error = viewModel.passwordError {
                Spacer().frame(height: Layout.spacingXS)
                inlineError(error)
            }
            Spacer().frame(height: Layout.spacingSM)
            forgotPasswordLink
            Spacer().frame(height: Layout.spacingLG)
            loginButton
            if let error = viewModel.serverError {
                Spacer().frame(height: Layout.spacingXS)
                inlineError(error)
            }
            Spacer().frame(height: Layout.spacingLG)
            orSeparator
            Spacer().frame(height: Layout.spacingLG)
            appleSignInButton
            Spacer().frame(height: Layout.spacingSM)
            googleSignInButton
            if viewModel.configuration.allowGuestAccess {
                Spacer().frame(height: Layout.spacingSM)
                guestButton
            }
            Spacer().frame(height: Layout.spacingXL)
            registerLink
            Spacer().frame(height: Layout.spacingXL)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        Text(Strings.title)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.primary)
    }

    // MARK: - Email field

    private var emailField: some View {
        let hasError = viewModel.emailError != nil
        return VStack(alignment: .leading, spacing: Layout.spacingXS) {
            TextField(Strings.emailPlaceholder, text: $viewModel.email)
                .autocorrectionDisabled()
#if canImport(UIKit)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
#endif
                .font(.body)
                .padding(.horizontal, Layout.spacingSM)
                .frame(height: Layout.fieldHeight)
                .background(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.radiusSM)
                        .stroke(
                            hasError ? Color(.systemRed) : fieldBorderColor,
                            lineWidth: hasError ? 1.5 : 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: Layout.radiusSM))
                .disabled(viewModel.isLoading)
                .submitLabel(.next)
                .accessibilityLabel(Strings.emailPlaceholder)

            if let error = viewModel.emailError {
                inlineError(error)
            }
        }
    }

    // MARK: - Password field

    private var passwordField: some View {
        let hasError = viewModel.passwordError != nil
        return ZStack(alignment: .trailing) {
            Group {
                if viewModel.isPasswordVisible {
                    TextField(Strings.passwordPlaceholder, text: $viewModel.password)
#if canImport(UIKit)
                        .textContentType(.password)
#endif
                        .submitLabel(.go)
                        .accessibilityLabel(Strings.passwordPlaceholder)
                } else {
                    SecureField(Strings.passwordPlaceholder, text: $viewModel.password)
#if canImport(UIKit)
                        .textContentType(.password)
#endif
                        .submitLabel(.go)
                        .accessibilityLabel(Strings.passwordPlaceholder)
                }
            }
            .font(.body)
            .padding(.leading, Layout.spacingSM)
            .padding(.trailing, Layout.spacingXL + Layout.spacingMD)
            .frame(height: Layout.fieldHeight)
            .background(fieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.radiusSM)
                    .stroke(
                        hasError ? Color(.systemRed) : fieldBorderColor,
                        lineWidth: hasError ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.radiusSM))
            .disabled(viewModel.isLoading)

            Button {
                viewModel.isPasswordVisible.toggle()
            } label: {
                Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondary)
                    .frame(width: Layout.toggleTapTarget, height: Layout.toggleTapTarget)
            }
            .accessibilityLabel(viewModel.isPasswordVisible ? Strings.hidePassword : Strings.showPassword)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Inline error

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: Layout.spacingXS) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color(.systemRed))
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color(.systemRed))
        }
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Forgot password

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button(Strings.forgotPassword) {
                viewModel.onForgotPassword?()
            }
            .font(.subheadline)
            .foregroundStyle(viewModel.configuration.primaryColor)
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Login button

    private var loginButton: some View {
        Button {
            Task { await viewModel.loginAction() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(Strings.submitButton)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.buttonHeight)
        }
        .background(viewModel.configuration.primaryColor)
        .clipShape(RoundedRectangle(cornerRadius: Layout.radiusMD))
        .opacity(viewModel.isFormValid || viewModel.isLoading ? 1.0 : 0.5)
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .accessibilityLabel(Strings.submitButton)
    }

    // MARK: - Or separator

    private var orSeparator: some View {
        HStack(spacing: Layout.spacingSM) {
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
                .accessibilityHidden(true)
            Text(Strings.or)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
                .accessibilityHidden(true)
        }
    }

    private var separatorColor: Color {
#if canImport(UIKit)
        Color(UIColor.separator)
#else
        Color(NSColor.separatorColor)
#endif
    }

    // MARK: - Sign in with Apple

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { _ in
            // Stub — Apple sign-in token handling is task #24
        } onCompletion: { _ in
            // Stub — Apple sign-in token handling is task #24
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: Layout.buttonHeight)
        .clipShape(Capsule())
        .disabled(viewModel.isLoading)
    }

    // MARK: - Sign in with Google

    private var googleSignInButton: some View {
        Button {
            // Stub — Google sign-in token handling is task #25
        } label: {
            HStack(spacing: 0) {
                googleGIcon
                    .padding(.leading, Layout.spacingMD)
                Spacer()
                Text(Strings.googleButton)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 31/255, green: 31/255, blue: 31/255))
                Spacer()
                Spacer()
                    .frame(width: Layout.googleIconSize + Layout.spacingMD)
            }
            .frame(height: Layout.buttonHeight)
            .background(Color.white)
            .overlay(
                Capsule()
                    .stroke(Color(red: 116/255, green: 119/255, blue: 117/255), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel(Strings.googleButton)
    }

    private var googleGIcon: some View {
        // Placeholder for the Google G logo — replaced with the actual SVG asset in task #28.
        Rectangle()
            .fill(Color(red: 66/255, green: 133/255, blue: 244/255))
            .frame(width: Layout.googleIconSize, height: Layout.googleIconSize)
    }

    // MARK: - Guest button

    private var guestButton: some View {
        Button {
            viewModel.onGuestAccess?()
        } label: {
            Text(Strings.guestButton)
                .font(.body.weight(.semibold))
                .foregroundStyle(viewModel.configuration.primaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
        }
        .disabled(viewModel.isLoading)
        .accessibilityLabel(Strings.guestButton)
    }

    // MARK: - Register link

    private var registerLink: some View {
        HStack {
            Spacer()
            Button(Strings.registerLink) {
                viewModel.onRegister?()
            }
            .font(.subheadline)
            .foregroundStyle(viewModel.configuration.primaryColor)
            .disabled(viewModel.isLoading)
            Spacer()
        }
    }

    // MARK: - Platform adaptive colors

    private var fieldBackground: Color {
#if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
#else
        Color(NSColor.controlBackgroundColor)
#endif
    }

    private var fieldBorderColor: Color {
#if canImport(UIKit)
        Color(UIColor.systemFill)
#else
        Color(NSColor.separatorColor)
#endif
    }
}

// MARK: - Previews

#if DEBUG
@Observable
@MainActor
private final class PreviewLoginViewModel: LoginViewModelProtocol {
    var email: String
    var password: String
    var isPasswordVisible: Bool
    var isLoading: Bool
    var isFormValid: Bool
    var emailError: String?
    var passwordError: String?
    var serverError: String?
    var onForgotPassword: (() -> Void)?
    var onRegister: (() -> Void)?
    var onGuestAccess: (() -> Void)?
    var configuration: AuthClientConfiguration

    func loginAction() async {}

    init(
        email: String = "",
        password: String = "",
        isPasswordVisible: Bool = false,
        isLoading: Bool = false,
        isFormValid: Bool = false,
        emailError: String? = nil,
        passwordError: String? = nil,
        serverError: String? = nil,
        configuration: AuthClientConfiguration = AuthClientConfiguration()
    ) {
        self.email = email
        self.password = password
        self.isPasswordVisible = isPasswordVisible
        self.isLoading = isLoading
        self.isFormValid = isFormValid
        self.emailError = emailError
        self.passwordError = passwordError
        self.serverError = serverError
        self.configuration = configuration
    }
}

#Preview("Default") {
    LoginView(viewModel: PreviewLoginViewModel())
}

#Preview("Email Error") {
    LoginView(viewModel: PreviewLoginViewModel(
        email: "not-an-email",
        password: "password123",
        emailError: "Please enter a valid email address."
    ))
}

#Preview("Loading") {
    LoginView(viewModel: PreviewLoginViewModel(
        email: "user@example.com",
        password: "password123",
        isLoading: true,
        isFormValid: true
    ))
}

#Preview("Server Error") {
    LoginView(viewModel: PreviewLoginViewModel(
        email: "user@example.com",
        password: "password123",
        isFormValid: true,
        serverError: "Something went wrong. Please try again."
    ))
}
#endif
