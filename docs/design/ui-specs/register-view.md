# UI Spec — RegisterView

## Purpose

Allows a new user to create an account with email and password. Presented by pushing
onto the `NavigationStack` inside the auth sheet, navigated to from `LoginView`.
Also handles guest upgrade when `AuthManager.authState == .guest`.

---

## Layout

`RegisterView` is a `ScrollView` containing a single `VStack` (top to bottom):

```
[Screen title]
[Spacing: spacing.lg]
[Email text field]
[Spacing: spacing.xs]
[Password text field + show/hide toggle]
[Spacing: spacing.xs]
[Confirm password text field + show/hide toggle]
[Spacing: spacing.xs]
[Inline error message — conditionally visible]
[Spacing: spacing.lg]
[Register button — full width]
[Spacing: spacing.xl]
["Already have an account? Log in" link — centred]
[Spacing: spacing.xl — bottom safe area]
```

Horizontal edge padding: `spacing.md` on both sides.
macOS: width capped at 400pt, centred.

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|-----------------|-------|
| Screen title (`Text`) | `type.title`, `color.label.primary` | `auth.register.title` | |
| Email field (`TextField`) | `type.body`, `border.field` | `auth.register.field.email.placeholder` | `keyboardType(.emailAddress)`, `textContentType(.emailAddress)`, `autocapitalization(.none)` |
| Password field (`SecureField`) | `type.body`, `border.field` | `auth.register.field.password.placeholder` | `textContentType(.newPassword)` |
| Show/hide password toggle | `eye` / `eye.slash` SF Symbol | `auth.field.password.show` / `auth.field.password.hide` | Same spec as LoginView |
| Confirm password field (`SecureField`) | `type.body`, `border.field` | `auth.register.field.confirm_password.placeholder` | `textContentType(.newPassword)` |
| Show/hide confirm password toggle | `eye` / `eye.slash` SF Symbol | `auth.field.password.show` / `auth.field.password.hide` | Same spec |
| Inline error message | `type.footnote`, `color.error` | See Error States table | Conditionally visible |
| Register button (`Button`) | Primary button component | `auth.register.button.submit` | Full width, 50pt height |
| "Already have an account? Log in" (`Button`) | `type.subhead`, `color.primary` | `auth.register.link.login` | Centred; pops `NavigationStack` to `LoginView` |

---

## States

| State | Behaviour |
|-------|-----------|
| Default | All fields empty, Register button disabled |
| Filling | Register button disabled until all three fields are non-empty |
| Ready to submit | All three fields non-empty; Register button active |
| Loading | Register button shows spinner; all fields and links disabled; keyboard dismissed |
| Error — field validation | Affected field(s) border error; inline error below field |
| Error — server | Inline error below Register button |

---

## Error States and Inline Messages

| Scenario | Key | Placement |
|----------|-----|-----------|
| Empty field | `auth.error.required` | Below the empty field |
| Invalid email format | `auth.error.email_format` | Below email field |
| Password too short (< 8 chars) | `auth.register.error.password_too_short` | Below password field |
| Passwords do not match | `auth.register.error.password_mismatch` | Below confirm-password field |
| Email already in use | `auth.register.error.email_taken` | Below email field |
| Network unavailable | `auth.error.network` | Below Register button |
| Server error | `auth.error.server` | Below Register button |

---

## Localisation Keys

| Key | Placeholder English String |
|-----|---------------------------|
| `auth.register.title` | "Create account" |
| `auth.register.field.email.placeholder` | "Email" |
| `auth.register.field.password.placeholder` | "Password" |
| `auth.register.field.confirm_password.placeholder` | "Confirm password" |
| `auth.register.button.submit` | "Register" |
| `auth.register.link.login` | "Already have an account? Log in" |
| `auth.register.error.password_too_short` | "Password must be at least 8 characters." |
| `auth.register.error.password_mismatch` | "Passwords do not match." |
| `auth.register.error.email_taken` | "An account with this email already exists." |

---

## Accessibility

- Minimum tap target: 44x44pt — all buttons meet this via height.
- Contrast ratio: WCAG AA — all system color tokens.
- Dynamic Type: `ScrollView` wrapping ensures no clipping under large text.
- VoiceOver labels:
  - Email field: `accessibilityLabel("auth.register.field.email.placeholder")`
  - Password field: `accessibilityLabel("auth.register.field.password.placeholder")`
  - Confirm-password field: `accessibilityLabel("auth.register.field.confirm_password.placeholder")`
  - Show/hide toggles: dynamic label updates as per LoginView spec
  - Register button: `accessibilityLabel("auth.register.button.submit")`
  - Inline errors: mirrors error string, `accessibilityAddTraits(.updatesFrequently)`
- Focus order: Email → Password → Confirm Password → Register → Login link.
- Keyboard: `submitLabel(.next)` on email and password fields; `submitLabel(.go)` on confirm-password field.

---

## Design Tokens Used

Same token set as `LoginView`. See `login-view.md`.

Additional tokens:
| Token | Usage |
|-------|-------|
| `spacing.xs` | Between confirm-password field and inline error |
