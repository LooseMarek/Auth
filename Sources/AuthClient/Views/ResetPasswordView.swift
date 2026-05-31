import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The reset-password screen of the Auth flow.
///
/// `ResetPasswordView` is pushed onto the `AuthSheetContainer` navigation stack from
/// the `ForgotPasswordView` success state. It collects the one-time reset token delivered
/// by email, a new password, and a confirm-password field, then calls the injected
/// `AuthNetworkService.resetPassword(token:newPassword:)` endpoint to complete the reset.
///
/// On success, the view transitions to a confirmation card that prompts the user to log in.
public struct ResetPasswordView: View {
    @State private var viewModel: ResetPasswordViewModel
    private let authManager: AuthManager
    /// Closure provided by `AuthSheetContainer` (via `ForgotPasswordView`) to pop the
    /// entire forgot-password flow back to `LoginView`. See the `init` documentation for details.
    private let popToRoot: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.authTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var bundle: Bundle { authManager.configuration.localizationBundle ?? .module }

    /// Creates a `ResetPasswordView`.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager (used for theming).
    ///   - networkService: The network layer used for the reset-password request.
    ///   - popToRoot: Optional closure that resets the `NavigationStack` path to empty,
    ///     returning the user directly to `LoginView`. Provided by `AuthSheetContainer`
    ///     (via `ForgotPasswordView`'s success state); tapping "Back to log in" fires
    ///     this closure so both `ResetPasswordView` and `ForgotPasswordView` are popped
    ///     at once. Pass `nil` (default) when presenting `ResetPasswordView` standalone
    ///     (e.g. Xcode Previews) — falls back to the local `dismiss()`.
    ///   - prefilledToken: Optional token to pre-populate the token field (e.g. for Xcode Previews).
    ///   - initialIsLoading: When `true`, the submit button shows a loading indicator on appear.
    ///   - initialIsSuccess: When `true`, the success card is shown immediately on appear.
    ///   - initialErrorMessage: Optional error message to display immediately on appear.
    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        popToRoot: (() -> Void)? = nil,
        prefilledToken: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.authManager = authManager
        self.popToRoot = popToRoot
        self._viewModel = State(wrappedValue: ResetPasswordViewModel(
            networkService: networkService,
            localizationBundle: authManager.configuration.localizationBundle,
            initialToken: prefilledToken,
            initialIsLoading: initialIsLoading,
            initialIsSuccess: initialIsSuccess,
            initialErrorMessage: initialErrorMessage
        ))
    }

    public var body: some View {
        content
            .environment(
                \.authTheme,
                AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
            )
            .onAppear {
                // If popToRoot is provided (set by AuthSheetContainer when pushing
                // this view via navigationDestination), use it so tapping "Back to log in"
                // pops both ResetPasswordView and ForgotPasswordView, returning to LoginView.
                // Otherwise fall back to the local dismiss (standalone / preview use).
                if let popToRoot {
                    viewModel.onBackToSignIn = popToRoot
                } else {
                    viewModel.onBackToSignIn = { dismiss() }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            ZStack {
                if !viewModel.isSuccess {
                    formContent
                        .opacity(viewModel.isSuccess ? 0 : 1)
                        .transition(.opacity)
                } else {
                    successContent
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .scale(scale: 0.96))
                        )
                }
            }
            .animation(
                reduceMotion
                    ? .easeInOut(duration: 0.18)
                    : .spring(response: 0.32, dampingFraction: 0.7),
                value: viewModel.isSuccess
            )
            .padding(.horizontal, 24)
            .font(theme.font)
        }
        .background(theme.backgroundColor)
    }

    // MARK: - Form content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
            Spacer().frame(height: 24)
            tokenFieldSection
            Spacer().frame(height: 14)
            newPasswordFieldSection
            Spacer().frame(height: 14)
            confirmPasswordFieldSection
            Spacer().frame(height: 24)
            submitButton
            Spacer().frame(height: 32)
            backLink
            Spacer().frame(height: 32)
        }
        .allowsHitTesting(!viewModel.isLoading)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "auth.reset.title", bundle: bundle))
                .font(.title.bold())
                .foregroundStyle(theme.primaryTextColor)
            Text(String(localized: "auth.reset.subtitle", bundle: bundle))
                .font(.callout)
                .foregroundStyle(theme.secondaryTextColor)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var tokenFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(String(localized: "auth.reset.field.token.placeholder", bundle: bundle), text: $viewModel.token)
