# UX Flow — Guest / Anonymous Session

## Entry Point

From `LoginView`, user taps "Continue as Guest".
This button is only visible when `AuthClientConfiguration.allowGuestAccess == true`.
When `allowGuestAccess == false`, this button is not rendered at all.

## Steps

1. **LoginView**
   - User taps "Continue as Guest" button.

2. **Loading**
   - Button switches to loading spinner, all other interactive elements disabled.
   - `AuthManager` sends `POST /auth/guest` with `GuestAuthRequest`.
   - Server generates a new UUID, issues a JWT, returns `AuthResponse`.

3. **Happy path — success**
   - `AuthManager` stores guest JWT in Keychain.
   - `AuthManager.authState` set to `.guest` with the UUID.
   - Auth sheet dismisses.
   - Host app receives updated auth state via `@Observable`.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful guest sign-in | Sheet dismissed, `AuthManager.authState = .guest(uuid:)` |
| User swipes sheet down | Sheet dismissed, `AuthManager.authState` unchanged |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| Network unavailable | No connection | Inline error below "Continue as Guest" button: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below button: `auth.error.server` |

## Loading State

- "Continue as Guest" button shows `ProgressView` spinner.
- All other interactive elements disabled.
- No network progress bar — the guest endpoint is fast.

## Edge Cases

- **`allowGuestAccess == false`:** The "Continue as Guest" button is not rendered.
  No code path exists for the user to reach this flow. The guest `POST /auth/guest`
  endpoint is still available on the server; only the UI entry point is hidden.
- **UUID persistence:** The guest UUID returned in `AuthResponse.userId` is the
  user's stable identifier. It is stored in Keychain alongside the JWT so it
  persists across app launches during the guest session.
- **Repeated launches:** If the user already has a valid guest JWT in Keychain,
  `AuthManager` restores the `.guest` state on app launch without presenting the
  sheet again. The host app drives this via `AuthManager.authState`.
