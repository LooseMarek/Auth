import Foundation

/// Local mirror of the demo API's `GET /me` response body.
///
/// This struct is a plain Foundation type — it does not import Vapor.
/// It mirrors `demo/api/Sources/demoauth/DTOs/MeResponse.swift` exactly.
struct MeResponse: Codable, Sendable {

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
