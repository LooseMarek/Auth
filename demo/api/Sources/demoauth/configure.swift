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

    // MARK: Development default — set JWT_SIGNING_SECRET in production
    // The demo API uses a hardcoded insecure secret when JWT_SIGNING_SECRET is absent.
    // This is intentional: the demo is not a production deployment. For a real server,
    // export a strong random value, e.g.:
    //   export JWT_SIGNING_SECRET=$(openssl rand -hex 32)
    let jwtSecret = Environment.get("JWT_SIGNING_SECRET")
        ?? AuthServerConfiguration.developmentDefaultJWTSigningSecret
    let appleJWKSData = try await URLSession.shared.data(
        from: URL(string: "https://appleid.apple.com/auth/keys")!
    ).0
    let appleJWKS = try JSONDecoder().decode(JWKS.self, from: appleJWKSData)

    let googleJWKSData = try await URLSession.shared.data(
        from: URL(string: "https://www.googleapis.com/oauth2/v3/certs")!
    ).0
    let googleJWKS = try JSONDecoder().decode(JWKS.self, from: googleJWKSData)

    let authConfig = AuthServerConfiguration(
        jwtSigningSecret: jwtSecret,
        appleJWKS: appleJWKS,
        googleJWKS: googleJWKS
    )
    app.storage[AuthServerConfiguration.StorageKey.self] = authConfig

    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(CreatePasswordResetToken())
    app.migrations.add(AddAuthProviderToUser())
    app.migrations.add(MakeUserEmailOptional())

    try await app.autoMigrate()

    try routes(app)
}
