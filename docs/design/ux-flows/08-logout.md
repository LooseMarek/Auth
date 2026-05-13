# UX Flow — Logout

## Entry Point

Programmatic — the host app calls `authManager.logout()` from any context (e.g. Profile
screen settings, menu item). There is no auth-sheet UI for logout.

## Steps

1. **Host app calls `authManager.logout()`**
   - `AuthManager` sends `POST /auth/logout` with the current refresh token.
   - Server invalidates the refresh token in the persistence layer.

2. **Happy path — success**
   - `AuthManager` clears all tokens from Keychain.
   - `AuthManager.authState` set to `.unauthenticated`.
   - Host app reacts to the state change via `@Observable`.

3. **Host app responds**
   - The host app is responsible for navigating the user back to an appropriate screen
     (e.g. onboarding or welcome screen). `AuthManager` only manages state — it does
     not control navigation.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful logout | `AuthManager.authState = .unauthenticated`; Keychain cleared |

## Error States

| Error | Handling |
|-------|---------|
| Network unavailable | Tokens cleared from Keychain locally regardless. Auth state set to `.unauthenticated`. Server invalidation is best-effort; tokens will expire via TTL. |
| Server error | Same as network unavailable — local Keychain is cleared and state reset. The logout is considered successful from the user's perspective. |

> Logout must always succeed locally. A server-side failure must not block the user
> from being signed out in the app.

## UI Notes

No dedicated SwiftUI screen is needed for logout. The host app drives the UX
(confirmation alert, loading state, etc.) using standard SwiftUI patterns. `AuthManager`
exposes an `async` `logout()` method the host app awaits.

## Edge Cases

- **Guest logout:** Calling `logout()` while in `.guest` state also clears the guest
  JWT and UUID from Keychain. Auth state resets to `.unauthenticated`. No server call
  is needed for guest logout — guest sessions are server-side stateless by design
  (guest tokens are short-lived JWTs with no refresh token to invalidate). The
  implementation should call `POST /auth/logout` only when a refresh token is present.
