import Fluent
import FluentSQLiteDriver
import AuthServer
import Vapor

/// Configures the Vapor application with SQLite persistence and AuthServer integration.
public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

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
