import AuthShared
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The forgot-password screen of the Auth flow.
///
/// `ForgotPasswordView` is pushed onto the `AuthSheetContainer` navigation stack from
/// `LoginView`. It collects the user's email address and calls the injected
/// `AuthNetworkService.forgotPassword(email:)` endpoint to trigger a password-reset email.
///
/// On success, the view transitions to a confirmation card with an animated checkmark.
/// The transition respects `accessibilityReduceMotion` — a simple opacity fade is used
/// instead of the default spring-scale animation when reduce-motion is enabled.
public struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel
    private let authManager: AuthManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.authTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var bundle: Bundle { authManager.configuration.localizationBundle ?? .module }

    /// Creates a `ForgotPasswordView`.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager (used for theming).
    ///   - networkService: The network layer used for the forgot-password request.
    ///   - prefilledEmail: Optional email to pre-populate the email field (e.g. for Xcode Previews).
    ///   - initialIsLoading: When `true`, the submit button shows a loading indicator on appear.
    ///   - initialIsSuccess: When `true`, the success card is shown immediately on appear.
    ///   - initialErrorMessage: Optional error message to display immediately on appear.
    public init(
        authManager: AuthManager,
        networkService: any AuthNetworkService,
        prefilledEmail: String = "",
        initialIsLoading: Bool = false,
        initialIsSuccess: Bool = false,
        initialErrorMessage: String? = nil
    ) {
        self.authManager = authManager
        self._viewModel = State(wrappedValue: ForgotPasswordViewModel(
            networkService: networkService,
            localizationBundle: authManager.configuration.localizationBundle,
            initialEmail: prefilledEmail,
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
            // Apply custom base font when configured; child modifiers override as needed.
            .font(theme.font)
        }
        .background(theme.backgroundColor)
    }

    // MARK: - Form content

    private var formContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
            Spacer().frame(height: 24)
            emailFieldSection
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
            Text(String(localized: "auth.forgot.title", bundle: bundle))
                .font(.title.bold())
                .foregroundStyle(Color.primary)
            Text(String(localized: "auth.forgot.subtitle", bundle: bundle))
                .font(.callout)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: 340, alignment: .leading)
        }
        .padding(.top, 24)
    }

    private var emailFieldSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField(String(localized: "auth.forgot.field.email.placeholder", bundle: bundle), text: $viewModel.email)
#if canImport(UIKit)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
#endif
                .textContentType(.emailAddress)
                .submitLabel(.go)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(ForgotPasswordColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit {
                    Task { await viewModel.submit() }
                }

            if let message = viewModel.errorMessage {
                errorRow(message: message)
            }
        }
    }

    @ViewBuilder
    private func errorRow(message: String) -> some View {
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

    private var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .colorScheme(.dark)
                } else {
                    Text(String(localized: "auth.forgot.button.submit", bundle: bundle))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
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
            Button(String(localized: "auth.forgot.link.back", bundle: bundle)) {}
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
            // Hero icon: 64pt soft-circle containing 48pt checkmark
            ZStack {
                Circle()
                    .fill(ForgotPasswordColors.successSoft)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ForgotPasswordColors.success)
                    .accessibilityHidden(true)
            }

            Spacer().frame(height: 12)

            Text(String(localized: "auth.forgot.success.title", bundle: bundle))
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 4)

            Text(String(localized: "auth.forgot.success.body", bundle: bundle))
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(ForgotPasswordColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(ForgotPasswordColors.separator, lineWidth: 1)
        )
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color(red: 0.043, green: 0.051, blue: 0.071, opacity: 0.06), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private var backToLoginButton: some View {
        Button {} label: {
            Text(String(localized: "auth.forgot.link.back", bundle: bundle))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(theme.primaryColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Internal colour helpers

private enum ForgotPasswordColors {
    /// Field fill — `color.surface` token: #F5F5F7 light / #2C2C2E dark.
    #if canImport(UIKit)
    static let surface = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
    })
    /// Card background — `color.surface.elevated`: #FFFFFF light / #3A3A3C dark.
    static let surfaceElevated = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.227, green: 0.227, blue: 0.235, alpha: 1)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    })
    /// `color.success`: #2BA471 light / #3DD68C dark.
    static let success = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 1)
            : UIColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 1)
    })
    /// `color.success.soft`: #2BA471 @10% light / #3DD68C @14% dark.
    static let successSoft = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.839, blue: 0.549, alpha: 0.14)
            : UIColor(red: 0.169, green: 0.643, blue: 0.443, alpha: 0.1)
    })
    /// `color.separator`: rgba(11,13,18,0.08) light / rgba(255,255,255,0.08) dark.
    static let separator = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
            : UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 0.08)
    })
    #else
    static let surface = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
    })
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

private struct PreviewForgotPasswordNetworkService: AuthNetworkService {
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

    func upgradeGuestWithApple(guestUUID: UUID, identityToken: String, displayName: String?) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func signInWithGoogle(identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithGoogle(guestUUID: UUID, identityToken: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func loginAsGuest() async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }

    func upgradeGuestWithEmail(guestUUID: UUID, email: String, password: String) async throws -> AuthResponse {
        throw AuthNetworkError.serverError
    }
}

private extension AuthManager {
    static var previewForgotPassword: AuthManager {
        AuthManager(configuration: AuthClientConfiguration())
    }
}

#Preview("Default — empty") {
    ForgotPasswordView(
        authManager: .previewForgotPassword,
        networkService: PreviewForgotPasswordNetworkService()
    )
}

#Preview("Email entered") {
    ForgotPasswordView(
        authManager: .previewForgotPassword,
        networkService: PreviewForgotPasswordNetworkService(),
        prefilledEmail: "user@example.com"
    )
}

#Preview("Loading") {
    ForgotPasswordView(
        authManager: .previewForgotPassword,
        networkService: PreviewForgotPasswordNetworkService(),
        prefilledEmail: "user@example.com",
        initialIsLoading: true
    )
}

#Preview("Error") {
    ForgotPasswordView(
        authManager: .previewForgotPassword,
        networkService: PreviewForgotPasswordNetworkService(),
        prefilledEmail: "user@example.com",
        initialErrorMessage: "No internet connection. Please try again."
    )
}

#Preview("Success") {
    ForgotPasswordView(
        authManager: .previewForgotPassword,
        networkService: PreviewForgotPasswordNetworkService(),
        initialIsSuccess: true
    )
}

#endif
