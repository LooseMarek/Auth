# UX Flow — Email/Password Login

## Entry Point

The host app calls `authManager.presentAuthFlow()` from any context (Profile screen,
paywall, feature gate, etc.). The `.authSheet(manager:)` modifier observes this and
presents the bottom sheet. `LoginView` is the initial screen.

The same entry point handles guest upgrade — if the current session is a guest session,
the flow continues identically from the user's perspective; the credential-attachment
logic runs transparently on the server side.

## Steps

1. **LoginView (default state)**
   - User sees: screen title, email field, password field, Login button, "Forgot password?"
     link, "Don't have an account? Register" link, "or" separator, Sign in with Apple
     button, Sign in with Google button, and optionally "Continue as Guest" button.
   - User action: taps email field, enters email address.

2. **LoginView (email entered)**
   - User taps password field, enters password.
   - "Login" button becomes active.

3. **LoginView (loading)**
   - User taps "Login".
   - Button switches to loading spinner. All fields and buttons disabled.
   - Client sends `POST /auth/login` with `LoginRequest` (email, password).

4. **Happy path — success**
   - Server returns `AuthResponse` (JWT + refresh token + expiry).
   - `AuthManager` stores tokens in Keychain, sets auth state to `.authenticated`.
   - Sheet dismisses.
   - Host app receives updated auth state via `@Observable` `AuthManager`.

## Exit Points

| Exit | State left in |
|------|--------------|
| Successful login | Sheet dismissed, `AuthManager.authState = .authenticated` |
| User swipes sheet down | Sheet dismissed, `AuthManager.authState` unchanged |
| User taps "Register" | NavigationStack pushes `RegisterView` (stays in sheet) |
| User taps "Forgot password?" | NavigationStack pushes `ForgotPasswordView` (stays in sheet) |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| Invalid credentials | Server returns 401 | Inline error below password field: `auth.login.error.invalid_credentials` |
| Network unavailable | No connection | Inline error below Login button: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below Login button: `auth.error.server` |
| Empty fields | User taps Login with blank field | Field border turns error red, inline error: `auth.error.required` |
| Invalid email format | Client-side validation | Inline error below email field: `auth.error.email_format` |

## Loading State

- Login button shows `ProgressView` spinner.
- All interactive elements disabled.
- Keyboard dismissed.

## Edge Cases

- **Guest upgrade:** When `AuthManager.authState == .guest`, the server receives the
  guest UUID alongside credentials via `POST /auth/upgrade` instead of `POST /auth/login`.
  From the user's perspective the flow is identical.
- **Already authenticated:** Host app should not call `presentAuthFlow()` when a user
  is already authenticated. `AuthManager` guards against this defensively.
