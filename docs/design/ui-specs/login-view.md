# UI Spec — LoginView

## Purpose

The primary entry point for authentication. Displays email/password fields, social
sign-in options, and optional guest access. Presented as the initial screen inside the
`.authSheet` bottom sheet.

---

## Layout

Sheet container fills the screen bottom-up with `.presentationDetents([.medium, .large])`.
`LoginView` is a `ScrollView` containing a single `VStack` with the following stacking
order (top to bottom):

```
[Screen title]
[Spacing: spacing.lg]
[Email text field]
[Spacing: spacing.xs]
[Password text field + show/hide toggle]
[Spacing: spacing.xs]
[Inline error message — conditionally visible]
[Spacing: spacing.sm]
["Forgot password?" link — right-aligned]
[Spacing: spacing.lg]
[Login button — full width]
[Spacing: spacing.lg]
["or" separator — full width]
[Spacing: spacing.lg]
[Sign in with Apple button — full width]
[Spacing: spacing.sm]
[Sign in with Google button — full width]
[Spacing: spacing.sm]
["Continue as Guest" button — full width — conditional on allowGuestAccess]
[Spacing: spacing.xl]
["Don't have an account? Register" link — centred]
[Spacing: spacing.xl — bottom safe area]
```

Horizontal edge padding: `spacing.md` on both sides.

On macOS, the sheet renders as a floating window panel. The same stacking order applies.
Width is capped at 400pt on macOS (centred in the panel).

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|-----------------|-------|
| Screen title (`Text`) | `type.title`, `color.label.primary` | `auth.login.title` | |
| Email field (`TextField`) | `type.body`, `border.field` | `auth.login.field.email.placeholder` | `keyboardType(.emailAddress)`, `textContentType(.emailAddress)`, `autocapitalization(.none)` |
| Password field (`SecureField`) | `type.body`, `border.field` | `auth.login.field.password.placeholder` | `textContentType(.password)`; show/hide toggle button inside field |
| Show/hide password toggle (`Button`) | `eye` / `eye.slash` SF Symbol, `color.label.secondary` | `auth.field.password.show` / `auth.field.password.hide` | Toggles between `SecureField` and `TextField`; 44x44pt tap target |
| Inline error message | `type.footnote`, `color.error` | See Error States table | Conditionally visible |
| "Forgot password?" link (`Button`) | `type.subhead`, `color.primary` | `auth.login.link.forgot_password` | Right-aligned |
| Login button (`Button`) | Primary button component | `auth.login.button.submit` | Full width, 50pt height |
| "or" separator | Divider component | `auth.separator.or` | |
| Sign in with Apple (`SignInWithAppleButton`) | Apple brand — `.black` / `.white` | System-provided | `radius.pill`, 50pt height |
| Sign in with Google (`Button`) | Google brand component | `auth.button.google` | See design-system.md for Google button spec |
| "Continue as Guest" (`Button`) | Secondary style (no background fill, `color.primary` text) | `auth.login.button.guest` | Hidden when `allowGuestAccess == false` |
| "Don't have an account? Register" (`Button`) | `type.subhead`, `color.primary` | `auth.login.link.register` | Centred; tapping pushes `RegisterView` |

---

## States

| State | Behaviour |
|-------|-----------|
| Default | All fields empty, Login button disabled (opacity 0.5) |
| Partially filled | Login button disabled until both email and password fields are non-empty |
| Ready to submit | Both fields non-empty; Login button fully active |
| Loading | Login button shows spinner; all fields and buttons disabled; keyboard dismissed |
| Error — field validation | Affected field border turns `border.field.error`; inline error message appears below field |
| Error — server | Inline error message appears below Login button (not below a field) |
| Social loading | Full-screen overlay `ProgressView` while Apple/Google server call is in flight |

---

## Error States and Inline Messages

