import Vapor
import Fluent
import Foundation
import AuthShared

/// Vapor `RouteCollection` that handles password-reset initiation.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: ForgotPasswordController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/forgot-password` — generates a reset token and calls the injected email transport
public struct ForgotPasswordController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Reset token lifetime in seconds (1 hour).
    private static let resetTokenTTL: TimeInterval = 3600

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `POST /auth/forgot-password` route.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("forgot-password", use: forgotPassword)
    }

    // MARK: - Forgot Password

    /// Initiates a password reset for the given email address.
    ///
    /// Always returns HTTP 200 to prevent user enumeration. If the email is
    /// registered and an `emailTransport` closure is configured, a reset token
    /// is generated and the closure is called. If no transport is configured,
    /// throws HTTP 500 (fail-fast per ADR-005).
    ///
    /// - Throws: `Abort(.internalServerError)` when `emailTransport` is not configured.
    @Sendable
    func forgotPassword(req: Request) async throws -> Response {
        guard let emailTransport = configuration.emailTransport else {
            throw Abort(.internalServerError, reason: "Email transport is not configured")
        }

        let body = try req.content.decode(ForgotPasswordRequest.self)

        // Look up user — do NOT reveal existence via the response.
        // Guest users have synthetic @auth.internal emails that no one will submit here.
        if let user = try await User.query(on: req.db)
            .filter(\.$email == body.email)
            .first(),
           let userID = user.id
        {
            let userEmail = user.email
            // Invalidate any existing reset tokens for this user.
            try await PasswordResetToken.query(on: req.db)
                .filter(\.$user.$id == userID)
                .delete()

            // Generate and persist a new reset token.
            let rawToken = UUID().uuidString
            let expiresAt = Date().addingTimeInterval(Self.resetTokenTTL)
            let resetToken = PasswordResetToken(token: rawToken, userID: userID, expiresAt: expiresAt)
            try await resetToken.save(on: req.db)

            // Deliver the reset email via the injected transport.
            let subject = "Reset your password"
            let body = "Use the following token to reset your password (valid for 1 hour): \(rawToken)"
            try await emailTransport(userEmail, subject, body)
        }

        // Always 200 — prevents user enumeration.
        return Response(status: .ok)
    }
}
