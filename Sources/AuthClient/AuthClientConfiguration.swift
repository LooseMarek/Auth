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
    ///
    /// When the `light`/`dark` initialiser is used, this property holds the adaptive
    /// default colour and is superseded by the scheme-specific tokens at theme resolution
    /// time — callers should not read this property directly; use `AuthTheme` instead.
    public let primaryColor: Color

    /// Screen background color.
    /// Defaults to the platform system background, which adapts to light and dark mode.
    ///
    /// When the `light`/`dark` initialiser is used, this property holds the adaptive
    /// default and is superseded by the scheme-specific tokens at theme resolution time.
    public let backgroundColor: Color

    /// Custom font applied to all auth screens. `nil` uses the system default.
    public let font: Font?

    /// Custom bundle used to resolve all localised strings in Auth screens.
    ///
    /// Pass a `Bundle` from your host app (e.g. `Bundle.main`) to supply custom or translated
    /// `Localizable.strings`. When `nil` (the default), the Auth module bundle is used.
    public let localizationBundle: Bundle?

    // MARK: - Flat color tokens (optional — nil = use AuthTheme adaptive defaults)
    //
    // These are the backward-compatible single-set token properties.
    // When `lightTokens` / `darkTokens` are supplied via the dual-scheme init,
    // `AuthTheme` uses those instead of these properties.

    /// Text field / input background colour.
    /// When `nil`, `AuthTheme` falls back to the `color.surface` token (#F5F5F7 light / #2C2C2E dark).
    public let surfaceColor: Color?

    /// Primary body text colour.
    /// When `nil`, `AuthTheme` falls back to SwiftUI's `Color.primary`.
    public let primaryTextColor: Color?

    /// Secondary / hint text colour.
    /// When `nil`, `AuthTheme` falls back to SwiftUI's `Color.secondary`.
    public let secondaryTextColor: Color?

    /// Label colour for the primary action button.
    /// When `nil`, `AuthTheme` falls back to `.white`.
    public let buttonTextColor: Color?

    /// Colour used for error messages and icons.
    /// When `nil`, `AuthTheme` falls back to `Color.red`.
    public let errorColor: Color?

    // MARK: - Per-scheme token sets

    /// Colour tokens to use in light mode.
    /// When non-nil, `AuthTheme` uses these in preference to the flat token properties
    /// when the colour scheme is `.light`.
    public let lightTokens: AuthColorTokens?

    /// Colour tokens to use in dark mode.
    /// When non-nil, `AuthTheme` uses these in preference to the flat token properties
    /// when the colour scheme is `.dark`.
    public let darkTokens: AuthColorTokens?

    // MARK: - Backward-compatible (flat-colour) initialiser

    /// Creates an `AuthClientConfiguration` with a single adaptive colour set.
    ///
    /// All colour parameters are adaptive — supply a `UIColor`/`NSColor` dynamic provider
    /// when you need different values for light and dark mode, or use the `init(light:dark:)`
    /// variant to provide completely separate token sets per scheme.
    ///
    /// - Parameters:
    ///   - allowGuestAccess: When `false`, guest / anonymous sign-in UI is hidden. Defaults to `true`.
    ///   - primaryColor: Pass `nil` to use Auth Blue (adapts to light / dark).
    ///   - backgroundColor: Pass `nil` to use the system background (adapts to light / dark).
    ///   - font: Custom font for all auth screens. Defaults to `nil` (system font).
    ///   - localizationBundle: Pass a bundle to override Auth's built-in localisation. Defaults to `nil` (uses Auth module bundle).
    ///   - surfaceColor: Pass `nil` to use the `color.surface` adaptive default (#F5F5F7 / #2C2C2E).
    ///   - primaryTextColor: Pass `nil` to use SwiftUI's `Color.primary`.
    ///   - secondaryTextColor: Pass `nil` to use SwiftUI's `Color.secondary`.
    ///   - buttonTextColor: Pass `nil` to use `.white`.
    ///   - errorColor: Pass `nil` to use `Color.red`.
    public init(
        allowGuestAccess: Bool = true,
        primaryColor: Color? = nil,
        backgroundColor: Color? = nil,
        font: Font? = nil,
        localizationBundle: Bundle? = nil,
        surfaceColor: Color? = nil,
        primaryTextColor: Color? = nil,
        secondaryTextColor: Color? = nil,
        buttonTextColor: Color? = nil,
        errorColor: Color? = nil
    ) {
        self.allowGuestAccess = allowGuestAccess
        self.primaryColor = primaryColor ?? Self.adaptivePrimaryColor
        self.backgroundColor = backgroundColor ?? Self.adaptiveBackgroundColor
        self.font = font
        self.localizationBundle = localizationBundle
        self.surfaceColor = surfaceColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.buttonTextColor = buttonTextColor
        self.errorColor = errorColor
        self.lightTokens = nil
        self.darkTokens = nil
    }

    // MARK: - Dual-scheme initialiser

    /// Creates an `AuthClientConfiguration` with separate colour token sets for light and dark mode.
    ///
    /// Use this initialiser when you need different brand colours in each colour scheme
    /// (e.g. a brighter primary in dark mode, or a different background palette altogether).
    /// `AuthTheme` selects the appropriate set based on `colorScheme` and falls back to
    /// adaptive defaults for any token left as `nil`.
    ///
    /// - Parameters:
    ///   - allowGuestAccess: When `false`, guest / anonymous sign-in UI is hidden. Defaults to `true`.
    ///   - light: Colour tokens applied when the colour scheme is `.light`.
    ///            Any `nil` property falls back to the Auth design-system default for that token.
    ///   - dark: Colour tokens applied when the colour scheme is `.dark`.
    ///           Any `nil` property falls back to the Auth design-system default for that token.
    ///   - font: Custom font for all auth screens. Defaults to `nil` (system font).
    ///   - localizationBundle: Pass a bundle to override Auth's built-in localisation. Defaults to `nil`.
    public init(
        allowGuestAccess: Bool = true,
        light: AuthColorTokens,
        dark: AuthColorTokens,
        font: Font? = nil,
        localizationBundle: Bundle? = nil
    ) {
        self.allowGuestAccess = allowGuestAccess
        // The flat colour properties are set to adaptive defaults; they are not used when
        // lightTokens / darkTokens are present — AuthTheme uses those directly.
        self.primaryColor = Self.adaptivePrimaryColor
        self.backgroundColor = Self.adaptiveBackgroundColor
        self.font = font
        self.localizationBundle = localizationBundle
        // Flat tokens are nil — AuthTheme will use lightTokens/darkTokens instead.
        self.surfaceColor = nil
        self.primaryTextColor = nil
        self.secondaryTextColor = nil
        self.buttonTextColor = nil
        self.errorColor = nil
        self.lightTokens = light
        self.darkTokens = dark
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
