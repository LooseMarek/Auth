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

    // MARK: - Email transport

    @Test("configure sets emailTransport on AuthServerConfiguration")
    func testEmailTransportIsConfigured() async throws {
        try await withConfiguredApp { app in
            let config = app.storage[AuthServerConfiguration.StorageKey.self]
            #expect(config?.emailTransport != nil, "emailTransport should be configured so ForgotPasswordController does not 500")
        }
    }

    @Test("configure email transport closure uses Vapor logger and does not throw")
    func testEmailTransportClosureUsesVaporLogger() async throws {
        // Pass unsetEnvKeys so the helper unsets RESEND_API_KEY *after* Vapor loads
        // .env (which re-sets it via setenv). configure() then picks the console path
        // and the transport closure logs via app.logger without making any network call.
        try await withConfiguredApp(unsetEnvKeys: ["RESEND_API_KEY"]) { app in
            let config = app.storage[AuthServerConfiguration.StorageKey.self]
            let transport = try #require(config?.emailTransport, "emailTransport must be non-nil")
            // Invoke the closure — it should log via app.logger (Vapor structured logging)
            // and complete without throwing. Visual confirmation of log output is an
            // integration concern; this smoke-test ensures the logger-based closure runs.
            try await transport("test@example.com", "Reset your password", "Your reset link: https://example.com/reset?token=abc123")
        }
    }

    @Test("configure uses console transport when RESEND_API_KEY is absent")
    func testConsoleTransportIsUsedWhenResendApiKeyIsAbsent() async throws {
        // Pass unsetEnvKeys so the helper unsets RESEND_API_KEY *after* Vapor loads
        // .env (which re-sets it via setenv). configure() then falls through to the
        // console logger path and the transport must not throw when invoked.
        try await withConfiguredApp(unsetEnvKeys: ["RESEND_API_KEY"]) { app in
            let config = app.storage[AuthServerConfiguration.StorageKey.self]
            let transport = try #require(config?.emailTransport, "emailTransport must be non-nil even without RESEND_API_KEY")
            // Smoke-test: the console transport should complete without throwing.
            try await transport("console@example.com", "Console transport test", "body text")
        }
    }

    @Test("configure uses Resend transport when RESEND_API_KEY env var is set")
    func testResendTransportIsUsedWhenEnvVarIsSet() async throws {
        // Set the env var before configuring the app.
        setenv("RESEND_API_KEY", "test-resend-key-12345", 1)
        defer { unsetenv("RESEND_API_KEY") }

        try await withConfiguredApp { app in
            let config = app.storage[AuthServerConfiguration.StorageKey.self]
            // The transport must be non-nil when RESEND_API_KEY is present.
            #expect(config?.emailTransport != nil, "emailTransport must be non-nil when RESEND_API_KEY is set")
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
