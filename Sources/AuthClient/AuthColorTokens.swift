import SwiftUI

/// A set of colour tokens for a single colour scheme (light or dark).
///
/// Pass one instance to `AuthClientConfiguration(light:dark:)` to supply
/// per-scheme colours. Any property left as `nil` falls back to the corresponding
/// adaptive default in `AuthTheme`.
///
/// Example — supply completely different brand colours per scheme:
/// ```swift
/// AuthClientConfiguration(
///     light: AuthColorTokens(
///         primaryColor: Color(red: 0.039, green: 0.4, blue: 1.0),
///         backgroundColor: .white
///     ),
///     dark: AuthColorTokens(
///         primaryColor: Color(red: 0.239, green: 0.545, blue: 1.0),
///         backgroundColor: Color(red: 0.1, green: 0.1, blue: 0.13)
///     )
/// )
/// ```
public struct AuthColorTokens: Sendable {

    /// Tint applied to buttons and interactive elements.
    /// `nil` uses the Auth Blue adaptive default for the active scheme.
    public let primaryColor: Color?

    /// Screen background colour.
    /// `nil` uses the platform system background for the active scheme.
    public let backgroundColor: Color?

    /// Text field / input background colour.
    /// `nil` uses the `color.surface` adaptive default (#F5F5F7 light / #2C2C2E dark).
    public let surfaceColor: Color?

    /// Primary body text colour.
    /// `nil` falls back to SwiftUI's `Color.primary`.
    public let primaryTextColor: Color?

    /// Secondary / hint text colour.
    /// `nil` falls back to SwiftUI's `Color.secondary`.
    public let secondaryTextColor: Color?

    /// Label colour for the primary action button.
    /// `nil` falls back to `.white`.
    public let buttonTextColor: Color?

    /// Colour used for error messages and icons.
    /// `nil` falls back to `Color.red`.
    public let errorColor: Color?

    public init(
        primaryColor: Color? = nil,
        backgroundColor: Color? = nil,
        surfaceColor: Color? = nil,
        primaryTextColor: Color? = nil,
        secondaryTextColor: Color? = nil,
        buttonTextColor: Color? = nil,
        errorColor: Color? = nil
    ) {
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.surfaceColor = surfaceColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.buttonTextColor = buttonTextColor
        self.errorColor = errorColor
    }
}
