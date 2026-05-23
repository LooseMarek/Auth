import Foundation
import Vapor

/// Response body for the `GET /me` endpoint.
///
/// Returns profile and token debug information for the authenticated user.
/// This is a demo-only DTO — it is not part of `AuthShared`.
struct MeResponse: Content {

    /// The authenticated user's unique identifier.
    let id: UUID

    /// The user's email address. Empty string for guest users.
    let email: String

    /// The authentication provider used to create the account.
    /// One of: `"email"`, `"apple"`, `"google"`, `"guest"`.
    let authProvider: String

    /// The date the user account was created.
    let createdAt: Date

    /// Whether this is a guest (anonymous) account.
    let isGuest: Bool

    /// The expiry date of the current access token.
    let accessTokenExpiry: Date

    /// The unique identifier of the active refresh token associated with this session.
    let refreshTokenId: UUID
}
