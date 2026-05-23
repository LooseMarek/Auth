@testable import demoauth
import AuthServer
import FluentSQLiteDriver
import VaporTesting
import Testing
import Vapor

/// Tests that `configure(_:)` registers the expected AuthServer migrations
/// and routes on the Vapor application.
@Suite("Configure Tests", .serialized)
struct ConfigureTests {

    // MARK: - Helpers

    /// Creates a test application, calls `configure()`, overrides the database
    /// with an in-memory SQLite instance for test isolation, runs the test
    /// closure, then tears down the app.
    private func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            // Override the file-based SQLite database set by configure() with
            // an in-memory database so tests are isolated and leave no files.
            app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
            try await test(app)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    // MARK: - Migration registration

    @Test("configure registers CreateUser, CreateRefreshToken, and CreatePasswordResetToken migrations")
    func testAuthMigrationsAreRegistered() async throws {
        try await withConfiguredApp { app in
            // Verify migration registration by running autoMigrate() on the
            // in-memory SQLite database and querying each AuthServer table.
            // A successful query proves the table (and therefore its migration)
            // was registered and ran.
            try await app.autoMigrate()

            let userCount = try await User.query(on: app.db).count()
            #expect(userCount == 0, "users table should exist and be empty")

            let tokenCount = try await RefreshToken.query(on: app.db).count()
            #expect(tokenCount == 0, "refresh_tokens table should exist and be empty")

            let resetCount = try await PasswordResetToken.query(on: app.db).count()
            #expect(resetCount == 0, "password_reset_tokens table should exist and be empty")

            try await app.autoRevert()
        }
    }

    // MARK: - Route registration

    @Test("configure registers POST /auth/register and POST /auth/login routes")
    func testAuthRoutesAreRegistered() async throws {
        try await withConfiguredApp { app in
            let routes = app.routes.all

            let hasRegister = routes.contains { route in
                route.method == .POST &&
                route.path.map(\.description) == ["auth", "register"]
            }
            #expect(hasRegister, "POST /auth/register route should be registered")

            let hasLogin = routes.contains { route in
                route.method == .POST &&
                route.path.map(\.description) == ["auth", "login"]
            }
            #expect(hasLogin, "POST /auth/login route should be registered")
        }
    }
}
