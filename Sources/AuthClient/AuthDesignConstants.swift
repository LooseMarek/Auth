import Foundation
/// Static layout constants derived from the design system token table.
///
/// These values are not theme-dependent — they encode structural constraints from
/// design-system.md (tap targets, heights) that must remain stable across all themes.
/// Tests reference these constants to prevent regressions against WCAG 44 × 44pt minimums.
enum AuthDesignConstants {
    /// Height of the primary action button (Log in, Create account, Send reset link).
    /// Design-system.md §10.1: 52pt — naturally exceeds the 44pt minimum tap target.
    static let primaryButtonHeight: CGFloat = 52

    /// Height of social / secondary buttons (Sign in with Apple, Sign in with Google,
    /// Continue as Guest).
    /// Design-system.md §10.5–10.7: 50pt — naturally exceeds the 44pt minimum tap target.
    static let socialButtonHeight: CGFloat = 50

    /// WCAG 2.1 SC 2.5.5 minimum tap target size.
    /// Every interactive element must be at least 44 × 44pt.
    static let minimumTapTarget: CGFloat = 44
}
