# UX Flow — Guest Upgrade

## Entry Point

The host app calls `authManager.presentAuthFlow()` while `AuthManager.authState == .guest`.
The `.authSheet(manager:)` modifier presents the bottom sheet with `LoginView`.

The host app does not need to use a different API call to trigger guest upgrade — the
standard `presentAuthFlow()` method is the same entry point. `AuthManager` transparently
detects the guest state and routes the server request to `POST /auth/upgrade` instead of
the standard login/register/social endpoints.

## Steps

1. **LoginView (guest upgrade context)**
   - Screen looks identical to the standard login screen.
   - No special "upgrade" messaging is shown on `LoginView` — the upgrade happens
     transparently. The host app may display upgrade-prompting messaging in its own UI
     before calling `presentAuthFlow()`.
   - User chooses a sign-in method: email/password login, Register, Sign in with Apple,
     Sign in with Google.

2. **User completes chosen auth flow**
   - See individual flow docs (01, 02, 04, 05) for step-by-step detail.
   - When the server call is made, `AuthManager` detects guest state and sends the
     guest UUID alongside credentials to `POST /auth/upgrade`.

3. **Happy path — success**
   - Server attaches credentials to the existing guest UUID.
   - Returns updated `AuthResponse` for the same UUID.
   - `AuthManager` replaces guest tokens with full auth tokens.
   - `AuthManager.authState` transitions from `.guest` to `.authenticated`.
   - Sheet dismisses.
   - No app data is lost — the UUID did not change.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful upgrade | Sheet dismissed, `AuthManager.authState = .authenticated` (same UUID) |
| User swipes sheet down | Sheet dismissed, `AuthManager.authState = .guest` (unchanged) |

## Error States

Same as the individual auth flows (01, 02, 04, 05). No additional error states specific
to guest upgrade — if the upgrade endpoint fails, the error is surfaced in `LoginView`
using the same inline error components.

| Error | Display |
|-------|---------|
| Network unavailable | Inline error: `auth.error.network` |
| Server error | Inline error: `auth.error.server` |
| Invalid credentials | Inline error: `auth.login.error.invalid_credentials` |

## Edge Cases

- **UUID collision:** Handled server-side. `POST /auth/upgrade` is idempotent for the
  same UUID + provider combination.
- **Already upgraded:** If the user already upgraded and is fully authenticated,
  `AuthManager` should not present the auth sheet for upgrade. Host app should check
  `AuthManager.authState` before calling `presentAuthFlow()`.
- **Guest token expiry:** If the guest JWT has expired, `AuthManager` will need to
  silently re-issue a guest token before proceeding with the upgrade, or prompt the
  user to begin a fresh session. This is an implementation-level concern; no distinct
  UX screen is needed — the auth sheet is presented and the user proceeds normally.
