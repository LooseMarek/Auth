import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// MARK: - AuthTheme

/// Internal design-token bridge. Populated once from `AuthClientConfiguration` and injected
/// into the view hierarchy via the SwiftUI environment. Views must never read
/// `AuthClientConfiguration` directly — they always consume tokens from `AuthTheme`.
///
/// `AuthTheme` is **internal** and must never be exposed in the public API.
struct AuthTheme {

    // MARK: - Primary colour tokens

    /// The resolved primary colour for the current colour scheme.
    let primaryColor: Color

    /// Mouse-hover state: brightness ΔL = −10% (light) / +5% (dark).
    let primaryHover: Color

    /// Active touch / mouse-down state: brightness ΔL = −20% (light) / +10% (dark).
    let primaryPressed: Color

    /// Disabled primary button tint: primaryColor at 40% opacity.
    let primaryDisabled: Color

    /// Focus halos, soft selections: primaryColor at 10% opacity (light) / 14% (dark).
    let primarySoft: Color

    // MARK: - Vendor-immutable social button tokens

    /// Apple Sign-In background — fixed constant per Apple HIG, never themed.
    let appleButtonBackground: Color

    /// Apple Sign-In label colour — fixed constant per Apple HIG, never themed.
    let appleButtonLabel: Color

    // MARK: - Google button style

    /// Resolved style parameters for the "Sign in with Google" button.
    let googleButtonStyle: GoogleButtonStyle

    // MARK: - Background colour token

    /// Screen / sheet background colour — `color.bg` token, passed through from configuration.
    let backgroundColor: Color

    // MARK: - Surface & text colour tokens

    /// Text field / input background colour — `color.surface` token.
    /// Resolved from `AuthClientConfiguration.surfaceColor` when provided;
    /// falls back to #F5F5F7 (light) / #2C2C2E (dark).
    let surfaceColor: Color

    /// Primary body text colour. Resolved from configuration or falls back to `Color.primary`.
    let primaryTextColor: Color

    /// Secondary / hint text colour. Resolved from configuration or falls back to `Color.secondary`.
    let secondaryTextColor: Color

    /// Primary action button label colour. Resolved from configuration or falls back to `.white`.
    let buttonTextColor: Color

    /// Error message and icon colour. Resolved from configuration or falls back to `Color.red`.
    let errorColor: Color

    // MARK: - Typography

    /// Custom base font from `AuthClientConfiguration.font`; `nil` → SF Pro (system default).
    let font: Font?

    // MARK: - Initialisers

    /// Creates a fully resolved `AuthTheme` from a configuration and an explicit colour scheme.
    ///
    /// Passing `colorScheme` explicitly (rather than reading it from the environment inside the
    /// init) makes the derivation logic fully unit-testable without needing a live SwiftUI view.
    ///
    /// When `configuration` was built with the dual-scheme `init(light:dark:)`, the matching
    /// `AuthColorTokens` set is resolved first; any token that is `nil` in that set falls back
    /// to the same adaptive defaults used by the flat-colour init path.
    init(configuration: AuthClientConfiguration, colorScheme: ColorScheme) {
        let isDark = colorScheme == .dark

        // Resolve per-scheme token set, if present.
        let tokens: AuthColorTokens? = isDark ? configuration.darkTokens : configuration.lightTokens

        // MARK: Primary colour

        // Prefer the scheme-specific primary token; fall back to the configuration's adaptive
        // primaryColor (which itself already encodes light/dark via UIColor/NSColor dynamic provider).
        let rawPrimary: Color
        if let tokenPrimary = tokens?.primaryColor {
            rawPrimary = tokenPrimary
        } else {
            rawPrimary = configuration.primaryColor
        }
        let primary = AuthTheme.resolvedPrimary(from: rawPrimary, isDark: isDark)
        self.primaryColor = primary

        // Derive interaction states from the resolved primary colour.
        self.primaryHover    = AuthTheme.adjustBrightness(of: primary, delta: isDark ? +0.05 : -0.10)
        self.primaryPressed  = AuthTheme.adjustBrightness(of: primary, delta: isDark ? +0.10 : -0.20)
        self.primaryDisabled = primary.opacity(0.40)
        self.primarySoft     = primary.opacity(isDark ? 0.14 : 0.10)

        // Vendor-fixed Apple colours — never influenced by primaryColor.
        self.appleButtonBackground = isDark ? .white : .black
        self.appleButtonLabel      = isDark ? .black : .white

        // Google button style.
        self.googleButtonStyle = GoogleButtonStyle(
            background: .clear,
            borderColor: primary.opacity(0.20),
            borderWidth: 1.0,
            cornerRadius: 9999.0,
            height: 50.0
        )

        // MARK: Background colour

        // Prefer scheme-specific token; fall back to configuration.backgroundColor.
        self.backgroundColor = tokens?.backgroundColor ?? configuration.backgroundColor

        // MARK: Surface colour

        // Prefer scheme-specific surface; fall back to flat configuration token; then adaptive default.
        self.surfaceColor = tokens?.surfaceColor
            ?? configuration.surfaceColor
            ?? AuthTheme.defaultSurfaceColor

        // MARK: Text colour tokens

        // Prefer scheme-specific token; fall back to flat configuration token; then SwiftUI semantic default.
        self.primaryTextColor   = tokens?.primaryTextColor   ?? configuration.primaryTextColor   ?? Color.primary
        self.secondaryTextColor = tokens?.secondaryTextColor ?? configuration.secondaryTextColor ?? Color.secondary
        self.buttonTextColor    = tokens?.buttonTextColor    ?? configuration.buttonTextColor    ?? Color.white
        self.errorColor         = tokens?.errorColor         ?? configuration.errorColor         ?? Color.red

        // Typography pass-through.
        self.font = configuration.font
    }

