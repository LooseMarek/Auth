# UX Flow — Forgot Password

This flow spans two screens: `ForgotPasswordView` (request reset email) and
`ResetPasswordView` (apply new password with the token received by email).

## Entry Point

From `LoginView`, user taps the "Forgot password?" link.
The `NavigationStack` inside the sheet pushes `ForgotPasswordView`.

---

## Part 1 — ForgotPasswordView

### Steps

1. **ForgotPasswordView (default state)**
   - User sees: screen title, explanatory subheading, email field, "Send reset link"
     button, "Back to log in" link.

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
     body `auth.forgot.success.body`.
   - Two actions available: "Enter reset token" button (proceeds to `ResetPasswordView`)
     and "Back to log in" link (returns to `LoginView`).

5. **User proceeds to ResetPasswordView**
   - User taps "Enter reset token".
   - `NavigationStack` pushes `ResetPasswordView`.

### Exit Points (ForgotPasswordView)

| Exit | State left in |
|------|--------------|
| Success → "Enter reset token" | Pushes `ResetPasswordView` |
| Success → "Back to log in" | `NavigationStack` pops to `LoginView` |
| "Back to log in" link (before sending) | `NavigationStack` pops to `LoginView` |
| User swipes sheet down | Sheet dismissed, no auth state change |

### Error States (ForgotPasswordView)

| Error | Trigger | Display |
|-------|---------|---------|
| Invalid email format | Client-side | Inline error below email field: `auth.error.email_format` |
| Empty field | Tapped Send with blank field | Inline error below field: `auth.error.required` |
| Network unavailable | No connection | Inline error below button: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below button: `auth.error.server` |

> The server always returns 200 for a well-formed email address whether or not the
> address is registered. This prevents user enumeration. No "email not found" error
> is shown to the user.

### Loading State

- "Send reset link" button shows `ProgressView` spinner.
- Email field and button disabled.
- Keyboard dismissed.

---

## Part 2 — ResetPasswordView

### Steps

6. **ResetPasswordView (default state)**
   - User sees: screen title, subtitle, reset token field, new password field,
     confirm password field, "Reset password" button (disabled), "Back to log in" link.

7. **ResetPasswordView (fields filled)**
   - User enters the reset token from the email.
   - User enters a new password (≥8 characters) in both fields.
   - "Reset password" button activates once token is non-empty and passwords match.

8. **ResetPasswordView (loading)**
   - User taps "Reset password".
   - Button switches to loading spinner; all fields disabled.
   - Client sends `POST /auth/reset-password` with `ResetPasswordRequest` (token, newPassword).

9. **Happy path — success state**
   - Server validates token and updates the password, returning 200.
   - View transitions to success card.
   - Success card displayed: checkmark icon, title `auth.reset.success.title`,
     body `auth.reset.success.body`, "Back to log in" button.

10. **User returns to LoginView**
    - User taps "Back to log in" button in the success card (or the link in the form).
    - The `dismissToRoot` closure fires — pops both `ResetPasswordView` and
      `ForgotPasswordView` — returning directly to `LoginView`.

### Exit Points (ResetPasswordView)

| Exit | State left in |
|------|--------------|
| Success → "Back to log in" button | Pops to `LoginView` (via `dismissToRoot`) |
| "Back to log in" link (before submitting) | Pops to `LoginView` (via `dismissToRoot`) |
| User swipes sheet down | Sheet dismissed, no auth state change |

### Error States (ResetPasswordView)

| Error | Trigger | Display |
|-------|---------|---------|
| Invalid / expired token | Server returns 400 | Inline error below token field: `auth.error.invalid_reset_token` |
| Network unavailable | No connection | Inline error below token field: `auth.error.network` |
| Server error | Server returns 5xx | Inline error below token field: `auth.error.server` |

Client-side validation (prevents submission before network call):

| Error | Condition |
|-------|-----------|
| Passwords do not match | `auth.reset.error.password_mismatch` — shown as disabled button |
| Password too short | `auth.reset.error.password_too_short` — shown as disabled button |

---

## Edge Cases

- **User navigates back before success (ForgotPasswordView):** `NavigationStack` pop
  gesture is allowed — user returns to `LoginView` without any state change.
- **Reset link email delivery:** Handled server-side via the injected email transport
  closure. `ForgotPasswordView` has no knowledge of the email transport mechanism.
- **Token already used or expired:** Server returns 400 (`invalidResetToken`); the error
  is displayed inline. The user must return to `ForgotPasswordView` and request a new link.
- **"Back to log in" pops to root:** `ResetPasswordView` receives `ForgotPasswordView`'s
  `dismiss` closure as `dismissToRoot`. Invoking it dismisses both screens, landing on
  `LoginView` — not `ForgotPasswordView`.
