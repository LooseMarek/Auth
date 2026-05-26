# UI Spec — LoginView

**Version:** 2.0 · **Date:** 2026-05-15

## Purpose

The primary entry point for authentication. Displays email/password fields,
social sign-in options, and optional guest access. Presented as the initial
screen inside the `.authSheet` bottom sheet.

See `../design-system.md` for the token vocabulary used below, and
`../Auth Views Demo.html` for every state rendered.

---

## Layout

`LoginView` is a `ScrollView` containing a single `VStack` (top to bottom):

```
[Screen title — type.title.lg]
[Subtitle  — type.callout, color.label.secondary]    space.xs below title
[Space: space.lg]
[Email text field]
[Space: 14pt]
[Password text field + eye/eye.slash toggle]
[Space: space.xxs]  (only when error present)
[Inline error message — conditional]
[Space: 4pt]
["Forgot password?" link — right-aligned, type.subhead, color.primary]
[Space: space.lg]
[Login button — full width, primary]
[Space: space.md]
[Divider — "OR" — type.footnote uppercase tracking 0.08em]
[Space: space.md]
[Sign in with Apple — full width, radius.pill, 50pt]
[Space: space.xs]
[Sign in with Google — full width, radius.pill, 50pt]
[Space: space.xs]
[Continue as Guest — conditional on allowGuestAccess]
[Space: space.xl]
["Don't have an account? Register" — centred, type.subhead, color.primary on bold]
[Space: space.xl + safe area]
```

Horizontal edge padding: `space.lg` (24pt) on both sides.

On macOS the same stacking applies inside a 440 × ≥540pt floating panel
centered in the host window. No max-width override needed — the panel
sets the bound.

---

## Tagline

The subtitle is fixed copy intended to be reassuring without being chirpy:

> "Sign in to pick up where you left off."

Localisation key: `auth.login.subtitle`.

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Screen title | `type.title.lg`, `color.label.primary` | `auth.login.title` | |
| Subtitle | `type.callout`, `color.label.secondary` | `auth.login.subtitle` | Max width 340pt |
| Email field | Text Field component | `auth.login.field.email.placeholder` | `keyboardType(.emailAddress)`, `textContentType(.emailAddress)`, `autocapitalization(.none)`, `submitLabel(.next)` |
| Password field | Text Field component (secure) | `auth.login.field.password.placeholder` | `textContentType(.password)`, `submitLabel(.go)`, trailing eye toggle |
| Show/hide toggle | SF Symbol `eye` / `eye.slash`, 18pt, `color.label.tertiary` | `auth.field.password.show` / `.hide` | 44×44pt hit area |
| Inline error | Error Row component | See Error States table | Appears + 4px slide-up, `dur.base` |
| Forgot link | `type.subhead`, `color.primary` | `auth.login.link.forgot_password` | Right-aligned |
| Login button | Primary Button | `auth.login.button.submit` | Full width, 52pt height |
| Divider | "Or" Divider component | `auth.separator.or` | Uppercase, tracking 0.08em |
| Apple button | Custom button — see § 10.5 of design-system | `auth.button.apple` | `radius.pill`, 50pt |
| Google button | Custom button — see § 10.6 of design-system | `auth.button.google` | `radius.pill`, 50pt |
| Guest button | Outline button — see § 10.7 | `auth.login.button.guest` | Hidden when `allowGuestAccess == false` |
| Register link | `type.subhead`, `color.label.secondary` with bold `color.primary` "Register" run | `auth.login.link.register` | Centred; tap pushes `RegisterView` |

---

## States

| State | Visual |
|-------|--------|
| Default | Both fields empty; Login button shows `color.primary.disabled` |
| Partially filled | Login button stays disabled until both fields are non-empty |
| Ready | Login button uses `color.primary` |
| Hover (macOS) | Login button shifts to `color.primary.hover` |
| Pressed | Login button shifts to `color.primary.pressed` + scale 0.97 |
| Loading | Login button shows spinner (tinted `color.label.on-primary`); all fields and other buttons disabled; keyboard dismissed |
| Error — field | Affected field uses `color.error` border + inline error row below (validation errors only) |
| Error — toast | Dismissible toast banner at the bottom of the screen (`color.error` background); for network/server/provider errors |
| Social loading | Full-screen `LoadingOverlay` over the sheet while Apple/Google call is in flight |

---

