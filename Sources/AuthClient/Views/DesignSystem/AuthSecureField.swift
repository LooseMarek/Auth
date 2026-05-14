import SwiftUI

/// A styled secure/password field matching the Auth design system spec.
///
/// Includes a show/hide toggle button with a 44x44pt tap target as per the accessibility spec.
struct AuthSecureField: View {

    @Binding var text: String
    @Binding var isVisible: Bool
    let placeholder: String
    let isError: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            if isVisible {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
            } else {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
            }

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(
                isVisible
                    ? String(localized: "auth.field.password.hide", bundle: .module)
                    : String(localized: "auth.field.password.show", bundle: .module)
            )
        }
        .padding(.leading, AuthSpacing.sm)
        .frame(height: 50)
        .background(authSurfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: AuthRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AuthRadius.sm, style: .continuous)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }

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
            return Color.accentColor
        } else {
            return Color(.systemFill)
        }
    }

    private var borderWidth: CGFloat {
        isError || isFocused ? 1.5 : 1
    }
}
