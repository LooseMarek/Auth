@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Vapor

/// Creates a test application configured with an in-memory SQLite database for full
/// test isolation. Passes the factory into `configure()` so that `autoMigrate()`
/// never touches `db.sqlite` on disk, regardless of execution order.
///
/// - Parameters:
///   - unsetEnvKeys: Environment variable keys to unset **after** Vapor creates the
///     application (and loads `.env`) but **before** `configure()` runs. This lets
///     individual tests override or suppress keys that are present in `.env` without
///     affecting other tests. Callers are responsible for restoring values if needed.
///   - test: The test body receiving the configured application.
func withConfiguredApp(
    unsetEnvKeys: [String] = [],
    _ test: (Application) async throws -> Void
) async throws {
    let app = try await Application.make(.testing)
    // Unset any keys the caller wants to suppress AFTER Vapor has loaded .env —
    // Vapor's dotenv loader calls setenv() during Application.make(), so any
    // unsetenv() in the test body (before withConfiguredApp) is undone by that load.
    for key in unsetEnvKeys {
        unsetenv(key)
    }
    do {
        try await configure(app, database: .sqlite(.memory))
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
