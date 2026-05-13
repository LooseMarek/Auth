# ADR-003 — Non-rotating Refresh Tokens

**Date:** 2026-05-12
**Status:** Accepted
**Author:** Architect
**Deciders:** Marek Loose

---

## Context

The package must manage the full JWT token lifecycle. The key design decision is whether refresh tokens rotate on each use (the more secure model used by high-security APIs) or remain static until they expire (simpler, sufficient for personal-use apps).

---

## Decision

Refresh tokens are **non-rotating**: a single refresh token is issued at login and reused on every silent refresh until it expires. The default TTL is **1 day** (configurable). Access token default TTL is **1 hour** (configurable).

---

## Options Considered

### Option 1: Rotating refresh tokens

**Description:** Every silent refresh issues a new refresh token and invalidates the previous one. The old token is deleted from the persistence layer immediately.

**Pros:**
- Refresh token theft is detected at the next refresh attempt (reuse of an old token = stolen credential)
- Industry standard for high-security OAuth 2.0 implementations

**Cons:**
- Requires atomicity: issuing a new token and deleting the old one must succeed together, or the client and server can fall out of sync
- More complex persistence logic (must handle race conditions in multi-device scenarios)
- Overkill for single-developer personal iOS apps with no concurrent sessions

---

### Option 2: Non-rotating refresh tokens — chosen

**Description:** One refresh token per session; reused until it expires. Logout explicitly deletes it from the persistence layer.

**Pros:**
- Simple: no need for atomic token-swap logic
- No risk of client/server desync
- Sufficient security for the target use case (personal apps, single user per account)
- Configurable TTL provides expiry-based revocation

**Cons:**
- A stolen refresh token can be used until it expires (no automatic rotation-based detection)
- Not suitable for multi-user or high-security applications

---

## Rationale

Auth is a personal-use package targeting solo developer projects. The additional complexity and failure modes of rotating refresh tokens provide no meaningful security benefit for single-user personal apps. Non-rotating tokens with a 1-day TTL and explicit logout invalidation satisfy the security requirements of the target use case. Rotation can be added as a post-MVP feature if requirements change.

---

## Consequences

**Positive:**
- Simple, linear persistence logic — no atomic swap required
- No client/server desync scenarios to handle

**Negative / Trade-offs:**
- `AuthServer` is not suitable out-of-the-box for multi-user production applications without adding token rotation

**Risks:**
- Consumers building apps with more rigorous security requirements must implement rotation themselves or wait for a post-MVP feature.

---

## Related

| Type | Reference |
|------|-----------|
| Supersedes | MVP Scope Open Question #3 |
| Related ADRs | ADR-004 (Fluent persistence) |
| Related issues | — |
