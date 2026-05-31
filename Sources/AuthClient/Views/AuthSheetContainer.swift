import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// MARK: - Navigation destination enum

/// Navigation destinations for the login flow within `AuthSheetContainer`.
///
/// `AuthSheetContainer` owns a `[LoginFlowDestination]` path bound to its `NavigationStack`.
/// Screens push onto the path by calling their `navigateTo` closure; `popToRoot` clears the
/// path entirely, snapping back to `LoginView` without dismissing the sheet.
public enum LoginFlowDestination: Hashable {
    /// Push `ForgotPasswordView`, pre-populating the email field with `prefilledEmail`.
    case forgotPassword(prefilledEmail: String)
    /// Push `ResetPasswordView` from `ForgotPasswordView`'s success state.
    case resetPassword
    /// Push `RegisterView` from `LoginView`'s "Create account" link.
    case register
    /// Push `ChangePasswordView` from the host app (email-auth users only).
    case changePassword
}

// MARK: - Container

/// The SwiftUI container that wraps all auth screens and owns the internal `NavigationStack`.
///
/// Host apps never instantiate this directly — it is presented automatically by the
/// `.authSheet(manager:)` view modifier when `AuthManager.isPresentingAuthFlow` becomes `true`.
///
/// ## Layout
/// ```
/// AuthSheetContainer
///   └── NavigationStack (value-based, [LoginFlowDestination] path)
///         └── LoginView (root screen)
///               ↳ (.forgotPassword) ForgotPasswordView
///                     ↳ (.resetPassword) ResetPasswordView
///               ↳ (.register) RegisterView
/// ```
///
/// ## Navigation — value-based throughout
/// All navigation in the login flow uses value-based `NavigationLink` / `navigationDestination`.
/// - `LoginView` receives a `navigateTo` closure that appends a `LoginFlowDestination` to `navPath`.
/// - `ForgotPasswordView` receives both `navigateTo` (to push `ResetPasswordView`) and
///   `popToRoot` (to reset the path and return to `LoginView`).
/// - `ResetPasswordView` receives `popToRoot` only — its "Back to sign in" button calls it.
/// - `navPath.removeAll()` is a plain state mutation; it cannot dismiss the sheet.
///
/// This approach fixes two bugs that the earlier destination-based wiring had:
/// 1. **ForgotPasswordView cached state** — destination-based links reuse the same view
///    instance; value-based navigation always creates a fresh instance on push.
/// 2. **ResetPasswordView dismiss-to-root** — calling `navPath.removeAll()` resets the path
///    and returns to `LoginView`; it does NOT dismiss the enclosing sheet.
///
/// ## Platform behaviour
/// - **iOS:** System `.sheet` at `.large` detent; drag indicator visible. Horizontal/top
///   padding (`space.lg` = 24pt) and bottom padding (`space.xl` = 32pt + safe area) are
///   applied inside each screen's own `VStack`, not at this layer.
/// - **macOS:** SwiftUI `.sheet` renders as a floating panel. The container constrains
///   itself to 440pt wide and at least 540pt tall, applies `shadow.sheet`, a 14pt corner
///   radius, and an explicit 1pt separator-coloured border. A manual `color.scrim` overlay
///   is applied to the host content by `AuthSheetModifier`.
public struct AuthSheetContainer: View {

    private let authManager: AuthManager

    @Environment(\.colorScheme) private var colorScheme
    @State private var navPath: [LoginFlowDestination] = []

    public init(authManager: AuthManager) {
        self.authManager = authManager
    }

    public var body: some View {
        let theme = AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
        NavigationStack(path: $navPath) {
            LoginView(
                authManager: authManager,
                networkService: authManager.networkService,
                navigateTo: { navPath.append($0) }
            )
#if canImport(AppKit)
            .frame(width: 440)
            .frame(minHeight: 540)
#endif
            .navigationDestination(for: LoginFlowDestination.self) { dest in
                switch dest {
                case .forgotPassword(let email):
                    ForgotPasswordView(
                        authManager: authManager,
                        networkService: authManager.networkService,
                        navigateTo: { navPath.append($0) },
                        popToRoot: { navPath.removeAll() },
                        prefilledEmail: email
                    )
                case .resetPassword:
                    ResetPasswordView(
                        authManager: authManager,
                        networkService: authManager.networkService,
                        popToRoot: { navPath.removeAll() }
                    )
                case .register:
                    RegisterView(
                        authManager: authManager,
                        networkService: authManager.networkService
                    )
                case .changePassword:
                    ChangePasswordView(
                        authManager: authManager,
                        networkService: authManager.networkService,
                        popToRoot: { navPath.removeAll() }
                    )
                }
            }
        }
        .environment(\.authTheme, theme)
#if !canImport(AppKit)
        .background(theme.backgroundColor.ignoresSafeArea())
#else
        .frame(width: 440)
        .frame(minHeight: 540)
        .background(theme.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(AuthSheetColors.separator, lineWidth: 1)
        )
        .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: 0.18),
            radius: 32,
            x: 0,
            y: 24
        )
        .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: 0.04),
            radius: 0,
            x: 0,
            y: 1
        )
#endif
    }
}

// MARK: - Adaptive colour helpers

private enum AuthSheetColors {
    /// `color.separator` token — hairline border for the macOS floating panel.
    /// `rgba(11,13,18,0.08)` light / `rgba(255,255,255,0.08)` dark.
    #if canImport(UIKit)
    static let separator = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.08)
            : UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 0.08)
    })
    #else
    static let separator = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1.0, alpha: 0.08)
            : NSColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 0.08)
    })
    #endif
}
