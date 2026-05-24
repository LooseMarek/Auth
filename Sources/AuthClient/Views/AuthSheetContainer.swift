import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// The SwiftUI container that wraps all auth screens and owns the internal `NavigationStack`.
///
/// Host apps never instantiate this directly — it is presented automatically by the
/// `.authSheet(manager:)` view modifier when `AuthManager.isPresentingAuthFlow` becomes `true`.
///
/// ## Layout
/// ```
/// AuthSheetContainer
///   └── NavigationStack (internal)
///         └── LoginView (root screen)
///               ↳ (push) RegisterView
///               ↳ (push) ForgotPasswordView
/// ```
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

    public init(authManager: AuthManager) {
        self.authManager = authManager
    }

    public var body: some View {
        let theme = AuthTheme(configuration: authManager.configuration, colorScheme: colorScheme)
        NavigationStack {
            LoginView(
                authManager: authManager,
                networkService: authManager.networkService
            )
#if canImport(AppKit)
            .frame(width: 440)
            .frame(minHeight: 540)
#endif
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
