import AuthServer
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    guard let authConfig = app.storage[AuthServerConfiguration.StorageKey.self] else {
        throw Abort(.internalServerError, reason: "AuthServerConfiguration not set in app.storage")
    }

    try app.register(collection: AuthController(configuration: authConfig))
    try app.register(collection: RefreshTokenController(configuration: authConfig))
}