## Error States

**Strategy — validation vs. non-validation:**

- **Validation errors** (field-level): displayed *inline* directly below the relevant input field.
  These are errors the user can fix by correcting a field value (wrong credentials, bad format, etc.).
- **Non-validation errors** (network / server / provider): displayed as a *dismissible toast*
  pinned to the bottom of the screen. These are errors the user cannot fix by editing a field
  (no internet connection, server down, third-party sign-in failure, etc.).

Tapping the toast banner dismisses it and leaves the Login view in a clean state ready for retry.

| Scenario | Key | Placement | Error type |
|----------|-----|-----------|------------|
| Empty email or password | `auth.error.required` | Below the empty field | Validation — inline |
| Invalid email format | `auth.error.email_format` | Below email field | Validation — inline |
| Invalid credentials | `auth.login.error.invalid_credentials` | Below password field | Validation — inline |
| Network unavailable | `auth.error.network` | Toast at bottom of screen | Non-validation — toast |
| Server error | `auth.error.server` | Toast at bottom of screen | Non-validation — toast |
| Social token invalid | `auth.social.error.token_invalid` | Toast at bottom of screen | Non-validation — toast |
| Guest sign-in error | `auth.error.network` / `auth.error.server` | Toast at bottom of screen | Non-validation — toast |
| Google sign-in error | `auth.error.network` / `auth.error.server` | Toast at bottom of screen | Non-validation — toast |
| Apple sign-in error | `auth.error.network` / `auth.error.server` | Toast at bottom of screen | Non-validation — toast |

---

## Localisation Keys

| Key | English |
|-----|---------|
| `auth.login.title` | Welcome back |
| `auth.login.subtitle` | Sign in to pick up where you left off. |
| `auth.login.field.email.placeholder` | you@email.com |
| `auth.login.field.password.placeholder` | Password |
| `auth.login.button.submit` | Log in |
| `auth.login.link.forgot_password` | Forgot password? |
| `auth.login.link.register` | Don't have an account? Register |
| `auth.login.button.guest` | Continue as Guest |
| `auth.login.error.invalid_credentials` | Incorrect email or password. |
| `auth.button.google` | Sign in with Google |
| `auth.button.google.accessibility` | Sign in with Google |
| `auth.separator.or` | or |
| `auth.field.password.show` | Show password |
| `auth.field.password.hide` | Hide password |
| `auth.error.required` | This field is required. |
| `auth.error.email_format` | Please enter a valid email address. |
| `auth.error.network` | No internet connection. Please try again. |
| `auth.error.server` | Something went wrong. Please try again. |
| `auth.social.error.token_invalid` | Sign-in failed. Please try again. |

---

## Accessibility

- Min tap target 44 × 44pt — buttons are 50–52pt tall and compliant.
- Contrast AA — every text/background pair meets the threshold; see `design-system.md § 12`.
- Dynamic Type scales via SwiftUI text styles; `ScrollView` ensures graceful overflow.
- VoiceOver labels — email, password, toggle (dynamic), Login button, error row, social buttons, divider hidden, register link.
- Keyboard — `submitLabel(.next)` on email, `submitLabel(.go)` on password.
- Focus order — Email → Password → Forgot → Login → Apple → Google → Guest → Register.

---

## Design Tokens Used

| Token | Where |
|-------|-------|
| `color.primary` | Login button background, link tint |
| `color.bg` | Sheet background |
| `color.surface` | Field fill |
| `color.label.primary` | Title, field value |
| `color.label.secondary` | Subtitle, register-link prefix |
| `color.label.tertiary` | Placeholder, eye toggle |
| `color.error` | Inline error, errored field border |
| `color.separator` | Divider lines |
| `type.title.lg` | Title |
| `type.callout` | Subtitle |
| `type.body` | Field value |
| `type.button` | Login button label |
| `type.button.social` | Apple / Google / Guest labels |
| `type.subhead` | Forgot, register, divider label |
| `type.footnote` | Inline error |
| `space.xs` / `space.sm` / `space.md` / `space.lg` / `space.xl` | Per stacking diagram |
| `radius.sm` | Text fields |
| `radius.md` | Login button |
| `radius.pill` | Social buttons |
| `shadow.focus` / `shadow.focus.error` | Focused field |
| `dur.quick` / `dur.base` / `dur.instant` | Per state transitions in § design-system §8 |
