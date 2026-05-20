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
struct AuthSheetModifier: ViewModifier {

    @Bindable var authManager: AuthManager

    func body(content: Content) -> some View {
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
#if canImport(UIKit)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
#endif
            }
    }
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
