# UX Flow — Account Deletion

## Entry Point

Programmatic — the host app calls `authManager.presentDeleteAccountFlow()` from any
context (e.g. Profile screen > Delete Account). The `.authSheet(manager:)` modifier
handles presentation.

## Steps

1. **Host app calls `authManager.presentDeleteAccountFlow()`**
   - `AuthManager` sets internal state that triggers a confirmation dialog.
   - A system `Alert` or `confirmationDialog` is presented over the current screen
     (not a full sheet navigation — it is a modal dialog).

2. **Confirmation dialog**
   - Title: `auth.delete_account.dialog.title`
   - Message: `auth.delete_account.dialog.message`
   - Destructive action: `auth.delete_account.dialog.confirm` (red / `.destructive` role)
   - Cancel action: `auth.delete_account.dialog.cancel`

3. **User cancels**
   - Dialog dismisses. No state change. Control returns to host app.

4. **User confirms deletion — loading**
   - Dialog dismisses.
   - A full-screen `ProgressView` overlay appears (applied by `AuthManager` over the
     host app's content via the `.authSheet` modifier attachment point).
   - `AuthManager` sends `DELETE /auth/account` with the current JWT.

5. **Happy path — success**
   - Server deletes user record and all associated refresh tokens.
   - `AuthManager` clears all tokens from Keychain.
   - `AuthManager.authState` set to `.unauthenticated`.
   - Loading overlay dismissed.
   - Host app reacts to state change via `@Observable`.

## Exit Points

| Exit | State left in |
|------|--------------|
| User cancels dialog | No change |
| Successful deletion | `AuthManager.authState = .unauthenticated`; Keychain cleared; server record deleted |

## Error States

| Error | Display |
|-------|---------|
| Network unavailable | Loading overlay dismissed; error `Alert` presented: title `auth.delete_account.error.title`, message `auth.error.network`; single "OK" button |
| Server error | Loading overlay dismissed; error `Alert` presented: title `auth.delete_account.error.title`, message `auth.error.server`; single "OK" button |
| Auth expired (JWT invalid) | Same as server error — the user may need to re-authenticate before deletion. Host app should ensure the user is authenticated before calling `presentDeleteAccountFlow()`. |

## Loading State

- Full-screen `ProgressView` overlay over the host app content.
- No timeout — the host app should implement a timeout at the network layer if needed.

## UI Notes

This flow does not add any new SwiftUI screens. It uses:
- A system `confirmationDialog` (SwiftUI `.confirmationDialog` modifier, not a custom view).
- A full-screen overlay `ProgressView` managed by `AuthManager`.
- A system `Alert` for error states.

All string keys must be defined in `Localizable.strings`.

## Edge Cases

- **Unauthenticated call:** If the host app calls `presentDeleteAccountFlow()` while
  `authState == .unauthenticated`, `AuthManager` should no-op and log a warning.
- **Guest deletion:** If `authState == .guest`, deletion removes the guest record from
  the server and clears Keychain. Same flow and dialog — no special-cased UI needed.
