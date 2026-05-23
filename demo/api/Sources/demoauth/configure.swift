import Fluent
import FluentSQLiteDriver
import AuthServer
import Vapor

/// Configures the Vapor application with SQLite persistence and AuthServer integration.
public func configure(_ app: Application) async throws {
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    let authConfig = AuthServerConfiguration(
        jwtSigningSecret: Environment.get("JWT_SIGNING_SECRET") ?? "demo-secret-change-in-production"
    )
    app.storage[AuthServerConfiguration.StorageKey.self] = authConfig

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePasswordResetToken())

    try routes(app)
}
