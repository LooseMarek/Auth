import Fluent

/// Fluent migration that converts legacy guest rows (email = "") to synthetic guest emails.
///
/// Before this migration, guest users were created with `email = ""`. The UNIQUE constraint
/// on `users.email` prevented more than one guest from existing at a time. After this
/// migration, guests use `guest+{UUID}@auth.internal` as their stored email — each value is
/// unique, so the constraint is satisfied and multiple guests can coexist.
///
/// This migration performs **no schema change** (no ALTER TABLE), making it compatible with
/// SQLite, PostgreSQL, and MySQL. It only updates data in existing rows.
///
/// Migration name: `make_user_email_optional`
///
/// > Note: The name is preserved for backward-compatibility with databases that already have
/// > this migration recorded in `_fluent_migrations` (e.g. PostgreSQL deployments that ran
/// > an earlier version of this migration successfully). Renaming would cause those databases
/// > to re-run the migration unnecessarily.
public struct MakeUserEmailOptional: AsyncMigration {

    public init() {}

    /// The canonical name recorded in the `_fluent_migrations` table.
    public var name: String { "make_user_email_optional" }

    /// Assigns synthetic guest emails to any rows with `email = ""`.
    ///
    /// New guests created after this migration already use `User.guestEmail(for:)`, so
    /// this only touches legacy data. On a fresh database with no legacy rows, this is a no-op.
    public func prepare(on database: any Database) async throws {
        let legacyGuests = try await User.query(on: database)
            .filter(\.$email == "")
            .all()

        for user in legacyGuests {
            guard let id = user.id else { continue }
            user.email = User.guestEmail(for: id)
            try await user.save(on: database)
        }
    }

    /// No-op revert. Restoring `email = ""` is intentionally unsupported because
    /// it would immediately re-introduce the UNIQUE collision that this migration fixes.
    public func revert(on database: any Database) async throws {}
}
