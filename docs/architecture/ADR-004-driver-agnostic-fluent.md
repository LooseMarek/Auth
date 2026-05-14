# ADR-004 — Driver-agnostic Fluent Persistence

**Date:** 2026-05-12
**Status:** Accepted
**Author:** Architect
**Deciders:** Marek Loose

---

## Context

`AuthServer` needs to persist `User` records and `RefreshToken` records. Vapor's Fluent ORM supports multiple database drivers (Postgres, MySQL, SQLite, MongoDB). The package must decide whether to bundle a specific driver or remain driver-agnostic and let the host application supply one.

---

## Decision

`AuthServer` depends only on `vapor/fluent` (the ORM core) and defines `User` and `RefreshToken` as Fluent `Model` types. It does **not** depend on any Fluent driver. The host application is responsible for adding a driver (e.g., `fluent-postgres-driver`, `fluent-sqlite-driver`) and running migrations.

---

## Options Considered

### Option 1: Bundle a specific driver (e.g., Fluent PostgreSQL driver)

**Description:** `AuthServer` depends on `fluent-postgres-driver` and assumes PostgreSQL as the persistence layer.

**Pros:**
- Zero configuration for the most common production setup
- No ambiguity about which driver to add

**Cons:**
- Forces PostgreSQL on consumers even if they're using SQLite for development or MySQL in production
- Adds a heavy native dependency to the package that consumers cannot opt out of
- Incompatible with `fluent-sqlite-driver` for lightweight testing setups

---

### Option 2: Driver-agnostic Fluent (chosen)

**Description:** Import only `vapor/fluent`. Define Fluent models normally. The host app's `configure.swift` adds the driver and registers migrations.

**Pros:**
- Works with any Fluent-supported database
- Test environments can use `fluent-sqlite-driver` for fast, in-process tests
- Production environments can use `fluent-postgres-driver` or any other
- Package footprint is minimal — no native library binaries bundled

**Cons:**
- Consumers must add a driver dependency themselves (one extra line in Package.swift)
- Migrations must be registered by the host app, not auto-applied by the package (minor friction)

---

## Rationale

A library should not dictate infrastructure choices. A consumer running integration tests wants SQLite in-process; a production Vapor app likely wants Postgres. By depending only on the Fluent core, `AuthServer` is compatible with both without any conditional compilation. The cost — one extra SPM dependency line in the host app — is trivial.

---

## Consequences

**Positive:**
- Drop-in compatible with any Fluent driver
- Host-app test targets can freely choose `fluent-sqlite-driver` for fast, in-process runs
- `AuthServer`'s own test target stays driver-free: unit tests only (schema names, model init, field assertions) — no `fluent-sqlite-driver` or any other driver in `AuthServerTests`
- No binary blobs or native library transitive dependencies

**Negative / Trade-offs:**
- Host app must register `AuthServer`'s migrations manually (e.g., `app.migrations.add(CreateUser())`)
- The README must document the exact migration registration steps

**Risks:**
- If Fluent introduces breaking schema changes between major versions, the host app's driver version must stay in sync with `AuthServer`'s `fluent` dependency version.

---

## Related

| Type | Reference |
|------|-----------|
| Supersedes | MVP Scope Open Question #1 |
| Related ADRs | ADR-001 (multi-target SPM), ADR-003 (non-rotating refresh tokens) |
| Related issues | — |
