import AuthenticationServices
import AuthShared
import Foundation

/// Handles the result of a Sign in with Apple authorisation flow.
///
/// `AppleSignInHandler` is the bridge between the system `ASAuthorizationController`
/// completion result and the `AuthManager` / `LoginViewModel` state. It is
/// intentionally separate from `LoginView` so the flow logic can be unit-tested
/// without SwiftUI or `ASAuthorizationController` involved.
///
/// **Happy path:**
/// 1. `LoginView` receives the `onCompletion` result from `SignInWithAppleButton`.
/// 2. `LoginView` calls `handleCredential(_:)` with the credential.
/// 3. If the current session is `.guest`, POST /auth/upgrade is called; otherwise POST /auth/apple.
/// 4. On success, `AuthManager.signIn(response:)` transitions state to `.authenticated`.
///
/// **Cancellation:** `handleCancellation()` is a no-op — no error is surfaced to the user.
///
/// **Errors:** Any network or server error is caught and surfaced as an inline error
/// message on the `LoginViewModel`.
@Observable
@MainActor
public final class AppleSignInHandler: NSObject {

    // MARK: - State

    /// `true` while a POST /auth/apple (or /auth/upgrade) request is in flight.
    public private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let authManager: AuthManager
    private let viewModel: LoginViewModel

    // MARK: - Private

    private var currentController: ASAuthorizationController?

    // MARK: - Init

    init(authManager: AuthManager, viewModel: LoginViewModel) {
        self.authManager = authManager
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - Public interface

    /// Initiates the Sign in with Apple system sheet.
    ///
    /// Creates and retains an `ASAuthorizationController`, sets itself as the delegate,
    /// then calls `performRequests()`. Results are delivered via `ASAuthorizationControllerDelegate`.
    public func performSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        currentController = controller
        controller.performRequests()
    }

    /// Called when the system delivers a successful Apple credential.
    ///
    /// Extracts the identity token from `credential`, calls the appropriate server
    /// endpoint, and updates `AuthManager` state on success or sets an inline error
    /// on the `LoginViewModel` on failure.
    ///
    /// - Parameter credential: The value conforming to ``AppleIDCredentialProtocol``
    ///   returned by the system authorisation controller.
    public func handleCredential(_ credential: any AppleIDCredentialProtocol) async {
        guard let identityToken = credential.identityTokenString else {
            viewModel.setAppleSignInError(.serverError)
            return
        }

        let displayName = credential.fullName.flatMap { components in
            PersonNameComponentsFormatter().string(from: components).nilIfEmpty
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: AuthResponse
            if case .guest(let guestUUID) = authManager.session {
                response = try await authManager.withFreshToken { accessToken in
                    try await authManager.networkService.upgradeGuestWithApple(
                        guestUUID: guestUUID,
                        accessToken: accessToken,
                        identityToken: identityToken,
                        displayName: displayName
                    )
                }
            } else {
                response = try await authManager.networkService.signInWithApple(
                    identityToken: identityToken,
                    displayName: displayName
                )
            }
            authManager.signIn(response: response)
        } catch AuthNetworkError.networkUnavailable {
            viewModel.setAppleSignInError(.networkUnavailable)
        } catch {
            viewModel.setAppleSignInError(.serverError)
        }
    }

    /// Called when the user cancels the system Sign in with Apple sheet.
    ///
    /// This is intentionally a no-op: Apple HIG requires that cancellation returns
    /// the user silently to `LoginView` without showing any error.
    public func handleCancellation() async {
        // Silent — do not modify AuthManager state or show an error.
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInHandler: ASAuthorizationControllerDelegate {

    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor [self] in
            defer { currentController = nil }
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            await handleCredential(credential)
        }
    }

    nonisolated public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor [self] in
            defer { currentController = nil }
            let nsError = error as NSError
            if nsError.domain == ASAuthorizationError.errorDomain,
               nsError.code == ASAuthorizationError.canceled.rawValue {
                await handleCancellation()
            } else {
                viewModel.setAppleSignInError(.serverError)
            }
        }
    }
}

// MARK: - ASAuthorizationAppleIDCredential conformance

extension ASAuthorizationAppleIDCredential: AppleIDCredentialProtocol {

    /// The identity token as a UTF-8 `String`, decoded from the raw `Data` returned by the system.
    ///
    /// Named `identityTokenString` to avoid colliding with `identityToken: Data?` on the concrete type.
    public var identityTokenString: String? {
        guard let data = identityToken else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Private helpers

private extension String {
    /// Returns `nil` when the string is empty (after trimming), otherwise returns `self`.
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
}
