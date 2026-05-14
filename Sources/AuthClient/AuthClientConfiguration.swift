import SwiftUI

/// Configuration for the AuthClient, passed once at setup time by the adopting app.
/// All properties are developer-facing — the end user never sees or changes them.
public struct AuthClientConfiguration: Sendable {

    /// When `false`, all guest / anonymous sign-in UI is hidden.
    public let allowGuestAccess: Bool

    /// Tint applied to buttons and interactive elements. Defaults to the system accent color.
    public let primaryColor: Color

    /// Screen background color. Defaults to the system background color.
    public let backgroundColor: Color

    /// Custom font applied to all auth screens. `nil` uses the system default.
    public let font: Font?

    public init(
        allowGuestAccess: Bool = true,
        primaryColor: Color = .accentColor,
        backgroundColor: Color = .white,
        font: Font? = nil
    ) {
        self.allowGuestAccess = allowGuestAccess
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.font = font
    }
}
