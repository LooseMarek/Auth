@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Vapor

/// Creates a test application configured with an in-memory SQLite database for full
/// test isolation. Passes the factory into `configure()` so that `autoMigrate()`
/// never touches `db.sqlite` on disk, regardless of execution order.
func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app, database: .sqlite(.memory))
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
