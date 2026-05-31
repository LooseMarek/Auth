import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The change-password screen of the Auth flow.
///
/// `ChangePasswordView` allows email-auth users to change their password from within
/// the app. It is pushed onto the `AuthSheetContainer` navigation stack via the
/// `.changePassword` destination.
///
/// On success, the view transitions to a confirmation card. The transition respects
/// `accessibilityReduceMotion` — a simple opacity fade is used instead of the
/// default spring-scale animation when reduce-motion is enabled.
///
/// This view is hidden in the navigation flow for Apple, Google, and Guest users —
/// only email-authenticated users should see the "Change Password" button in the host app.
public struct ChangePasswordView: View {
    @State private var viewModel: ChangePasswordViewModel
    private let authManager: AuthManager
    /// Closure from `AuthSheetContainer` that resets the `NavigationStack` path,
    /// returning to `LoginView`. When `nil` (standalone preview), falls back to `dismiss()`.
    private let popToRoot: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.authTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    private var bundle: Bundle { authManager.configuration.localizationBundle ?? .module }

    /// Creates a `ChangePasswordView`.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager (used for token + theming).
    ///   - networkService: The network layer used for the change-password request.
    ///   - popToRoot: Optional closure that resets the `NavigationStack` path to `LoginView`.
    ///     Provided by `AuthSheetContainer`. Pass `nil` (default) for standalone previews
    ///     — falls back to `dismiss()`.
    ///   - initialIsSuccess: When `true`, the success card is shown immediately on appear.
    ///   - initialErrorMessage: Optional inline error message to display immediately on appear.
    ///   - initialToastErrorMessage: Optional toast error message to display immediately on appear
    ///     (shown as a dismissable banner at the bottom — use for server/network errors).
    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        popToRoot: (() -> Void)? = nil,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil,
        initialToastErrorMessage: String? = nil
    ) {
        self.authManager = authManager
        self.popToRoot = popToRoot
        self._viewModel = State(wrappedValue: ChangePasswordViewModel(
            networkService: networkService,
            authManager: authManager,
            initialIsSuccess: initialIsSuccess,
            initialErrorMessage: initialErrorMessage,
            initialToastErrorMessage: initialToastErrorMessage
        ))
    }

    public var body: some View {
        content
            .environment(
                \.authTheme,
                AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
            )
            .onAppear {
                viewModel.onBackToSignIn = popToRoot ?? { dismiss() }
            }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
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

            // Toast overlay for server/network errors — pinned to the bottom.
            // Tapping it dismisses the error.
            if viewModel.toastErrorMessage != nil {
                toastOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.backgroundColor.ignoresSafeArea())
    }

    // MARK: - Form content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
            Spacer().frame(height: 24)
            currentPasswordField
            Spacer().frame(height: 12)
            newPasswordField
            Spacer().frame(height: 12)
            confirmPasswordField
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
            Text(String(localized: "auth.change_password.title", bundle: bundle))
                .font(.title.bold())
                .foregroundStyle(theme.primaryTextColor)
        }
        .padding(.top, 24)
    }

    private var currentPasswordField: some View {
        SecureField(
            String(localized: "auth.change_password.field.current_password", bundle: bundle),
            text: $viewModel.currentPassword
        )
        .textFieldStyle(.plain)
        .textContentType(.password)
        .foregroundStyle(theme.primaryTextColor)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(theme.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var newPasswordField: some View {
        SecureField(
            String(localized: "auth.change_password.field.new_password", bundle: bundle),
            text: $viewModel.newPassword
        )
        .textFieldStyle(.plain)
        .textContentType(.newPassword)
        .foregroundStyle(theme.primaryTextColor)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(theme.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var confirmPasswordField: some View {
        SecureField(
            String(localized: "auth.change_password.field.confirm_password", bundle: bundle),
            text: $viewModel.confirmPassword
        )
        .textFieldStyle(.plain)
        .textContentType(.newPassword)
        .foregroundStyle(theme.primaryTextColor)
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
                    Text(String(localized: "auth.change_password.button.submit", bundle: bundle))
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
            Button(String(localized: "auth.forgot.link.back", bundle: bundle)) {
                viewModel.backToSignIn()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.primaryColor)
            .buttonStyle(.plain)
            Spacer()
        }
    }

    /// Toast banner shown at the bottom of the screen for server and network errors.
    ///
    /// Displays a dismissible banner for all errors thrown by ``submit()``.
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
            // Hero icon: 64pt soft-circle containing 48pt checkmark
            ZStack {
                Circle()
                    .fill(ChangePasswordColors.successSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ChangePasswordColors.success)
                    .accessibilityHidden(true)
            }

            Spacer().frame(height: 12)

            Text(String(localized: "auth.change_password.success.title", bundle: bundle))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(theme.primaryTextColor)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            Text(String(localized: "auth.change_password.success.subtitle", bundle: bundle))
                .font(.body)
                .foregroundStyle(theme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(ChangePasswordColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(ChangePasswordColors.separator, lineWidth: 1)
        )
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.06), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private var backToLoginButton: some View {
        HStack {
            Spacer()
            Button(String(localized: "auth.forgot.link.back", bundle: bundle)) {
                viewModel.backToSignIn()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(theme.primaryColor)
            .buttonStyle(.plain)
            Spacer()
        }
    }
}

// MARK: - Internal colour helpers

/// Design-system constants for `ChangePasswordView`.
///
/// These tokens are fixed semantic colours (success, separator, elevated surface).
private enum ChangePasswordColors {
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

private struct PreviewChangePasswordNetworkService: AuthNetworkService {
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
    static var previewChangePassword: AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}

#Preview("Default — empty form") {
    ChangePasswordView(
        authManager: .previewChangePassword,
        networkService: PreviewChangePasswordNetworkService()
    )
}

#Preview("Success") {
    ChangePasswordView(
        authManager: .previewChangePassword,
        networkService: PreviewChangePasswordNetworkService(),
        initialIsSuccess: true
    )
}

#Preview("Error") {
    ChangePasswordView(
        authManager: .previewChangePassword,
        networkService: PreviewChangePasswordNetworkService(),
        initialToastErrorMessage: "Incorrect current password."
    )
}

#endif
