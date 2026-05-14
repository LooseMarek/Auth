# CLAUDE.md — Auth

> This file is the source of truth for all agents working on this project.
> It defines the tech stack, conventions, repo structure, and agent context.
> All agents must read this file before starting any task.

---

## Project Overview

A multi-target Swift Package that gives any iOS + Vapor project email, Google, Apple, and guest authentication with a shared token lifecycle — no manual wiring required.

---

## Platforms & Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| SPM | Swift 6.2, SPM | iOS 17.0, macOS 14.0 |

---

## Repository Structure

```
Auth/
├── docs/                   # Architecture, ADRs, product, and design docs
├── Sources/
│   ├── AuthShared/         # Shared Codable request/response types and JWT metadata
│   ├── AuthClient/         # iOS/macOS SwiftUI auth views and MVVM ViewModels
│   │   ├── Resources/      # Localizable.strings for all auth UI strings
│   │   ├── ViewModels/     # @Observable ViewModels (LoginViewModel, …)
│   │   └── Views/          # SwiftUI Views (LoginView, …)
│   └── AuthServer/         # Vapor 4 auth routes, JWT middleware, Fluent models
└── Tests/
    ├── AuthSharedTests/
    ├── AuthClientTests/     # Unit tests (XCTest)
    ├── AuthClientSnapshotTests/ # Snapshot tests (swift-snapshot-testing)
    └── AuthServerTests/
```

---

## Architecture

**Pattern:** See `./docs/architecture/`

**Key ADRs:** See `./docs/architecture/`

---

## Coding Conventions

### General
- Follow language-idiomatic style for each component
- Keep functions small and focused

### Git
**Branch Naming:** `{type}/{issue-number}-{short-description}`
**Commit Style:** Conventional Commits (`feat:`, `fix:`, `test:`, `chore:`, etc.)

---

## Testing Conventions

**Approach:** TDD — write failing tests before implementing

| Component | Test Types |
|-----------|-----------|
| AuthShared | Unit (XCTest) |
| AuthClient | Unit (XCTest), Snapshot (swift-snapshot-testing) |
| AuthServer | Unit (XCTest) |

### AuthServer testing constraint

`AuthServer` does **not** depend on any Fluent driver (`fluent-sqlite-driver`, `fluent-postgres-driver`, etc.) — the host app provides the driver (see ADR-004). Therefore `AuthServerTests` must **never** add a Fluent driver as a test dependency and must **never** import `FluentSQLiteDriver` or any other driver module.

Write unit tests only: assert schema names, model initialisation, field values, and relationship IDs. Do not write migration or CRUD integration tests inside this package — those belong in the host app's test suite.


---

## Environment & Secrets

**Secret Management:** GitHub Secrets for CI/CD, `.env` files locally (not committed)
