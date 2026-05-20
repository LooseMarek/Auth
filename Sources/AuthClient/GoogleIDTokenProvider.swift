import Foundation

/// Sentinel error thrown by `GoogleIDTokenProvider` implementations to signal a
/// user cancellation without surfacing an error in the UI.
///
/// Both the production `GIDSignInTokenProvider` and test mocks throw this to allow
/// `GoogleSignInHandler` to handle cancellation without inspecting opaque NSError
/// domains or the GIDSignIn SDK error type directly.
public struct GoogleSignInCancellationError: Error, Sendable {}

/// Abstracts the Google Sign-In SDK token retrieval for testability.
///
/// `GIDSignIn` requires a real `UIViewController` (iOS) or `NSWindow` (macOS) to present
/// the sign-in sheet and cannot be instantiated in unit tests. `GoogleSignInHandler`
/// depends on this protocol instead of `GIDSignIn` directly, allowing tests to inject
/// a mock that returns a token without any UI interaction.
///
/// The production implementation (`GIDSignInTokenProvider`) wraps
/// `GIDSignIn.sharedInstance.signIn(withPresenting:)` on iOS and
/// `GIDSignIn.sharedInstance.signIn(withPresenting:)` with an `NSWindow` on macOS.
public protocol GoogleIDTokenProvider: Sendable {
    /// Requests a Google ID token by presenting the sign-in UI.
    ///
    /// - Returns: The JWT identity token string on success.
    /// - Throws: `GoogleSignInCancellationError` if the user cancels.
    ///           Any other `Error` if the flow fails for another reason.
    func fetchIDToken() async throws -> String
}
