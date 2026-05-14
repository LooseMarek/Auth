import Foundation

/// Spacing tokens for `AuthClient` views, sourced from the design system.
///
/// Values match the design-system.md spacing table.
/// Never use raw numeric literals for spacing in AuthClient views — always use these constants.
enum AuthSpacing {
    /// 4pt — icon internal padding, tight inline gaps
    static let xxs: CGFloat = 4
    /// 8pt — between field and inline error
    static let xs: CGFloat = 8
    /// 12pt — between stacked components
    static let sm: CGFloat = 12
    /// 16pt — standard horizontal edge insets
    static let md: CGFloat = 16
    /// 24pt — between major sections
    static let lg: CGFloat = 24
    /// 32pt — top/bottom padding on screens
    static let xl: CGFloat = 32
    /// 48pt — hero spacing
    static let xxl: CGFloat = 48
}

// MARK: - Border Radius Tokens

/// Corner-radius tokens for `AuthClient` views, sourced from the design system.
enum AuthRadius {
    /// 6pt — text field inner corners
    static let sm: CGFloat = 6
    /// 10pt — primary and secondary buttons
    static let md: CGFloat = 10
    /// 14pt — cards, surface containers
    static let lg: CGFloat = 14
    /// 9999pt — social sign-in buttons (pill shape)
    static let pill: CGFloat = 9999
}
