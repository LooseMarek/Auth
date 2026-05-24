import SwiftUI

/// A SwiftUI `ViewModifier` that attaches auth flow presentation to any view.
///
/// Attach it once on the host app's root view:
/// ```swift
/// ContentView()
///     .authSheet(manager: authManager)
/// ```
///
/// The modifier observes `AuthManager.isPresentingAuthFlow` and
/// `AuthManager.authPresentationStyle`. When `isPresentingAuthFlow` becomes `true`:
/// - `.fullScreen` style → iOS uses `.fullScreenCover` (non-dismissible); macOS uses
///   `.sheet` with `.interactiveDismissDisabled(true)`.
/// - `.sheet` style → iOS uses `.sheet` with `.large` detent and drag indicator;
///   macOS uses the standard `.sheet` panel.
///
/// When the user dismisses the sheet (only possible in `.sheet` style), or when
/// authentication completes, `dismissAuthFlow()` is called to reset state.
///
/// ## macOS scrim
/// SwiftUI does not render a scrim behind `.sheet` panels on macOS. A manual
/// `color.scrim` overlay is applied behind the panel using a `ZStack` on the host
/// content. The scrim fades in when `isPresentingAuthFlow` is `true` and fades out
/// on dismiss.
struct AuthSheetModifier: ViewModifier {

    @Bindable var authManager: AuthManager

    // Both bindings are always in the view tree on iOS, so switching styles
    // never changes the view structure. SwiftUI can reliably detect the
    // false→true transition on whichever binding becomes active.
    private var fullScreenBinding: Binding<Bool> {
        Binding(
            get: { authManager.isPresentingAuthFlow && authManager.authPresentationStyle == .fullScreen },
            set: { presenting in if !presenting { authManager.dismissAuthFlow() } }
        )
    }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { authManager.isPresentingAuthFlow && authManager.authPresentationStyle == .sheet },
            set: { presenting in if !presenting { authManager.dismissAuthFlow() } }
        )
    }

    // macOS only: single binding for the sheet; style controls interactiveDismissDisabled.
    private var macOSPresentingBinding: Binding<Bool> {
        Binding(
            get: { authManager.isPresentingAuthFlow },
            set: { presenting in if !presenting { authManager.dismissAuthFlow() } }
        )
    }

    func body(content: Content) -> some View {
#if canImport(AppKit)
        ZStack {
            content
            if authManager.isPresentingAuthFlow {
                AuthSheetColors.scrim
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: macOSPresentingBinding) {
            AuthSheetContainer(authManager: authManager)
                .interactiveDismissDisabled(authManager.authPresentationStyle == .fullScreen)
        }
#else
        content
            .fullScreenCover(isPresented: fullScreenBinding) {
                AuthSheetContainer(authManager: authManager)
            }
            .sheet(isPresented: sheetBinding) {
                AuthSheetContainer(authManager: authManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
#endif
    }
}

// MARK: - Adaptive colour helpers

private enum AuthSheetColors {
    /// `color.scrim` token — `rgba(0,0,0,0.32)` light / `rgba(0,0,0,0.56)` dark.
    /// Applied manually on macOS because the system does not render a scrim behind `.sheet` panels.
#if canImport(UIKit)
    static let scrim = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.56)
            : UIColor(white: 0, alpha: 0.32)
    })
#else
    static let scrim = Color(nsColor: NSColor(name: nil) { a in
        a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 0, alpha: 0.56)
            : NSColor(white: 0, alpha: 0.32)
    })
#endif
}

// MARK: - View extension

public extension View {
    /// Attaches the auth sheet to this view, driven by the given `AuthManager`.
    ///
    /// Call this once on your app's root view. From then on, calling
    /// `authManager.presentAuthFlow()` from any screen will trigger the auth UI.
    ///
    /// - Parameter manager: The `AuthManager` instance that controls presentation state.
    func authSheet(manager: AuthManager) -> some View {
        modifier(AuthSheetModifier(authManager: manager))
    }
}
