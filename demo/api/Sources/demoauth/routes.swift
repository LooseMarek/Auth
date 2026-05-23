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
}
