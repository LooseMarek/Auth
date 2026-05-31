import XCTest
import Fluent
import NIOEmbedded
import NIOCore
import Logging
@testable import AuthServer

// NOTE: Unit test per CLAUDE.md constraints.
// AuthServerTests must never add a Fluent driver as a test dependency.
// We use a SchemaCapturingDatabase that records the DatabaseSchema passed to
// execute(schema:) without actually running any SQL — no driver required.

// MARK: - SchemaCapturingDatabase

/// A minimal Database conformer that captures the DatabaseSchema passed to
/// execute(schema:). Used to verify migration field definitions without
/// requiring a Fluent driver or a running database.
private final class SchemaCapturingDatabase: Database, @unchecked Sendable {

    private(set) var capturedSchemas: [DatabaseSchema] = []

    var context: DatabaseContext {
        DatabaseContext(
            configuration: _StubDatabaseConfiguration(),
            logger: Logger(label: "test"),
            eventLoop: EmbeddedEventLoop()
        )
    }

    var inTransaction: Bool { false }

    func execute(query: DatabaseQuery, onOutput: @escaping @Sendable (any DatabaseOutput) -> Void) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    func execute(schema: DatabaseSchema) -> EventLoopFuture<Void> {
        capturedSchemas.append(schema)
        return context.eventLoop.makeSucceededVoidFuture()
    }

    func execute(enum: DatabaseEnum) -> EventLoopFuture<Void> {
        context.eventLoop.makeSucceededVoidFuture()
    }

    func transaction<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }

    func withConnection<T>(_ closure: @escaping @Sendable (any Database) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        closure(self)
    }
}

private struct _StubDatabaseConfiguration: DatabaseConfiguration {
    var middleware: [any AnyModelMiddleware] = []
    func makeDriver(for databases: Databases) -> any DatabaseDriver {
        fatalError("_StubDatabaseConfiguration.makeDriver must not be called in unit tests")
    }
}

// MARK: - CreateUserMigrationTests

final class CreateUserMigrationTests: XCTestCase {

    // MARK: - Schema name

    func testCreateUser_schemaName() {
        // CreateUser targets the "users" schema — verify without executing the migration.
        XCTAssertEqual(User.schema, "users")
    }

    // MARK: - Field presence

    func testCreateUser_includesAuthProviderField() async throws {
        let db = SchemaCapturingDatabase()
        let migration = CreateUser()

        try await migration.prepare(on: db)

        guard let schema = db.capturedSchemas.first else {
            XCTFail("CreateUser.prepare() did not execute any schema operation")
            return
        }

        let fieldNames: [String] = schema.createFields.compactMap { definition in
            guard case .definition(let name, _, _) = definition,
                  case .key(let fieldKey) = name else { return nil }
            return fieldKey.description
        }

        XCTAssertTrue(
            fieldNames.contains("auth_provider"),
            "CreateUser.prepare() must include an 'auth_provider' field. Found: \(fieldNames)"
        )
    }

    // MARK: - auth_provider is nullable

    func testCreateUser_authProviderFieldIsNullable() async throws {
        let db = SchemaCapturingDatabase()
        let migration = CreateUser()

        try await migration.prepare(on: db)

        guard let schema = db.capturedSchemas.first else {
            XCTFail("CreateUser.prepare() did not execute any schema operation")
            return
        }

        let authProviderField = schema.createFields.first { definition in
            guard case .definition(let name, _, _) = definition,
                  case .key(let fieldKey) = name else { return false }
            return fieldKey.description == "auth_provider"
        }

        guard let field = authProviderField,
              case .definition(_, _, let constraints) = field else {
            XCTFail("auth_provider field not found in CreateUser schema")
            return
        }

        let isRequired = constraints.contains { constraint in
            if case .required = constraint { return true }
            return false
        }
        XCTAssertFalse(isRequired, "auth_provider must be nullable (no .required constraint)")
    }
}
