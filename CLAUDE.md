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

**Always provide snapshots for both platforms.** Every snapshot test must cover iOS (`UIHostingController`) and macOS (`NSHostingView`) — CI runs separate pipelines for each via `fastlane ios test` and `fastlane mac test`.

**macOS snapshots require `perceptualPrecision: 0.95`.** The CI runner is an Intel MacBook Pro (2018) while development happens on Apple Silicon. Even identical solid-colour views produce a sub-perceptual colour delta between the two due to display colour-space differences. Use:
```swift
assertSnapshot(of: hostingView, as: .image(perceptualPrecision: 0.95), named: "customTheme-macOS")
```

**iOS snapshots require `perceptualPrecision: 0.98`.** The CI runner is self-hosted and may run a different iOS simulator version than the local machine. Minor differences in SF Symbol rendering, text antialiasing, or colour profiles between iOS versions cause exact-match failures. Use:
```swift
assertSnapshot(of: hostingController.view, as: .image(perceptualPrecision: 0.98), named: "customTheme-iOS")
```

**Design snapshot test views to be cross-architecture stable.** Prefer solid `Rectangle().fill(color)` blocks over elements that involve hardware-specific rendering:
- No `LinearGradient` — Metal interpolates gradients differently on Intel vs Apple Silicon.
- No `.cornerRadius()` — GPU anti-aliasing at rounded edges differs between architectures.
- No `Text` — subpixel antialiasing is present on Intel but absent on Apple Silicon.

**Record snapshot references locally via Fastlane, not `swift test`.** `swift test` renders macOS views using the display's backing scale (2× Retina locally, 1× headless), causing scale mismatches on CI. Always record with:
```
bundle exec fastlane mac test   # records at 2× via xcodebuild, matching CI
bundle exec fastlane ios test   # records against the configured simulator
```
Run once to auto-record (test fails), then run again to confirm (test passes), then commit the reference images.

**Commit reference images alongside the test code.** Never push a snapshot test without its reference `.png` files — CI has no way to auto-commit them back to the repo.

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

The same `#if canImport(UIKit)` / `#else` pattern applies for all adaptive colours in `AuthColors` inside `LoginView.swift`.

---

### macOS SwiftUI text field styling

On macOS, `TextField` and `SecureField` default to `roundedBorder` style, which draws a native inner border/background. When wrapping a field in a custom `background` + `clipShape` container (the pattern used for our `color.surface` fields), this causes a "container inside container" appearance. Fix: add `.textFieldStyle(.plain)` to remove the native decoration before applying custom styling.

```swift
TextField("Email", text: $email)
    .textFieldStyle(.plain)   // removes native macOS border
    .padding(.horizontal, 16)
    .frame(height: 52)
    .background(AuthColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 8))
```
### AuthServer testing constraint

`AuthServer` does **not** depend on any Fluent driver (`fluent-sqlite-driver`, `fluent-postgres-driver`, etc.) — the host app provides the driver (see ADR-004). Therefore `AuthServerTests` must **never** add a Fluent driver as a test dependency and must **never** import `FluentSQLiteDriver` or any other driver module.

Write unit tests only: assert schema names, model initialisation, field values, and relationship IDs. Do not write migration or CRUD integration tests inside this package — those belong in the host app's test suite.


---

## Environment & Secrets

**Secret Management:** GitHub Secrets for CI/CD, `.env` files locally (not committed)
