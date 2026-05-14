import SwiftUI

/// A full-width primary action button matching the Auth design system spec.
///
/// - Shows a `ProgressView` spinner when `isLoading` is `true`.
/// - Renders at 0.5 opacity when `isEnabled` is `false`.
/// - Height: 50pt (meets 44pt minimum tap target).
struct AuthPrimaryButton: View {

    let label: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(Color.accentColor.opacity(isEnabled && !isLoading ? 1 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: AuthRadius.md, style: .continuous))
        .disabled(!isEnabled || isLoading)
    }
}
