import Vapor
import AuthShared

// MARK: - Vapor Content conformances for AuthShared types
//
// AuthShared types are plain Codable structs (no Vapor dependency).
// These retroactive conformances live in AuthServer so that Vapor can
// automatically decode request bodies and encode response bodies.

extension RegisterRequest: Content {}
extension LoginRequest: Content {}
extension AuthResponse: Content {}