    // MARK: - Private colour derivation helpers

    /// Returns the default surface colour as an adaptive dynamic colour.
    /// #F5F5F7 (light) / #2C2C2E (dark).
    ///
    /// Uses a UIColor/NSColor dynamic provider block so that the colour adapts to the
    /// trait environment at render time. This ensures dark-mode snapshot tests capture
    /// the correct dark surface colour regardless of when `AuthTheme` is initialised
    /// relative to the colour-scheme environment propagation.
    ///
    /// For unit tests that need to assert exact RGBA values, resolve the colour using
    /// `resolvedSurfaceColor(isDark:)` instead.
    private static let defaultSurfaceColor: Color = {
#if canImport(UIKit)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
                : UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        })
#else
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
                : NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        })
#endif
    }()

    /// Returns the default surface colour eagerly resolved for the given scheme.
    /// #F5F5F7 (light) / #2C2C2E (dark).
    ///
    /// Use this in unit tests when calling `rgba(of:)` requires a flat (non-dynamic)
    /// colour value. Views should use `defaultSurfaceColor` (the adaptive property) instead.
    static func resolvedSurfaceColor(isDark: Bool) -> Color {
#if canImport(UIKit)
        let uiColor = isDark
            ? UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        return Color(uiColor: uiColor)
#else
        let nsColor = isDark
            ? NSColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
            : NSColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1)
        return Color(nsColor: nsColor)
#endif
    }

    /// Resolves the `primaryColor` from `AuthClientConfiguration` for a given colour scheme.
    ///
    /// `AuthClientConfiguration.primaryColor` stores an adaptive `Color` whose resolved
    /// value depends on the current trait/appearance. On iOS, `UIColor.resolvedColor(with:)`
    /// evaluates the dynamic provider; on macOS, `NSColor.withSystemEffect(.none)` paired
    /// with an explicit appearance does the same.
    ///
    /// When a flat (non-adaptive) `Color` is supplied (e.g. in tests), the resolved value is
    /// identical regardless of the colour scheme — which is the correct behaviour.
    private static func resolvedPrimary(from color: Color, isDark: Bool) -> Color {
#if canImport(UIKit)
        let traits = UITraitCollection(userInterfaceStyle: isDark ? .dark : .light)
        let resolved = UIColor(color).resolvedColor(with: traits)
        return Color(uiColor: resolved)
#else
        let appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)!
        var result = Color.clear
        appearance.performAsCurrentDrawingAppearance {
            result = Color(nsColor: NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(color))
        }
        return result
#endif
    }

    /// Returns a new `Color` with brightness adjusted by `delta` (clamped to [0, 1]).
    private static func adjustBrightness(of color: Color, delta: CGFloat) -> Color {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

#if canImport(UIKit)
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let adjusted = max(0, min(1, b + delta))
        return Color(uiColor: UIColor(hue: h, saturation: s, brightness: adjusted, alpha: a))
#else
        NSColor(color).usingColorSpace(.deviceRGB)?
            .getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let adjusted = max(0, min(1, b + delta))
        return Color(nsColor: NSColor(hue: h, saturation: s, brightness: adjusted, alpha: a))
#endif
    }
}

// MARK: - GoogleButtonStyle

/// Resolved style parameters for the "Sign in with Google" button.
struct GoogleButtonStyle {
    /// Button background colour — always `Color.clear` (inherits page background).
    let background: Color
    /// Stroke colour — `primaryColor.opacity(0.20)`.
    let borderColor: Color
    /// Stroke line-width in points.
    let borderWidth: CGFloat
    /// Corner radius in points — `radius.pill` (9999).
    let cornerRadius: CGFloat
    /// Button height in points.
    let height: CGFloat
}

// MARK: - EnvironmentKey

private struct AuthThemeKey: EnvironmentKey {
    static let defaultValue = AuthTheme(
        configuration: AuthClientConfiguration(),
        colorScheme: .light
    )
}

extension EnvironmentValues {
    /// The resolved `AuthTheme` for the current view hierarchy.
    /// Inject via `.authTheme(_:colorScheme:)` on `AuthSheetContainer`.
    var authTheme: AuthTheme {
        get { self[AuthThemeKey.self] }
        set { self[AuthThemeKey.self] = newValue }
    }
}
