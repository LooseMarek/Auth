import AuthenticationServices
import SwiftUI

public struct LoginView: View {
    @State private var viewModel: LoginViewModel
    private let authManager: AuthManager

    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        prefilledEmail: String = "",
        prefilledPassword: String = "",
        initialErrorMessage: String? = nil
    ) {
        self.authManager = authManager
        self._viewModel = State(wrappedValue: LoginViewModel(
            networkService: networkService,
            initialEmail: prefilledEmail,
            initialPassword: prefilledPassword,
            initialErrorMessage: initialErrorMessage
        ))
    }

    public var body: some View {
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
                Spacer().frame(height: 16)
                orDivider
                Spacer().frame(height: 16)
                appleSignInButton
                Spacer().frame(height: 8)
                googleSignInButton
                if authManager.configuration.allowGuestAccess {
                    Spacer().frame(height: 8)
                    guestButton
                }
                Spacer().frame(height: 32)
                registerLink
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
        .background(authManager.configuration.backgroundColor)
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back")
                .font(.title)
                .bold()
                .foregroundStyle(Color.primary)
            Text("Sign in to pick up where you left off.")
                .font(.callout)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailField: some View {
        TextField("you@email.com", text: $viewModel.email)
#if canImport(UIKit)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
#endif
            .textContentType(.emailAddress)
            .submitLabel(.next)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.init(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var passwordField: some View {
        PasswordFieldView(text: $viewModel.password)
    }

    @ViewBuilder
    private var errorRow: some View {
        if let message = viewModel.errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.red)
            }
            .padding(.top, 4)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button("Forgot password?") {}
                .font(.subheadline.weight(.medium))
                .foregroundStyle(authManager.configuration.primaryColor)
        }
        .padding(.top, 4)
    }

    private var loginButton: some View {
        Button {
            Task { await viewModel.login(authManager: authManager) }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log in")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(
            viewModel.canSubmit && !viewModel.isLoading
                ? authManager.configuration.primaryColor
                : authManager.configuration.primaryColor.opacity(0.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(!viewModel.canSubmit || viewModel.isLoading)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.secondary.opacity(0.2))
                .accessibilityHidden(true)
            Text("or")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .accessibilityHidden(true)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.secondary.opacity(0.2))
                .accessibilityHidden(true)
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { _ in } onCompletion: { _ in }
            .frame(height: 50)
            .clipShape(Capsule())
    }

    private var googleSignInButton: some View {
        Button {
        } label: {
            HStack(spacing: 8) {
                GoogleLogoView()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text("Sign in with Google")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .overlay(Capsule().stroke(Color(.init(red: 0.855, green: 0.804, blue: 0.878, alpha: 1)), lineWidth: 1))
        .accessibilityLabel("Sign in with Google")
    }

    private var guestButton: some View {
        Button("Continue as Guest") {}
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
    }

    private var registerLink: some View {
        HStack {
            Spacer()
            Button {
            } label: {
                Text("Don't have an account? ")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
                + Text("Register")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(authManager.configuration.primaryColor)
            }
            Spacer()
        }
    }
}

// MARK: - Supporting views

private struct PasswordFieldView: View {
    @Binding var text: String
    @State private var isVisible: Bool = false

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField("Password", text: $text)
                        .textContentType(.password)
                        .submitLabel(.go)
                } else {
                    SecureField("Password", text: $text)
                        .textContentType(.password)
                        .submitLabel(.go)
                }
            }
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(.init(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Minimal multi-colour Google "G" mark built from SwiftUI shapes.
private struct GoogleLogoView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: s, height: s)
                Text("G")
                    .font(.system(size: s * 0.65, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
    }
}
