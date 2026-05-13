# UX Flow — Email/Password Registration

## Entry Point

From `LoginView`, user taps the "Don't have an account? Register" link.
The `NavigationStack` inside the sheet pushes `RegisterView`.

## Steps

1. **RegisterView (default state)**
   - User sees: screen title, email field, password field, confirm-password field,
     "Register" button, "Already have an account? Log in" back link.
   - User action: taps email field, enters email address.

2. **RegisterView (filling form)**
   - User taps password field, enters password.
   - User taps confirm-password field, enters password again.
   - "Register" button activates when all three fields are non-empty.

3. **RegisterView (loading)**
   - User taps "Register".
   - Client validates: email format, password minimum length (defined server-side;
     client enforces a minimum of 8 characters), passwords match.
   - If validation passes: button switches to loading spinner, all fields disabled.
   - Client sends `POST /auth/register` with `RegisterRequest` (email, password).

4. **Happy path — success**
   - Server returns `AuthResponse`.
   - `AuthManager` stores tokens, sets auth state to `.authenticated`.
   - Sheet dismisses.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful registration | Sheet dismissed, `AuthManager.authState = .authenticated` |
| User taps "Log in" back link | `NavigationStack` pops to `LoginView` |
| User swipes sheet down | Sheet dismissed, `AuthManager.authState` unchanged |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| Email already in use | Server returns 409 | Inline error below email field: `auth.register.error.email_taken` |
| Password too short | Client-side (< 8 chars) | Inline error below password field: `auth.register.error.password_too_short` |
| Passwords do not match | Client-side comparison | Inline error below confirm-password field: `auth.register.error.password_mismatch` |
| Invalid email format | Client-side | Inline error below email field: `auth.error.email_format` |
| Empty fields | Tapped Register with blank field | Field border error, inline error: `auth.error.required` |
| Network unavailable | No connection | Inline error below Register button: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below Register button: `auth.error.server` |

## Loading State

- Register button shows `ProgressView` spinner.
- All interactive elements disabled.
- Keyboard dismissed.

## Edge Cases

- **Guest upgrade path:** If the session is guest, `POST /auth/upgrade` is called instead
  of `POST /auth/register`. The UI flow and fields are identical.
- **Password visibility toggle:** Both password fields include a show/hide toggle
  (eye icon) so users can verify what they typed.
