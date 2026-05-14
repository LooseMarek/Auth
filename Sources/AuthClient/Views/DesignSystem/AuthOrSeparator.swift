import SwiftUI

/// The "or" horizontal separator used between primary and social sign-in buttons.
///
/// Layout: `HStack { line — label — line }` using design system tokens.
struct AuthOrSeparator: View {

    var body: some View {
        HStack(spacing: AuthSpacing.sm) {
            separatorLine
            Text("auth.separator.or", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            separatorLine
        }
        .accessibilityHidden(true)
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(separatorColor)
            .frame(height: 1)
    }

    private var separatorColor: Color {
#if canImport(UIKit)
        Color(UIColor.separator)
#else
        Color(NSColor.separatorColor)
#endif
    }
}
