import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct RegisterView: View {
    @State private var viewModel: RegisterViewModel
    private let authManager: AuthManager
    @Environment(\.colorScheme) private var colorScheme

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
            initialEmail: prefilledEmail,
            initialPassword: prefilledPassword,
            initialConfirmPassword: prefilledConfirmPassword,
            initialConfirmPasswordError: initialConfirmPasswordError,
            initialIsLoading: initialIsLoading
        ))
    }

    public var body: some View {
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
            .allowsHitTesting(!viewModel.isLoading)
        }
        .background(authManager.configuration.backgroundColor)
    }

    // MARK: - Subviews

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Create account")
                .font(.title.bold())
                .foregroundStyle(Color.primary)
            Text("Takes about 20 seconds. No payment needed.")
                .font(.callout)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("you@email.com", text: $viewModel.email)
#if canImport(UIKit)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
#endif
                .textContentType(.emailAddress)
                .submitLabel(.next)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(RegisterColors.surface)
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
                placeholder: "At least 8 characters",
                isConfirmField: false
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
                placeholder: "Re-enter password",
                isConfirmField: true
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
                .foregroundStyle(Color.red)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.red)
        }
        .padding(.top, 4)
        .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private func serverErrorRow(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.red)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.red)
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
                    Text("Create account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                viewModel.canSubmit
                    ? authManager.configuration.primaryColor
                    : authManager.configuration.primaryColor.opacity(0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSubmit)
    }

    private var loginLink: some View {
        HStack {
            Spacer()
            Button {} label: {
                Text("Already have an account? ")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondary)
                + Text("Log in")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(authManager.configuration.primaryColor)
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

    @State private var isVisible: Bool = false

    var body: some View {
        HStack {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.newPassword)
                        .submitLabel(isConfirmField ? .go : .next)
                        .textFieldStyle(.plain)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.newPassword)
                        .submitLabel(isConfirmField ? .go : .next)
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
        .background(RegisterColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Internal colour helpers

private enum RegisterColors {
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
