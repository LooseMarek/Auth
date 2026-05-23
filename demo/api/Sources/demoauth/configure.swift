import Fluent
import FluentSQLiteDriver
import AuthServer
import Vapor

/// Configures the Vapor application with SQLite persistence and AuthServer integration.
///
/// - Parameters:
///   - app: The Vapor application to configure.
///   - database: The database configuration factory. Defaults to a file-backed SQLite
///     database (`db.sqlite`). Pass `.sqlite(.memory)` in tests for full isolation.
public func configure(
    _ app: Application,
    database: DatabaseConfigurationFactory = .sqlite(.file("db.sqlite"))
) async throws {
    app.databases.use(database, as: .sqlite)

    let jwtSecret: String
    if let secret = Environment.get("JWT_SIGNING_SECRET") {
        jwtSecret = secret
    } else {
        app.logger.warning("JWT_SIGNING_SECRET is not set — using insecure default. Set this environment variable before deploying.")
        jwtSecret = "demo-secret-change-in-production"
    }
    let authConfig = AuthServerConfiguration(jwtSigningSecret: jwtSecret)
    app.storage[AuthServerConfiguration.StorageKey.self] = authConfig

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePasswordResetToken())

    try await app.autoMigrate()

    try routes(app)
}