#if canImport(UIKit)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
#endif
                .textContentType(.oneTimeCode)
                .submitLabel(.next)
                .foregroundStyle(theme.primaryTextColor)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(theme.surfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if let message = viewModel.errorMessage {
                errorRow(message: message)
            }
        }
    }

    private var newPasswordFieldSection: some View {
        SecureField(String(localized: "auth.reset.field.new_password.placeholder", bundle: bundle), text: $viewModel.newPassword)
            .textContentType(.newPassword)
            .submitLabel(.next)
            .foregroundStyle(theme.primaryTextColor)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(theme.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var confirmPasswordFieldSection: some View {
        SecureField(String(localized: "auth.reset.field.confirm_password.placeholder", bundle: bundle), text: $viewModel.confirmPassword)
            .textContentType(.newPassword)
            .submitLabel(.go)
            .foregroundStyle(theme.primaryTextColor)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(theme.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onSubmit {
                Task { await viewModel.submit() }
            }
    }

    @ViewBuilder
    private func errorRow(message: String) -> some View {
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

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .colorScheme(.dark)
                } else {
                    Text(String(localized: "auth.reset.button.submit", bundle: bundle))
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

    private var backLink: some View {
        HStack {
            Spacer()
            Button(String(localized: "auth.reset.link.back", bundle: bundle)) {
                viewModel.backToSignIn()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.primaryColor)
            .buttonStyle(.plain)
            Spacer()
        }
    }

    // MARK: - Success content

    private var successContent: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)
            successCard
            Spacer().frame(height: 24)
            backToLoginButton
            Spacer().frame(height: 32)
        }
    }

    private var successCard: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(ResetPasswordColors.successSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ResetPasswordColors.success)
                    .accessibilityHidden(true)
            }

            Spacer().frame(height: 12)

            Text(String(localized: "auth.reset.success.title", bundle: bundle))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            Text(String(localized: "auth.reset.success.body", bundle: bundle))
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(ResetPasswordColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(ResetPasswordColors.separator, lineWidth: 1)
        )
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.06), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private var backToLoginButton: some View {
        Button {
            viewModel.backToSignIn()
        } label: {
            Text(String(localized: "auth.reset.link.back", bundle: bundle))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.buttonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Internal colour helpers

/// Design-system constants for the success card in `ResetPasswordView`.
///
/// Mirrors the same semantic colour tokens used in `ForgotPasswordView`.
private enum ResetPasswordColors {
    #if canImport(UIKit)
    static let surfaceElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.227, green: 0.227, blue: 0.235, alpha: 1)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    })
    static let success = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 1)
            : UIColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 1)
    })
    static let successSoft = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 0.14)
            : UIColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 0.1)
    })
    static let separator = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
            : UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 0.08)
    })
    #else
    static let surfaceElevated = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.227, green: 0.227, blue: 0.235, alpha: 1)
            : NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    })
    static let success = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 1)
            : NSColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 1)
    })
    static let successSoft = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 0.14)
            : NSColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 0.1)
    })
    static let separator = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
            : NSColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 0.08)
    })
    #endif
}

// MARK: - Previews

#if DEBUG

private struct PreviewResetPasswordNetworkService: AuthNetworkService {
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
    static var previewResetPassword: AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}

#Preview("Default — empty") {
    ResetPasswordView(
        authManager: .previewResetPassword,
        networkService: PreviewResetPasswordNetworkService()
    )
}

#Preview("Token entered") {
    ResetPasswordView(
        authManager: .previewResetPassword,
        networkService: PreviewResetPasswordNetworkService(),
        prefilledToken: "1D92B930-6D05-4C4A-960C-6DAB9A6C152A"
    )
}

#Preview("Loading") {
    ResetPasswordView(
        authManager: .previewResetPassword,
        networkService: PreviewResetPasswordNetworkService(),
        prefilledToken: "1D92B930-6D05-4C4A-960C-6DAB9A6C152A",
        initialIsLoading: true
    )
}

#Preview("Error — invalid token") {
    ResetPasswordView(
        authManager: .previewResetPassword,
        networkService: PreviewResetPasswordNetworkService(),
        prefilledToken: "expired-token",
        initialErrorMessage: "Invalid or expired reset token. Please request a new one."
    )
}

#Preview("Success") {
    ResetPasswordView(
        authManager: .previewResetPassword,
        networkService: PreviewResetPasswordNetworkService(),
        initialIsSuccess: true
    )
}

#endif
