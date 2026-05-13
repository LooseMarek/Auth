# ADR-001 — Multi-target SPM Structure

**Date:** 2026-05-12
**Status:** Accepted
**Author:** Architect
**Deciders:** Marek Loose

---

## Context

Auth must provide shared Codable models, an iOS SwiftUI client layer, and a Vapor server layer to consumer projects. The question is how to package these three concerns so that an iOS host project can import just the client layer and a Vapor host project can import just the server layer — without both sides dragging in each other's dependencies (e.g., a Vapor server importing GoogleSignIn-iOS).

---

## Decision

Adopt a three-target multi-target SPM package:

- **`AuthShared`** — shared Codable request/response types; no dependencies; usable by both iOS and Vapor consumers.
- **`AuthClient`** — iOS + macOS SwiftUI views, ViewModels, direct Keychain storage (Security framework); depends on `AuthShared` + client-only packages.
- **`AuthServer`** — Vapor 4 routes, JWT middleware, Fluent models; depends on `AuthShared` + Vapor packages.

A fourth **`AuthKit`** umbrella library product re-exports all three for consumers that want a single-import drop-in.

---

## Options Considered

### Option 1: Single-target package

**Description:** One `Auth` target containing all code, guarded by `#if canImport(UIKit)` / `#if canImport(Vapor)` compile conditions throughout.

**Pros:**
- Simpler Package.swift
- Only one Swift module for consumers to import

**Cons:**
- All dependencies (GoogleSignIn, Vapor, Fluent) are pulled in by every consumer regardless of need
- Compile conditions scattered throughout the codebase are hard to maintain
- A Vapor server importing the package would attempt to resolve GoogleSignIn-iOS, which has no Linux support

---

### Option 2: Multi-target package (chosen)

**Description:** Three distinct targets with explicit dependency graphs. Each consumer imports only what it needs.

**Pros:**
- Dependency isolation: iOS consumers never see Vapor symbols; Vapor servers never see UIKit/GoogleSignIn symbols
- Clean API boundaries enforced by the compiler
- Models can be shared without duplication

**Cons:**
- Slightly more complex Package.swift (three products, three test targets)
- Consumers must know which product to import (`AuthClient` vs `AuthServer` vs `AuthKit`)

---

### Option 3: Separate packages (Auth-iOS + Auth-Vapor)

**Description:** Two independent GitHub repositories sharing models via a third `AuthShared` package.

**Pros:**
- Completely independent versioning and release cycles
- No cross-platform complexity in a single Package.swift

**Cons:**
- Three repos to maintain and version-pin together
- A breaking model change requires coordinated releases across two packages
- Adds friction for the primary use case: the full-stack solo developer who uses both

---

## Rationale

Multi-target within a single package gives clean dependency isolation without the overhead of coordinating multiple repositories. The umbrella `AuthKit` product preserves the "one import" convenience for full-stack consumers. This is the standard approach used by the Swift on Server ecosystem (e.g., `vapor/jwt` offering separate client and server targets in one package).

---

## Consequences

**Positive:**
- iOS consumers import `AuthClient`; Vapor consumers import `AuthServer`; full-stack consumers import `AuthKit`
- Models are shared by reference (same binary, no DTO translation layer)
- Single version pin covers the entire auth surface

**Negative / Trade-offs:**
- Package.swift is more complex than a single-target package
- Linux CI must only compile `AuthShared` + `AuthServer` (not `AuthClient`)

**Risks:**
- Accidental import of `AuthClient` in a Linux Vapor server will fail at compile time — clear enough to diagnose, but a gotcha for first-time consumers.

---

## Related

| Type | Reference |
|------|-----------|
| Supersedes | — |
| Related ADRs | ADR-004 (driver-agnostic Fluent) |
| Related issues | — |
