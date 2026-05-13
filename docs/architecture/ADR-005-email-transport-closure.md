# ADR-005 — Email Transport as Injected Async Closure

**Date:** 2026-05-12
**Status:** Accepted
**Author:** Architect
**Deciders:** Marek Loose

---

## Context

`AuthServer`'s `POST /auth/forgot-password` endpoint must send a password-reset email. Sending email from Swift requires either a bundled SMTP library or an HTTP call to a third-party email API. The package must decide how to provide this capability without introducing a hard dependency on a specific email service or SMTP client.

---

## Decision

Email delivery is provided via a **pure Swift async closure** injected at configure time:

```swift
typealias EmailTransport = (_ recipient: String, _ subject: String, _ body: String) async throws -> Void
```

The host application supplies this closure in `AuthServer.configure(emailTransport:)`. No default transport is bundled. The `forgot-password` route simply calls the closure; it has no knowledge of how the email is actually delivered.

---

## Options Considered

### Option 1: Bundle an SMTP library (e.g., `vapor/smtp` or `Swiftmailer`)

**Description:** Add a Swift SMTP client as a dependency; provide a built-in email sender.

**Pros:**
- Zero configuration for consumers who just want SMTP to work
- Self-contained: no external service account required for basic use

**Cons:**
- No mature, widely-adopted Swift SMTP library exists as of 2026
- Forces a specific transport mechanism on all consumers
- SMTP authentication configuration (host, port, TLS, credentials) becomes part of `AuthServer`'s API surface
- Consumers using Mailgun, SendGrid, SES, Postmark, etc. would need to work around the bundled library

---

### Option 2: Injected async closure (chosen)

**Description:** Accept the email sending function as a closure parameter at configure time. The package calls it; the consumer implements it.

**Pros:**
- No email dependency in the package at all — zero transitive dependencies for email
- Works with any delivery mechanism: SMTP, Mailgun HTTP API, AWS SES SDK, a mock in tests, a simple `print()` for development
- Interface is the smallest possible surface: three strings in, `throws` out
- Completely testable: pass a closure that captures sent emails into an array

**Cons:**
- The consumer must implement the closure (even if it's just `{ _, _, _ in }` for a dev environment)
- No "it just works" experience — requires a few lines of wiring

---

### Option 3: Leave email as a no-op / TODO

**Description:** `forgot-password` writes the reset token to the response body (dev mode) and relies on the consumer to handle sending.

**Pros:**
- No configuration required at all

**Cons:**
- Exposes a reset token in an HTTP response — security risk
- Not a usable implementation; shifts the entire email problem to the consumer

---

## Rationale

The injected closure pattern is the standard Swift dependency injection idiom. It imposes no transitive dependencies, is trivially testable, and gives the consumer complete control over the delivery mechanism. The cost (a few lines of configure code) is minimal and explicitly documented in the README. This is the same pattern Vapor itself uses for lifecycle hooks and middleware.

---

## Consequences

**Positive:**
- `AuthServer` has no email-related dependencies
- Consumers can switch email providers without touching the package
- Integration tests for `forgot-password` can verify the reset token without sending real emails

**Negative / Trade-offs:**
- First-time setup requires the consumer to wire up the closure; the README must include a working example (e.g., using `vapor/smtp` or a Mailgun HTTP call)

**Risks:**
- If a consumer forgets to supply the closure and calls `forgot-password`, the route must fail gracefully with a 500 rather than silently dropping the email.

---

## Related

| Type | Reference |
|------|-----------|
| Supersedes | MVP Scope Open Question #2 |
| Related ADRs | ADR-001 (multi-target SPM) |
| Related issues | — |
