import SwiftUI

/// Placeholder for the Sign in with Apple button.
///
/// The production implementation will use `SignInWithAppleButton` from `AuthenticationServices`
/// (which requires UIKit on iOS — guarded with `#if canImport(UIKit)`).
/// This placeholder preserves the correct layout and dimensions for snapshot tests and
/// serves as a drop-in that will be replaced when the Apple auth task is implemented.
struct AuthSocialAppleButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AuthSpacing.sm) {
                Image(systemName: "apple.logo")
                    .font(.body.weight(.medium))
                Text("Sign in with Apple")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .background(Color.black)
        .clipShape(Capsule())
    }
}
