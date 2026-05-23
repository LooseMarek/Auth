@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Vapor

/// Creates a test application, calls `configure()`, overrides the database
/// with an in-memory SQLite instance for test isolation, runs the test
/// closure, then tears down the app.
func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
