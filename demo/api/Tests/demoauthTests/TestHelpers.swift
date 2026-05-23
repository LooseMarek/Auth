@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Vapor

/// Creates a test application, overrides the database with an in-memory SQLite
/// instance for test isolation, then calls `configure()` so that `autoMigrate()`
/// inside configure targets the in-memory DB rather than `db.sqlite` on disk.
func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
        try await configure(app)
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
