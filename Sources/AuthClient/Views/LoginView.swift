import SwiftUI
import AuthenticationServices

// MARK: - LoginView

/// The primary email/password sign-in screen.
///
/// Presented inside the `.authSheet` bottom sheet. Backed by `LoginViewModel`.
public struct LoginView: View {

    // MARK: - State

    @State var viewModel: LoginViewModel
    private let configuration: AuthClientConfiguration

    /// Controls whether the password field shows plain text.
    @State private var isPasswordVisible: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Init

    public init(viewModel: LoginViewModel, configuration: AuthClientConfiguration) {
        self._viewModel = State(wrappedValue: viewModel)
        self.configuration = configuration
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleSection
                emailSection
                passwordSection
                forgotPasswordLink
                loginButton
                orSeparator
                appleSignInButton
                googleSignInButton
                guestButton
                registerLink
            }
            .padding(.horizontal, 16) // spacing.md
            // Cap width at 400pt on macOS and centre
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity)
        }
        .background(configuration.backgroundColor)
    }

    // MARK: - Title

    private var titleSection: some View {
        Text("Welcome back")
            .font(.title2).fontWeight(.semibold) // type.title
            .foregroundColor(.primary)           // color.label.primary
            .padding(.bottom, 24)                // spacing.lg
    }

    // MARK: - Email field

    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            AuthTextField(
                placeholder: "Email",
                text: $viewModel.email,
                hasError: viewModel.errorMessage != nil && viewModel.email.isEmpty
            )
            .modifier(EmailFieldModifiers())
            .accessibilityLabel("Email")
            .disabled(viewModel.isLoading)
        }
        .padding(.bottom, 8) // spacing.xs
    }

    // MARK: - Password field

    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) { // spacing.xs
            ZStack(alignment: .trailing) {
                if isPasswordVisible {
                    AuthTextField(
                        placeholder: "Password",
                        text: $viewModel.password,
                        hasError: false
                    )
                    .modifier(PasswordFieldModifiers())
                    .accessibilityLabel("Password")
                    .disabled(viewModel.isLoading)
                } else {
                    AuthSecureField(
                        placeholder: "Password",
                        text: $viewModel.password,
                        hasError: false
                    )
                    .modifier(PasswordFieldModifiers())
                    .accessibilityLabel("Password")
                    .disabled(viewModel.isLoading)
                }

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary) // color.label.secondary
                        .frame(width: 44, height: 44) // min tap target
                }
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                .disabled(viewModel.isLoading)
            }

            // Inline error message
            if let errorMessage = viewModel.errorMessage {
                inlineError(errorMessage)
            }
        }
        .padding(.bottom, 8) // spacing.xs
    }

    // MARK: - Forgot password link

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button {
                // Navigation handled by parent NavigationStack
            } label: {
                Text("Forgot password?")
                    .font(.subheadline) // type.subhead
                    .foregroundColor(configuration.primaryColor)
            }
            .accessibilityLabel("Forgot password?")
            .disabled(viewModel.isLoading)
        }
        .padding(.bottom, 24) // spacing.lg
    }

    // MARK: - Login button

    private var loginButton: some View {
        let isDisabled = viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading

        return Button {
            Task { await viewModel.login() }
        } label: {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.white) // color.label.on-primary
                } else {
                    Text("Log in")
                        .font(.body).fontWeight(.semibold) // type.button
                        .foregroundColor(.white)           // color.label.on-primary
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50) // 50pt height per design system
        }
        .background(isDisabled ? configuration.primaryColor.opacity(0.5) : configuration.primaryColor)
        .cornerRadius(10) // radius.md
        .disabled(isDisabled)
        .accessibilityLabel("Log in")
        .accessibilityHint("Double tap to log in")
        .padding(.bottom, 24) // spacing.lg
    }

    // MARK: - "Or" separator

    private var orSeparator: some View {
        HStack {
            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
                .accessibilityHidden(true)

            Text("or")
                .font(.subheadline) // type.subhead
                .foregroundColor(.secondary) // color.label.secondary
                .padding(.horizontal, 12) // spacing.sm

            Rectangle()
                .fill(separatorColor)
                .frame(height: 1)
                .accessibilityHidden(true)
        }
        .padding(.bottom, 24) // spacing.lg
    }

    // MARK: - Sign in with Apple

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { _ in
            // Social sign-in handled in task #24
        } onCompletion: { _ in
            // Social sign-in handled in task #24
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50) // 50pt height per design system
        .clipShape(Capsule()) // radius.pill
        .disabled(viewModel.isLoading)
        .padding(.bottom, 12) // spacing.sm
    }

    // MARK: - Sign in with Google

    private var googleSignInButton: some View {
        Button {
            // Google sign-in handled in task #25
        } label: {
            HStack(spacing: 0) {
                // Google "G" logo placeholder — replaced with asset in theming task
                Image(systemName: "g.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(googleLabelColor)
                    .padding(.leading, 16) // spacing.md

                Spacer()

                Text("Sign in with Google")
                    .font(.system(size: 15, weight: .medium)) // type.social-button
                    .foregroundColor(googleLabelColor)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(Color.white) // color.google.background — always white per Google brand guidelines
        .clipShape(Capsule()) // radius.pill
        .overlay(
            Capsule()
                .stroke(googleBorderColor, lineWidth: 1) // border.google
        )
        .accessibilityLabel("Sign in with Google")
        .disabled(viewModel.isLoading)
        .padding(.bottom, 12) // spacing.sm
    }

    // MARK: - Guest button

    @ViewBuilder
    private var guestButton: some View {
        if configuration.allowGuestAccess {
            Button {
                // Guest flow handled in task #27
            } label: {
                Text("Continue as Guest")
                    .font(.body).fontWeight(.semibold) // type.button
                    .foregroundColor(configuration.primaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .accessibilityLabel("Continue as Guest")
            .disabled(viewModel.isLoading)
            .padding(.bottom, 32) // spacing.xl
        }
    }

    // MARK: - Register link

    private var registerLink: some View {
        HStack {
            Spacer()
            Button {
                // Navigation handled by parent NavigationStack
            } label: {
                Text("Don't have an account? Register")
                    .font(.subheadline) // type.subhead
                    .foregroundColor(configuration.primaryColor)
            }
            .accessibilityLabel("Don't have an account? Register")
            .disabled(viewModel.isLoading)
            Spacer()
        }
        .padding(.bottom, 32) // spacing.xl
    }

    // MARK: - Inline error helper

    private func inlineError(_ message: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.footnote) // 13pt, color.error
                .foregroundColor(.red)

            Text(message)
                .font(.footnote) // type.footnote
                .foregroundColor(.red) // color.error
        }
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Platform-adaptive color helpers

    private var separatorColor: Color {
#if canImport(UIKit)
        Color(UIColor.separator)
#else
        Color(NSColor.separatorColor)
#endif
    }

    private var googleLabelColor: Color {
        Color(red: 0.122, green: 0.122, blue: 0.122)
    }

    private var googleBorderColor: Color {
        Color(red: 0.455, green: 0.467, blue: 0.459)
    }
}

// MARK: - AuthTextField

/// A reusable styled text field matching the design system.
struct AuthTextField: View {

    let placeholder: String
    @Binding var text: String
    let hasError: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body) // type.body
            .padding(.horizontal, 12) // spacing.sm
            .frame(height: 50) // 50pt height per design system
            .background(fieldBackground)
            .cornerRadius(6) // radius.sm
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        hasError ? Color.red : fieldBorderColor, // border.field or border.field.error
                        lineWidth: hasError ? 1.5 : 1
                    )
            )
    }

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

// MARK: - AuthSecureField

/// A reusable styled secure field matching the design system.
struct AuthSecureField: View {

    let placeholder: String
    @Binding var text: String
    let hasError: Bool

    var body: some View {
        SecureField(placeholder, text: $text)
            .font(.body) // type.body
            .padding(.horizontal, 12) // spacing.sm
            .frame(height: 50)
            .background(fieldBackground)
            .cornerRadius(6) // radius.sm
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        hasError ? Color.red : fieldBorderColor,
                        lineWidth: hasError ? 1.5 : 1
                    )
            )
    }

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

// MARK: - Platform modifier helpers

/// Applies UIKit-specific email field modifiers where available.
private struct EmailFieldModifiers: ViewModifier {
    func body(content: Content) -> some View {
#if canImport(UIKit)
        content
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
#else
        content
#endif
    }
}

/// Applies UIKit-specific password field modifiers where available.
private struct PasswordFieldModifiers: ViewModifier {
    func body(content: Content) -> some View {
#if canImport(UIKit)
        content
            .textContentType(.password)
#else
        content
#endif
    }
}
