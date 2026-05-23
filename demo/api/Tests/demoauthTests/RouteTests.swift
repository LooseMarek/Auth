@testable import demoauth
import FluentSQLiteDriver
import VaporTesting
import Testing
import Vapor

/// Tests verifying that removed scaffold routes are no longer present.
@Suite("Route Tests", .serialized)
struct RouteTests {

    // MARK: - Helpers

    private func withConfiguredApp(_ test: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
            try await test(app)
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
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
