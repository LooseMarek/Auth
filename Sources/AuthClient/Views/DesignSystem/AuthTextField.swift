import SwiftUI

/// A styled text field matching the Auth design system spec.
///
/// Uses `color.surface` background, `border.field` / `border.field.error` stroke,
/// and `radius.sm` corner radius.
struct AuthTextField: View {

    @Binding var text: String
    let placeholder: String
    let isError: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, AuthSpacing.sm)
            .frame(height: 50)
            .background(authSurfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: AuthRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AuthRadius.sm, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .focused($isFocused)
    }

    /// `color.surface` — secondary system background, adaptive light/dark.
    private var authSurfaceColor: Color {
#if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
#else
        Color(NSColor.controlBackgroundColor)
#endif
    }

    private var borderColor: Color {
        if isError {
            return Color(red: 1, green: 0.231, blue: 0.188) // color.error
        } else if isFocused {
            return Color.accentColor // color.primary / border.field.focused
        } else {
            return Color(.systemFill) // border.field
        }
    }

    private var borderWidth: CGFloat {
        isError || isFocused ? 1.5 : 1
    }
}
