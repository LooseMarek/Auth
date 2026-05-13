# ADR-002 — @Observable and iOS 17.0 Deployment Target

**Date:** 2026-05-12
**Status:** Accepted
**Author:** Architect
**Deciders:** Marek Loose

---

## Context

`AuthClient` needs a ViewModel layer to back its SwiftUI views (`LoginView`, `RegisterView`, `ForgotPasswordView`). Swift offers two ViewModel observation mechanisms: the legacy `ObservableObject` protocol (iOS 14+) and the new `@Observable` macro (iOS 17+, Swift 5.9). The MVP scope originally declared iOS 16+ as the deployment target.

---

## Decision

Use the `@Observable` macro for all `AuthClient` ViewModels. Bump the `AuthClient` deployment target (and therefore the package-level iOS minimum) from **iOS 16.0** to **iOS 17.0**.

---

## Options Considered

### Option 1: MVVM with `ObservableObject` (iOS 16.0 target, unchanged)

**Description:** ViewModels conform to `ObservableObject`; properties marked `@Published`. Views use `@StateObject` / `@EnvironmentObject`.

**Pros:**
- Preserves iOS 16 support (wider device compatibility)
- Mature, well-understood pattern with extensive community examples

**Cons:**
- `@Published` boilerplate on every observable property
- Coarser re-renders: any `@Published` change triggers full view re-evaluation
- Being phased out in favour of `@Observable` in the Swift ecosystem

---

### Option 2: MVVM with `@Observable` (iOS 17.0 target) — chosen

**Description:** ViewModels use the `@Observable` macro. No `@Published` annotations needed. Views use plain `@State` for owned ViewModels.

**Pros:**
- Cleaner syntax — no `@Published`, no `@StateObject`/`@ObservedObject` distinction
- Fine-grained re-renders: only properties actually read by a view body trigger updates
- Aligns with Apple's recommended direction for SwiftUI apps going forward
- Swift 6 + `@Observable` interact well with `Sendable` requirements

**Cons:**
- Requires iOS 17.0+ — drops iOS 16 support
- Newer pattern with slightly less Stack Overflow coverage

---

## Rationale

The primary consumer is a solo iOS + Vapor developer working on personal projects. iOS 17 adoption has been high since its 2023 release and is not a meaningful constraint for this use case. The `@Observable` macro reduces boilerplate and future-proofs `AuthClient` against Apple's continued investment in this API. The trade-off (dropping iOS 16) is acceptable given the target audience.

---

## Consequences

**Positive:**
- Simpler ViewModel code; easier to maintain and extend
- Better performance via fine-grained observation
- Package stays aligned with modern SwiftUI idioms

**Negative / Trade-offs:**
- Consumers whose apps target iOS 16 cannot use `AuthClient`; they would need to import only `AuthShared` and `AuthServer`, and build their own iOS client layer

**Risks:**
- If a future consumer requires iOS 16 support, `AuthClient` would need to be refactored to `ObservableObject` or offer a compatibility shim.

---

## Related

| Type | Reference |
|------|-----------|
| Supersedes | MVP Scope constraint "iOS 16+" |
| Related ADRs | ADR-001 (multi-target SPM) |
| Related issues | — |
