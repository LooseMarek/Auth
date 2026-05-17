import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Configuration for the AuthClient, passed once at setup time by the adopting app.
/// All properties are developer-facing — the end user never sees or changes them.
public struct AuthClientConfiguration: Sendable {

    /// When `false`, all guest / anonymous sign-in UI is hidden.
    public let allowGuestAccess: Bool

    /// Tint applied to buttons and interactive elements.
    /// Defaults to Auth Blue (#0A66FF light / #3D8BFF dark) per the Auth design system.
    public let primaryColor: Color

    /// Screen background color.
    /// Defaults to the platform system background, which adapts to light and dark mode.
    public let backgroundColor: Color

    /// Custom font applied to all auth screens. `nil` uses the system default.
    public let font: Font?

    /// - Parameters:
    ///   - primaryColor: Pass `nil` to use Auth Blue (adapts to light / dark).
    ///   - backgroundColor: Pass `nil` to use the system background (adapts to light / dark).
    public init(
        allowGuestAccess: Bool = true,
        primaryColor: Color? = nil,
        backgroundColor: Color? = nil,
        font: Font? = nil
    ) {
        self.allowGuestAccess = allowGuestAccess
        self.primaryColor = primaryColor ?? Self.adaptivePrimaryColor
        self.backgroundColor = backgroundColor ?? Self.adaptiveBackgroundColor
        self.font = font
    }

    // MARK: - Adaptive defaults (private — resolved inside the init body)

    /// Auth Blue: #0A66FF (light) / #3D8BFF (dark).
    #if canImport(UIKit)
    private static let adaptivePrimaryColor = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.545, blue: 1.0, alpha: 1.0)
            : UIColor(red: 0.039, green: 0.400, blue: 1.0, alpha: 1.0)
    })
    private static let adaptiveBackgroundColor = Color(uiColor: .systemBackground)
    #else
    private static let adaptivePrimaryColor = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.239, green: 0.545, blue: 1.0, alpha: 1.0)
            : NSColor(red: 0.039, green: 0.400, blue: 1.0, alpha: 1.0)
    })
    private static let adaptiveBackgroundColor = Color(nsColor: .windowBackgroundColor)
    #endif
}
