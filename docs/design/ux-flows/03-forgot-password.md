# UX Flow — Forgot Password

## Entry Point

From `LoginView`, user taps the "Forgot password?" link.
The `NavigationStack` inside the sheet pushes `ForgotPasswordView`.

## Steps

1. **ForgotPasswordView (default state)**
   - User sees: screen title, explanatory subheading, email field, "Send reset link"
     button, "Back to login" link.

2. **ForgotPasswordView (email entered)**
   - User taps email field, enters email address.
   - "Send reset link" button activates.

3. **ForgotPasswordView (loading)**
   - User taps "Send reset link".
   - Client validates email format.
   - Button switches to loading spinner, field and button disabled.
   - Client sends `POST /auth/forgot-password` with `ForgotPasswordRequest` (email).

4. **Happy path — success state**
   - Server returns 200 (regardless of whether the email exists — prevents enumeration).
   - View transitions to success state.
   - Success state card displayed: checkmark icon, title `auth.forgot.success.title`,
     body `auth.forgot.success.body`, "Back to login" button.

5. **User returns to LoginView**
   - User taps "Back to login" button in success state.
   - `NavigationStack` pops to `LoginView`.

## Exit Points

| Exit | State left in |
|------|--------------|
| Success → "Back to login" | `NavigationStack` pops to `LoginView` |
| "Back to login" link (before sending) | `NavigationStack` pops to `LoginView` |
| User swipes sheet down | Sheet dismissed, no auth state change |

## Error States

| Error | Trigger | Display |
|-------|---------|---------|
| Invalid email format | Client-side | Inline error below email field: `auth.error.email_format` |
| Empty field | Tapped Send with blank field | Inline error below field: `auth.error.required` |
| Network unavailable | No connection | Inline error below button: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below button: `auth.error.server` |

> The server always returns 200 for a well-formed email address whether or not the
> address is registered. This prevents user enumeration. No "email not found" error
> is shown to the user.

## Loading State

- "Send reset link" button shows `ProgressView` spinner.
- Email field and button disabled.
- Keyboard dismissed.

## Edge Cases

- **User navigates back before success:** `NavigationStack` pop gesture is allowed —
  user returns to `LoginView` without any state change.
- **Reset link email delivery:** Handled server-side via the injected email transport
  closure. `ForgotPasswordView` has no knowledge of the email transport mechanism.
