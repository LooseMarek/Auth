import SwiftUI

/// A SwiftUI `ViewModifier` that attaches auth sheet presentation to any view.
///
/// Attach it once on the host app's root view:
/// ```swift
/// ContentView()
///     .authSheet(manager: authManager)
/// ```
///
/// The modifier observes `AuthManager.isPresentingAuthFlow`. When it becomes `true`,
/// the `AuthSheetContainer` is presented as a system sheet. When the user dismisses
/// the sheet (drag gesture on iOS, Cmd-W or close button on macOS), `dismissAuthFlow()`
/// is called so `isPresentingAuthFlow` is reset to `false`.
///
/// ## Platform behaviour
/// - **iOS:** `.presentationDetents([.large])` — medium was removed because the auth
///   fields do not fit a medium-height sheet. Drag indicator is always visible.
/// - **macOS:** SwiftUI renders `.sheet` as a floating panel. A manual `color.scrim`
///   overlay is applied behind the panel using a `ZStack` on the host content.
///   The scrim fades in when `isPresentingAuthFlow` is `true` and fades out on dismiss.
struct AuthSheetModifier: ViewModifier {

    @Bindable var authManager: AuthManager

    func body(content: Content) -> some View {
#if canImport(AppKit)
        ZStack {
            content
            if authManager.isPresentingAuthFlow {
                AuthSheetColors.scrim
                    .ignoresSafeArea()
            }
        }
        .sheet(
            isPresented: Binding(
                get: { authManager.isPresentingAuthFlow },
                set: { presenting in
                    if !presenting {
                        authManager.dismissAuthFlow()
                    }
                }
            )
        ) {
            AuthSheetContainer(authManager: authManager)
        }
#else
        content
            .sheet(
                isPresented: Binding(
                    get: { authManager.isPresentingAuthFlow },
                    set: { presenting in
                        if !presenting {
                            authManager.dismissAuthFlow()
                        }
                    }
                )
            ) {
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
