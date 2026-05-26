import XCTest
import Fluent
@testable import AuthServer

// NOTE: Unit test per CLAUDE.md constraints.
// No Fluent driver import. We only assert the schema name
// exposed by the migration type — no DB execution.

final class MakeUserEmailOptionalTests: XCTestCase {

    func testMigrationName() {
        let migration = MakeUserEmailOptional()
        XCTAssertEqual(migration.name, "make_user_email_optional")
    }
}