| Scenario | Key | Placement |
|----------|-----|-----------|
| Empty email or password | `auth.error.required` | Below the empty field |
| Invalid email format | `auth.error.email_format` | Below email field |
| Invalid credentials | `auth.login.error.invalid_credentials` | Below password field |
| Network unavailable | `auth.error.network` | Below Login button |
| Server error | `auth.error.server` | Below Login button |
| Social token invalid | `auth.social.error.token_invalid` | Below Login button |

---

## Localisation Keys

| Key | Placeholder English String |
|-----|---------------------------|
| `auth.login.title` | "Welcome back" |
| `auth.login.field.email.placeholder` | "Email" |
| `auth.login.field.password.placeholder` | "Password" |
| `auth.login.button.submit` | "Log in" |
| `auth.login.link.forgot_password` | "Forgot password?" |
| `auth.login.link.register` | "Don't have an account? Register" |
| `auth.login.button.guest` | "Continue as Guest" |
| `auth.login.error.invalid_credentials` | "Incorrect email or password." |
| `auth.button.google` | "Sign in with Google" |
| `auth.button.google.accessibility` | "Sign in with Google" |
| `auth.separator.or` | "or" |
| `auth.field.password.show` | "Show password" |
| `auth.field.password.hide` | "Hide password" |
| `auth.error.required` | "This field is required." |
| `auth.error.email_format` | "Please enter a valid email address." |
| `auth.error.network` | "No internet connection. Please try again." |
| `auth.error.server` | "Something went wrong. Please try again." |
| `auth.social.error.token_invalid` | "Sign-in failed. Please try again." |

---

## Accessibility

- Minimum tap target: 44x44pt on all interactive elements. All buttons meet this via 50pt height or explicit frame modifiers.
- Contrast ratio: All text uses system color tokens guaranteed WCAG AA by Apple. `color.error` (#FF3B30) on `color.background` (white) is 4.0:1 — acceptable for 13pt footnote; verify against `color.background` in context.
- Dynamic Type: All text uses SwiftUI text styles. The `ScrollView` wrapper ensures the layout scrolls gracefully under Accessibility Large Text.
- VoiceOver labels:
  - Email field: `accessibilityLabel("auth.login.field.email.placeholder")`
  - Password field: `accessibilityLabel("auth.login.field.password.placeholder")`
  - Show/hide toggle: `accessibilityLabel` updates dynamically: `auth.field.password.show` or `auth.field.password.hide`
  - Login button: `accessibilityLabel("auth.login.button.submit")`, `accessibilityHint("auth.login.button.submit.hint")`
  - "Continue as Guest": `accessibilityLabel("auth.login.button.guest")`
  - Inline error: `accessibilityLabel` mirrors the error string; element gets `accessibilityAddTraits(.updatesFrequently)` so VoiceOver announces changes
  - Decorative divider lines: `.accessibilityHidden(true)`
- Focus order: Email → Password → Login → Forgot password → Apple → Google → Guest → Register link.
- Keyboard: `submitLabel(.next)` on email field; `submitLabel(.go)` on password field (triggers login).

---

## Design Tokens Used

| Token | Usage |
|-------|-------|
| `color.primary` | Login button background, link text color |
| `color.background` | Screen background |
| `color.surface` | Text field background |
| `color.label.primary` | Screen title, field text |
| `color.label.secondary` | Placeholder text, "or" label |
| `color.error` | Inline error text and icon, field error border |
| `color.separator` | "or" separator lines |
| `type.title` | Screen title |
| `type.body` | Field text |
| `type.button` | Login button label |
| `type.subhead` | "Forgot password?", "Register" links, "or" label |
| `type.footnote` | Inline error message |
| `type.social-button` | Google button label |
| `spacing.xs` | Between field and inline error |
| `spacing.sm` | Between social buttons |
| `spacing.md` | Horizontal edge insets |
| `spacing.lg` | Between major sections |
| `spacing.xl` | Bottom padding |
| `radius.sm` | Text field corner radius |
| `radius.md` | Login button corner radius |
| `radius.pill` | Apple and Google button corner radius |
| `border.field` | Default text field border |
| `border.field.focused` | Focused text field border |
| `border.field.error` | Error text field border |
| `border.google` | Google button border |
