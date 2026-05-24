/// Controls how the auth flow is presented to the user.
///
/// Pass this value to `AuthManager.presentAuthFlow(style:)` to choose between:
/// - `.fullScreen` — non-dismissible full-screen presentation, used when the app
///   gates content behind authentication (e.g. on first launch when the session is
///   `.unauthenticated`).  On iOS this renders as `.fullScreenCover`; on macOS it
///   renders as an `interactiveDismissDisabled` sheet.
/// - `.sheet` — standard system sheet, user-dismissible.  Used for contextual flows
///   such as upgrading a guest session from the Profile page.
public enum AuthPresentationStyle: Equatable, Sendable {
    /// Non-dismissible presentation — covers the full screen.
    case fullScreen
    /// Standard dismissible sheet presentation.
    case sheet
}
