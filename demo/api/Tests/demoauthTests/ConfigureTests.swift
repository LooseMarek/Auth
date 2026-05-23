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

    // MARK: - Migration registration

    @Test("configure registers CreateUser, CreateRefreshToken, and CreatePasswordResetToken migrations")
    func testAuthMigrationsAreRegistered() async throws {
        try await withConfiguredApp { app in
            // configure() already called autoMigrate() against the file-based DB.
            // Run it again against the in-memory DB (set by withConfiguredApp) so
            // the tables exist for the queries below.
            try await app.autoMigrate()
            do {
                let userCount = try await User.query(on: app.db).count()
                #expect(userCount == 0, "users table should exist and be empty")

                let tokenCount = try await RefreshToken.query(on: app.db).count()
                #expect(tokenCount == 0, "refresh_tokens table should exist and be empty")

                let resetCount = try await PasswordResetToken.query(on: app.db).count()
                #expect(resetCount == 0, "password_reset_tokens table should exist and be empty")
            } catch {
                try await app.autoRevert()
                throw error
            }
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
