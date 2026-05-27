import AuthServer
import Vapor

struct ConfigurationError: Error {
    let reason: String
}

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    guard let authConfig = app.storage[AuthServerConfiguration.StorageKey.self] else {
        throw ConfigurationError(reason: "AuthServerConfiguration not set in app.storage")
    }

    try app.register(collection: AuthController(configuration: authConfig))
    try app.register(collection: RefreshTokenController(configuration: authConfig))
    try app.register(collection: MeController(configuration: authConfig))
    // AccountDeletionController must be registered so that DELETE /auth/account is handled.
    // Without it, Vapor returns 404 and the client shows "Something went wrong." even
    // when the server receives the request (Vapor logs all requests, including 404s).
    try app.register(collection: AccountDeletionController(configuration: authConfig))
    // GuestAuthController must be registered so that POST /auth/guest is handled.
    // Without it, Vapor returns 404 and "Continue as Guest" shows "Something went wrong."
    try app.register(collection: GuestAuthController(configuration: authConfig))
    try app.register(collection: UpgradeController(configuration: authConfig))
    // AppleAuthController must be registered so that POST /auth/apple is handled.
    try app.register(collection: AppleAuthController(configuration: authConfig))
    // GoogleAuthController must be registered so that POST /auth/google is handled.
    // Without it, Vapor returns 404 and Sign in with Google shows "Something went wrong."
    try app.register(collection: GoogleAuthController(configuration: authConfig))
}
