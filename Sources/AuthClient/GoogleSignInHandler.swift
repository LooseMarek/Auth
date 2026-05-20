import AuthShared
import Foundation
import GoogleSignIn
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Handles the Sign in with Google OAuth flow.
///
/// `GoogleSignInHandler` is the bridge between the `GIDSignIn` SDK result and the
/// `AuthManager` / `LoginViewModel` state. It is intentionally separate from
/// `LoginView` so the flow logic can be unit-tested without SwiftUI or `GIDSignIn`
/// involved.
///
/// **Happy path:**
/// 1. `LoginView` calls `performSignIn()` when the user taps the Google button.
/// 2. The injected `GoogleIDTokenProvider` presents the Google sign-in sheet and
///    returns the JWT identity token.
/// 3. If the current session is `.guest`, POST /auth/upgrade is called; otherwise POST /auth/google.
/// 4. On success, `AuthManager.signIn(response:)` transitions state to `.authenticated`.
///
/// **Cancellation:** A cancellation from the SDK is treated as a no-op — no error is
/// surfaced to the user.
///
/// **Errors:** Any network or server error is caught and surfaced as an inline error
/// message on the `LoginViewModel`.
@Observable
@MainActor
public final class GoogleSignInHandler {

    // MARK: - State

    /// `true` while a POST /auth/google (or /auth/upgrade) request is in flight.
    public private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let authManager: AuthManager
    private let viewModel: LoginViewModel
    private let tokenProvider: any GoogleIDTokenProvider

    // MARK: - Init

    /// Creates a `GoogleSignInHandler` with an explicit token provider.
    ///
    /// Use the two-argument convenience init in production (it wires `GIDSignInTokenProvider`).
    /// Use this init in tests to inject a `MockGoogleIDTokenProvider`.
    init(
        authManager: AuthManager,
        viewModel: LoginViewModel,
        tokenProvider: any GoogleIDTokenProvider
    ) {
        self.authManager = authManager
        self.viewModel = viewModel
        self.tokenProvider = tokenProvider
    }

    /// Creates a `GoogleSignInHandler` wired to the real `GIDSignIn` SDK.
    ///
    /// - Parameters:
    ///   - authManager: The shared authentication state manager.
    ///   - viewModel: The `LoginViewModel` that owns the error message.
    convenience init(authManager: AuthManager, viewModel: LoginViewModel) {
        self.init(
            authManager: authManager,
            viewModel: viewModel,
            tokenProvider: GIDSignInTokenProvider()
        )
    }

    // MARK: - Public interface

    /// Initiates the Sign in with Google flow.
    ///
    /// Calls `tokenProvider.fetchIDToken()`, which presents the Google sign-in sheet.
    /// On success, forwards the identity token to the server. Cancellations are silent.
    public func performSignIn() {
        Task { await handleSignIn() }
    }

    /// Core sign-in logic, separated for testability.
    ///
    /// This method is `internal` so tests can `await` it directly without racing
    /// against a detached `Task`.
    func handleSignIn() async {
        isLoading = true
        defer { isLoading = false }

        let identityToken: String
        do {
            identityToken = try await tokenProvider.fetchIDToken()
        } catch is GoogleSignInCancellationError {
            // Silent — return to LoginView without showing an error.
            return
        } catch {
            viewModel.setGoogleSignInError(.serverError)
            return
        }

        do {
            let response: AuthResponse
            if case .guest(let guestUUID) = authManager.session {
                response = try await authManager.networkService.upgradeGuestWithGoogle(
                    guestUUID: guestUUID,
                    identityToken: identityToken
                )
            } else {
                response = try await authManager.networkService.signInWithGoogle(
                    identityToken: identityToken
                )
            }
            authManager.signIn(response: response)
        } catch AuthNetworkError.networkUnavailable {
            viewModel.setGoogleSignInError(.networkUnavailable)
        } catch {
            viewModel.setGoogleSignInError(.serverError)
        }
    }

}

// MARK: - GIDSignInTokenProvider (production)

/// Production implementation of `GoogleIDTokenProvider` that calls `GIDSignIn`.
///
/// On iOS, the presenting view controller is obtained via `UIApplication.shared`.
/// On macOS, the presenting window is obtained via `NSApplication.shared`.
struct GIDSignInTokenProvider: GoogleIDTokenProvider {

    func fetchIDToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
#if canImport(UIKit)
                guard
                    let scene = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first(where: { $0.activationState == .foregroundActive }),
                    let rootViewController = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
                else {
                    continuation.resume(throwing: AuthNetworkError.serverError)
                    return
                }
                GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                    if let error {
                        let nsError = error as NSError
                        // GIDSignInError.canceled = −5
                        if nsError.domain == "com.google.GIDSignInErrorDomain" && nsError.code == -5 {
                            continuation.resume(throwing: GoogleSignInCancellationError())
                        } else {
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                    guard let idToken = result?.user.idToken?.tokenString else {
                        continuation.resume(throwing: AuthNetworkError.serverError)
                        return
                    }
                    continuation.resume(returning: idToken)
                }
#else
                guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                    continuation.resume(throwing: AuthNetworkError.serverError)
                    return
                }
                GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
                    if let error {
                        let nsError = error as NSError
                        // GIDSignInError.canceled = −5
                        if nsError.domain == "com.google.GIDSignInErrorDomain" && nsError.code == -5 {
                            continuation.resume(throwing: GoogleSignInCancellationError())
                        } else {
                            continuation.resume(throwing: error)
                        }
                        return
                    }
                    guard let idToken = result?.user.idToken?.tokenString else {
                        continuation.resume(throwing: AuthNetworkError.serverError)
                        return
                    }
                    continuation.resume(returning: idToken)
                }
#endif
            }
        }
    }
}
