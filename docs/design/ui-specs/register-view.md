# UI Spec — RegisterView

**Version:** 2.0 · **Date:** 2026-05-15

## Purpose

Account creation. Reuses email + password fields, adds confirm-password.
Pushed onto the `NavigationStack` from `LoginView`. Also handles guest
upgrade when `AuthManager.authState == .guest`.

See `../design-system.md` for the token vocabulary used below.

---

## Layout

`RegisterView` is a `ScrollView` containing a single `VStack`:

```
[Screen title — type.title.lg]
[Subtitle  — type.callout, color.label.secondary]    space.xs below title
[Space: space.lg]
[Email text field]
[Space: space.xxs]  (only when error present)
[Inline error — conditional · email]
[Space: 14pt]
[Password text field + eye/eye.slash toggle]
[Space: space.xxs]  (only when error present)
[Inline error — conditional · password]
[Space: 14pt]
[Confirm password text field + eye/eye.slash toggle]
[Space: space.xxs]  (only when error present)
[Inline error — conditional · mismatch]
[Space: space.lg]
[Register button — full width, primary]
[Space: space.xl]
["Already have an account? Log in" — centred, type.subhead, color.primary on bold]
[Space: space.xl + safe area]
```

Horizontal edge padding: `space.lg` on both sides.

macOS: same stacking inside a 440 × ≥540pt floating panel.

---

## Tagline

> "Takes about 20 seconds. No payment needed."

Localisation key: `auth.register.subtitle`. The intent is to lower
friction perception — this is shown only on `LoginView`'s "register" push,
not on guest-upgrade where a different subtitle applies (see § 5).

---

## Components Used

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Screen title | `type.title.lg`, `color.label.primary` | `auth.register.title` | |
| Subtitle | `type.callout`, `color.label.secondary` | `auth.register.subtitle` | |
| Email field | Text Field | `auth.register.field.email.placeholder` — "Email" | `textContentType(.emailAddress)`, `submitLabel(.next)` |
| Password field | Text Field (secure) | `auth.register.field.password.placeholder` — "Password" | `textContentType(.newPassword)`, `submitLabel(.next)` |
| Confirm password field | Text Field (secure) | `auth.register.field.confirm_password.placeholder` — "Re-enter password" | `textContentType(.newPassword)`, `submitLabel(.go)` |
| Show/hide toggle (both pwds) | SF Symbol `eye` / `eye.slash`, 18pt | `auth.field.password.show` / `.hide` | Per LoginView spec |
| Inline error | Error Row component | See Error States | |
| Register button | Primary Button | `auth.register.button.submit` | Full width, 52pt |
| Login link | `type.subhead`, mixed weight | `auth.register.link.login` | Centred; pops `NavigationStack` |

---

## States

| State | Visual |
|-------|--------|
| Default | All fields empty; Register button uses `color.primary.disabled` |
| Filling | Button stays disabled until all three fields are non-empty |
| Ready | Button uses `color.primary` |
| Loading | Button shows spinner; fields and links disabled; keyboard dismissed |
| Error — field | Affected field(s) error border + inline message |
| Error — server | Inline error below Register button |

---

## Error States

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

## Guest-Upgrade Variant

When `AuthManager.authState == .guest` and the user enters the register flow,
the title and subtitle change:

| Element | Standard | Guest upgrade |
|---------|----------|---------------|
| Title | `auth.register.title` — "Create account" | `auth.register.upgrade.title` — "Save your progress" |
| Subtitle | `auth.register.subtitle` | `auth.register.upgrade.subtitle` — "Add an email and password so you don't lose your data." |
| Button | `auth.register.button.submit` — "Create account" | `auth.register.upgrade.button.submit` — "Save account" |

All other components and behaviour are identical.

---

## Localisation Keys

| Key | English |
|-----|---------|
| `auth.register.title` | Create account |
| `auth.register.subtitle` | Takes about 20 seconds. No payment needed. |
| `auth.register.upgrade.title` | Save your progress |
| `auth.register.upgrade.subtitle` | Add an email and password so you don't lose your data. |
| `auth.register.field.email.placeholder` | Email |
| `auth.register.field.password.placeholder` | Password |
| `auth.register.field.confirm_password.placeholder` | Re-enter password |
| `auth.register.button.submit` | Create account |
| `auth.register.upgrade.button.submit` | Save account |
| `auth.register.link.login` | Already have an account? Log in |
| `auth.register.error.password_too_short` | Password must be at least 8 characters. |
| `auth.register.error.password_mismatch` | Passwords do not match. |
| `auth.register.error.email_taken` | An account with this email already exists. |

---

## Accessibility

- Min tap target 44 × 44pt — Register button is 52pt; password toggles are 44×44pt hit areas.
- Contrast AA — same guarantee as LoginView.
- Dynamic Type scales via SwiftUI text styles; `ScrollView` wrapping prevents clipping.
- VoiceOver labels — email, password, confirm-password, both toggles (dynamic), Register button, inline errors with `accessibilityAddTraits(.updatesFrequently)`.
- Focus order — Email → Password → Confirm Password → Register → Login link.
- Keyboard — `submitLabel(.next)` on email and password; `submitLabel(.go)` on confirm-password.

---

## Design Tokens Used

Same vocabulary as `LoginView`. See that spec's table for the full list. The
only additions specific to RegisterView are the duplicated `space.xs` /
`space.xxs` rhythms around the three-field stack — already covered by the
spacing scale.
