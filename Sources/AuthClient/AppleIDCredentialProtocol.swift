import Foundation

/// A protocol that abstracts `ASAuthorizationAppleIDCredential` for testability.
///
/// `ASAuthorizationAppleIDCredential` cannot be instantiated directly in unit tests,
/// so `AppleSignInHandler` depends on this protocol rather than the concrete type.
/// In production, `ASAuthorizationAppleIDCredential` is extended to conform below.
/// In tests, `MockAppleIDCredential` (in the test target) provides a stand-in.
///
/// `identityTokenString` is used rather than `identityToken` to avoid colliding with
/// the existing `identityToken: Data?` property on `ASAuthorizationAppleIDCredential`.
public protocol AppleIDCredentialProtocol: Sendable {
    /// The JWT identity token as a UTF-8 string, returned by Sign in with Apple.
    var identityTokenString: String? { get }
    /// The user's name components — only supplied on first sign-in.
    var fullName: PersonNameComponents? { get }
}
