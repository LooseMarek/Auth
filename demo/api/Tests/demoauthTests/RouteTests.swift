@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Testing
import Vapor

/// Tests verifying route presence and that removed scaffold routes are no longer present.
@Suite("Route Tests", .serialized)
struct RouteTests {

    // MARK: - Hello route

    @Test("GET /hello returns 200 with 'Hello, world!'")
    func testHelloRoute() async throws {
        try await withConfiguredApp { app in
            try await app.testing().test(.GET, "hello") { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            }
        }
    }

    // MARK: - Todo scaffold removal

    @Test("no /todos route exists after Todo scaffold removal")
    func testTodoRoutesDoNotExist() async throws {
        try await withConfiguredApp { app in
            let hasTodosRoute = app.routes.all.contains { route in
                route.path.contains(.constant("todos"))
            }
            #expect(!hasTodosRoute, "No /todos route should exist after Todo scaffold removal")
        }
    }
}
