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
├── docs/               # Architecture, ADRs, product, and design docs
```

> Add component folders here as they are created.

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
| AuthServer | Unit (XCTest) |

### Snapshot Testing

**Two-arch workflow.** Snapshots are split by CPU architecture so M4 development machines and Intel CI never compare against each other's baselines:

- `arm64` suffix — recorded on Apple Silicon (M4), committed by agents
- `x86_64` suffix — recorded on Intel CI runner, committed by the snapshot-commit pipeline

Add this block at the top of every snapshot test file:

```swift
#if arch(arm64)
private let snapshotArch = "arm64"
#else
private let snapshotArch = "x86_64"
#endif
```

Then use it in every `assertSnapshot` call:

```swift
assertSnapshot(of: hostingView, as: .image, named: "macOS-\(snapshotArch)")
assertSnapshot(of: controller.view, as: .image, named: "iOS-\(snapshotArch)")
```

No `perceptualPrecision` needed — each architecture compares only against its own baselines.

**Always provide snapshots for both platforms.** Every snapshot test must cover iOS (`UIHostingController`) and macOS (`NSHostingView`).

**Agent workflow:**
1. Write the test. Run locally — missing `arm64` references are auto-recorded on first run (test fails with "Recorded snapshot"), pass on the second run.
2. Commit both the test code and the `arm64` `.png` files alongside it.
3. Open the PR. CI fails: `x86_64` references are missing.
4. Reviewer triggers **Record Snapshots (iOS/macOS)** pipeline, inspects artifacts, then triggers **Commit Snapshots** to write `x86_64` references back to the branch. CI goes green.

**Record locally via Fastlane, not `swift test`.** `swift test` renders macOS views using the display's backing scale (2× Retina locally, 1× headless), causing scale mismatches against CI. Always record with:
```
bundle exec fastlane mac test   # records macOS at 2× via xcodebuild
bundle exec fastlane ios test   # records against the configured simulator
```

---

## Living Document

**Every task that encounters a non-obvious problem with a clear solution must update this file.** If an agent hits a recurring pitfall — a build configuration quirk, a platform gotcha, a tooling workaround — and identifies a definitive fix, add a concise note to the relevant section before closing the PR. This prevents future agents from re-discovering the same issues.

---

### Adaptive colours in AuthClientConfiguration

`AuthClientConfiguration` stores `Color` values for `primaryColor` and `backgroundColor`. These default to Auth Blue and the system background — both of which must adapt to light and dark mode.

Swift does **not** allow `internal` or `fileprivate` statics as default parameter values in `public init`s (the default expression would be inaccessible to callers). The fix: use `Color?` parameters in the `public init` (nil = use adaptive default) and resolve the adaptive `Color` inside the init body via a `private static let`. The stored properties remain `Color` (non-optional).

Pattern:
```swift
public init(primaryColor: Color? = nil, ...) {
    self.primaryColor = primaryColor ?? Self.adaptivePrimaryColor
}
#if canImport(UIKit)
private static let adaptivePrimaryColor = Color(uiColor: UIColor { ... })
#else
private static let adaptivePrimaryColor = Color(nsColor: NSColor(name: nil) { ... })
#endif
```

The same `#if canImport(UIKit)` / `#else` pattern applies for all adaptive colour defaults in `AuthTheme` (e.g. `defaultSurfaceColor(isDark:)`).

---

### macOS SwiftUI text field styling

On macOS, `TextField` and `SecureField` default to `roundedBorder` style, which draws a native inner border/background. When wrapping a field in a custom `background` + `clipShape` container (the pattern used for our `color.surface` fields), this causes a "container inside container" appearance. Fix: add `.textFieldStyle(.plain)` to remove the native decoration before applying custom styling.

```swift
TextField("Email", text: $email)
    .textFieldStyle(.plain)   // removes native macOS border
    .padding(.horizontal, 16)
    .frame(height: 52)
    .background(theme.surfaceColor)
    .clipShape(RoundedRectangle(cornerRadius: 8))
```
### Localisation — SPM bundle access and defaultLocalization

SPM requires `defaultLocalization: "en"` in `Package.swift` the moment any `.lproj` folder is added to a processed resource directory. Without it, `swift build` / `swift test` fail with `manifest property 'defaultLocalization' not set`.

All user-facing strings in `AuthClient` are externalised to `Sources/AuthClient/Resources/en.lproj/Localizable.strings`. Access them in views with:

```swift
String(localized: "auth.login.title", bundle: .module)
```

Do **not** use `NSLocalizedString` — it defaults to the main bundle and will not find the SPM module's strings in host apps.

Key convention: `auth.{screen}.{element}` (e.g. `auth.login.title`, `auth.register.error.password_too_short`). The full key inventory lives in `docs/design/ui-specs/`.

**Snapshot re-recording after string changes.** Replacing inline strings with localised lookups changes the rendered placeholder text (e.g. `"Email"` → `"you@email.com"`), which invalidates all existing arm64 baselines. When this happens:
1. Delete the stale arm64 `.png` files for each affected snapshot folder.
2. Re-record via Fastlane: `bundle exec fastlane ios test` then `bundle exec fastlane mac test`.
3. Run each Fastlane lane a second time — first run records, second run verifies.
4. Do **not** use `swift test` to record macOS baselines — it renders at display backing scale, producing files that mismatch Fastlane-recorded CI baselines.

### AuthServer testing constraint

`AuthServer` does **not** depend on any Fluent driver (`fluent-sqlite-driver`, `fluent-postgres-driver`, etc.) — the host app provides the driver (see ADR-004). Therefore `AuthServerTests` must **never** add a Fluent driver as a test dependency and must **never** import `FluentSQLiteDriver` or any other driver module.

Write unit tests only: assert schema names, model initialisation, field values, and relationship IDs. Do not write migration or CRUD integration tests inside this package — those belong in the host app's test suite.


### SnapshotTesting must not be a production AuthClient dependency

`SnapshotTesting` (from swift-snapshot-testing) must only appear as a dependency of **test targets** (`AuthClientSnapshotTests`), never of the production `AuthClient` target. If added to the production target, host apps that link `AuthClient` will fail to link because `SnapshotTesting` references Swift Testing framework symbols (`Testing.Trait`, `Testing.SourceLocation`, etc.) that are unavailable in app bundles.

Correct placement in `Package.swift`:
```swift
// WRONG — causes linker failures in host apps:
.target(name: "AuthClient", dependencies: [..., .product(name: "SnapshotTesting", ...)], ...)

// CORRECT — only in the snapshot test target:
.testTarget(name: "AuthClientSnapshotTests", dependencies: [..., .product(name: "SnapshotTesting", ...)], ...)
```

---

## Environment & Secrets

**Secret Management:** GitHub Secrets for CI/CD, `.env` files locally (not committed)
