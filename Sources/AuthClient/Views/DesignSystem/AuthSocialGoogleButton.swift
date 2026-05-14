import SwiftUI

/// The Sign in with Google button following Google's branding guidelines.
///
/// Background: always white (`#FFFFFF`). Border: `#747775`. Label: `#1F1F1F`.
/// These are brand-constrained and must not be themed via `AuthClientConfiguration`.
struct AuthSocialGoogleButton: View {

    let action: () -> Void

    private let googleBorderColor = Color(red: 0.455, green: 0.467, blue: 0.459)    // #747775
    private let googleLabelColor  = Color(red: 0.122, green: 0.122, blue: 0.122)    // #1F1F1F

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Google "G" icon placeholder — the SVG asset is added in the Google auth task
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(googleLabelColor)
                    .padding(.leading, AuthSpacing.md)

                Text("auth.button.google", bundle: .module)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(googleLabelColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(googleBorderColor, lineWidth: 1)
            )
        }
        .accessibilityLabel(String(localized: "auth.button.google.accessibility", bundle: .module))
    }
}
