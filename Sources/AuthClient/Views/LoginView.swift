import AuthenticationServices
import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct LoginView: View {
    @State private var viewModel: LoginViewModel
    private let authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        prefilledEmail: String = "",
        prefilledPassword: String = "",
        initialErrorMessage: String? = nil,
        initialIsLoading: Bool = false
    ) {
        self.authManager = authManager
        self._viewModel = State(wrappedValue: LoginViewModel(
            networkService: networkService,
            initialEmail: prefilledEmail,
            initialPassword: prefilledPassword,
            initialErrorMessage: initialErrorMessage,
            initialIsLoading: initialIsLoading
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
            // Disable all interaction while a login request is in flight.
            .allowsHitTesting(!viewModel.isLoading)
        }
        .background(authManager.configuration.backgroundColor)
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back")
                .font(.title.bold())
                .foregroundStyle(Color.primary)
            Text("Sign in to pick up where you left off.")
                .font(.callout)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailField: some View {
        TextField("Email", text: $viewModel.email)
#if canImport(UIKit)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
#endif
            .textContentType(.emailAddress)
            .submitLabel(.next)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(AuthColors.surface)
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
                    Text("Log in")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            // Full color when form is valid; muted when empty fields regardless of loading.
            .background(
                viewModel.canSubmit
                    ? authManager.configuration.primaryColor
                    : authManager.configuration.primaryColor.opacity(0.8)
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
                .foregroundStyle(Color.primary.opacity(0.1))
                .accessibilityHidden(true)
            Text("or")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .accessibilityHidden(true)
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.primary.opacity(0.1))
                .accessibilityHidden(true)
        }
    }

    private var appleSignInButton: some View {
        Button {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()

            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(
                authorizationRequests: [request]
            )

            controller.performRequests()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)

                Text("Sign in with Apple")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var googleSignInButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image("google-logo", bundle: .module)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text("Sign in with Google")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.clear)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sign in with Google")
    }

    private var guestButton: some View {
        Button {} label: {
            Text("Continue as Guest")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.clear)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var registerLink: some View {
        HStack {
            Spacer()
            Button {} label: {
                Text("Don't have an account? ")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
                + Text("Register")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(authManager.configuration.primaryColor)
            }
            .buttonStyle(.plain)
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
                        .textFieldStyle(.plain)
                } else {
                    SecureField("Password", text: $text)
                        .textContentType(.password)
                        .submitLabel(.go)
                        .textFieldStyle(.plain)
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
            .buttonStyle(.plain)
            .accessibilityLabel(isVisible ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(AuthColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Internal colour helpers

private enum AuthColors {
    /// Field fill — `color.surface` token: #F5F5F7 light / #2C2C2E dark.
    #if canImport(UIKit)
    static let surface = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
    })
    #else
    static let surface = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
    })
    #endif
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
