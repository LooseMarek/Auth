import Vapor
import Fluent
import Foundation
import AuthShared

/// Vapor `RouteCollection` that handles password reset completion.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: ResetPasswordController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/reset-password` — validates the reset token and updates the user's password
public struct ResetPasswordController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `POST /auth/reset-password` route.
    public func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("reset-password", use: resetPassword)
    }

    // MARK: - Reset Password

    /// Resets the user's password using a one-time reset token.
    ///
    /// - Throws: `Abort(.badRequest)` when the token is not found or has expired.
    /// - Returns: HTTP 200 on success.
    @Sendable
    func resetPassword(req: Request) async throws -> Response {
        let body = try req.content.decode(ResetPasswordRequest.self)

        // Look up the reset token.
        guard
            let resetToken = try await PasswordResetToken.query(on: req.db)
                .filter(\.$token == body.token)
                .first()
        else {
            throw Abort(.badRequest, reason: "Invalid or expired reset token")
        }

        // Reject expired tokens.
        guard !resetToken.isExpired else {
            try await resetToken.delete(on: req.db)
            throw Abort(.badRequest, reason: "Invalid or expired reset token")
        }

        // Load the associated user and update the password hash.
        let user = try await resetToken.$user.get(on: req.db)
        user.passwordHash = try await req.password.async.hash(body.newPassword)
        try await user.save(on: req.db)

        // Invalidate the used reset token.
        try await resetToken.delete(on: req.db)

        return Response(status: .ok)
    }
}
