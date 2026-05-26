import Fluent
import FluentSQLiteDriver
import JWTKit
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
    app.http.server.configuration.hostname = "0.0.0.0"
    app.databases.use(database, as: .sqlite)

    let jwtSecret: String
    if let secret = Environment.get("JWT_SIGNING_SECRET") {
        jwtSecret = secret
    } else {
        app.logger.warning("JWT_SIGNING_SECRET is not set — using insecure default. Set this environment variable before deploying.")
        jwtSecret = "demo-secret-change-in-production"
    }
    let appleJWKSData = try await URLSession.shared.data(
        from: URL(string: "https://appleid.apple.com/auth/keys")!
    ).0
    let appleJWKS = try JSONDecoder().decode(JWKS.self, from: appleJWKSData)

    let authConfig = AuthServerConfiguration(jwtSigningSecret: jwtSecret, appleJWKS: appleJWKS)
    app.storage[AuthServerConfiguration.StorageKey.self] = authConfig

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePasswordResetToken())
    app.migrations.add(AddAuthProviderToUser())
    app.migrations.add(MakeUserEmailOptional())

    try await app.autoMigrate()

    try routes(app)
}
