import Vapor
import Fluent
import JWTKit
import AuthShared

/// Vapor `RouteCollection` that handles in-app password changes for email-auth users.
///
/// Register this controller with your Vapor `Application`:
/// ```swift
/// try app.register(collection: ChangePasswordController(configuration: config))
/// ```
///
/// This registers:
/// - `POST /auth/change-password` — verifies the current password and updates it to the
///   new one; requires a valid Bearer JWT.
///
/// Returns HTTP 401 when `currentPassword` does not match the stored bcrypt hash.
/// Returns HTTP 422 when the user has no stored password hash (Apple, Google, or guest account).
public struct ChangePasswordController: RouteCollection, Sendable {

    private let configuration: AuthServerConfiguration

    /// Creates the controller with the shared `AuthServerConfiguration`.
    public init(configuration: AuthServerConfiguration) {
        self.configuration = configuration
    }

    /// Registers the `POST /auth/change-password` route under the JWT-protected route group.
    public func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        let protected = auth.grouped(JWTMiddleware(configuration: configuration))
        protected.post("change-password", use: changePassword)
    }

    // MARK: - Change Password

    /// Changes the authenticated user's password.
    ///
    /// Decodes the Bearer JWT to identify the user, verifies `currentPassword` against
    /// the stored bcrypt hash, and replaces it with a bcrypt hash of `newPassword`.
    ///
    /// - Throws: `Abort(.unauthorized)` when the JWT is missing, malformed, or the
    ///   `currentPassword` does not match the stored hash.
    /// - Throws: `Abort(.notFound)` when no user with the decoded ID exists in the DB.
    /// - Throws: `Abort(.unprocessableEntity)` when the user account has no stored
    ///   password (i.e. Apple, Google, or guest account).
    /// - Returns: HTTP 200 with a `{ "message": "Password changed" }` body.
    @Sendable
    func changePassword(req: Request) async throws -> Response {
        // Extract and verify the Bearer JWT.
        guard let bearerHeader = req.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization header")
        }

        let keys = JWTKeyCollection()
        await keys.add(
            hmac: HMACKey(from: configuration.jwtSigningSecret),
            digestAlgorithm: .sha256
        )
        let payload = try await keys.verify(bearerHeader.token, as: AuthPayload.self)

        guard let userID = UUID(uuidString: payload.subject.value) else {
            throw Abort(.unauthorized, reason: "Invalid user identifier in token")
        }

        // Look up the user record.
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        // Only email-auth users have a password hash — reject social/guest accounts.
        guard !user.passwordHash.isEmpty else {
            throw Abort(.unprocessableEntity, reason: "Password change is not available for this account type. Only email-authenticated accounts can change their password.")
        }

        // Decode the request body.
        let body = try req.content.decode(ChangePasswordRequest.self)

        // Verify the current password against the stored bcrypt hash.
        let currentPasswordMatches = try await req.password.async.verify(
            body.currentPassword,
            created: user.passwordHash
        )
        guard currentPasswordMatches else {
            throw Abort(.unauthorized, reason: "Current password is incorrect")
        }

        // Hash the new password and persist it.
        user.passwordHash = try await req.password.async.hash(body.newPassword)
        try await user.save(on: req.db)

        // Return 200 with a simple confirmation body.
        let responseJSON = #"{"message":"Password changed"}"#
        let response = Response(status: .ok)
        response.headers.contentType = .json
        response.body = .init(string: responseJSON)
        return response
    }
}
