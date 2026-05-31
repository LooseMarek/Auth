# UI Spec — ResetPasswordView

**Version:** 1.0 · **Date:** 2026-05-31

## Purpose

Completes the password-reset flow started by `ForgotPasswordView`. The user enters the
one-time reset token delivered by email, a new password, and a confirm-password field,
then submits via `POST /auth/reset-password`. On success, the view transitions to a
confirmation card that prompts the user to log in.

Pushed onto the `NavigationStack` from `ForgotPasswordView`'s success state when the
user taps "Enter reset token".

See `../design-system.md` for the token vocabulary used below.
See [forgot-password-view.md](forgot-password-view.md) for the preceding screen.

---

## Layout — Form

```
[Screen title — type.title.lg]
[Subtitle — type.callout, color.label.secondary]   space.xs below
[Space: space.lg]
[Reset token text field]
[Space: space.xxs]  (only when error present)
[Inline error — conditional]
[Space: space.sm]
[New password field (SecureField)]
[Space: space.sm]
[Confirm password field (SecureField)]
[Space: space.lg]
["Update password" button — full width, primary]
[Space: space.xl]
["Back to log in" link — centred, type.subhead, color.primary]
[Space: space.xl + safe area]
```

Horizontal edge padding: `space.lg` on both sides.
macOS: 440 × ≥540pt floating panel.

---

## Layout — Success

```
[Space: space.xl — top breathing room]
[Success-state card — full width]
  ┌────────────────────────────────────────┐
  │ [64pt circle, color.success.soft]      │
  │   └─ checkmark.circle.fill · 48pt      │  centred
  │                                        │
  │ [Success title — type.headline, 20pt]  │  space.sm below icon circle
  │                                        │
  │ [Success body — type.body, secondary]  │  space.xxs below title
  │     max-width 280pt                    │
  └────────────────────────────────────────┘
[Space: space.lg]
["Back to log in" button — primary, full width]
[Space: space.xl + safe area]
```

The success card uses `color.surface.elevated`, `radius.lg`, `space.lg`
padding, and `shadow.card`.

---

## Motion · Form → Success

```
form fades out (opacity 1 → 0, 160ms, ease.standard)
   ↓ overlap
success card mounts at scale(0.96) opacity(0)
   → scale(1.0) opacity(1) over dur.reveal (320ms) on ease.emphasis
```

Reduce-motion collapses the transition to a 180ms opacity-only fade-in.

---

## Components Used

### Form

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Screen title | `type.title.lg`, `color.label.primary` | `auth.reset.title` | |
| Subtitle | `type.callout`, `color.label.secondary` | `auth.reset.subtitle` | Wraps to 2–3 lines |
| Reset token field | Text Field | `auth.reset.field.token.placeholder` | `textContentType(.oneTimeCode)`, `submitLabel(.next)` |
| Inline error | Error Row component | See Error States | |
| New password field | SecureField | `auth.reset.field.new_password.placeholder` | `textContentType(.newPassword)`, `submitLabel(.next)` |
| Confirm password field | SecureField | `auth.reset.field.confirm_password.placeholder` | `textContentType(.newPassword)`, `submitLabel(.go)` |
| Submit button | Primary Button | `auth.reset.button.submit` | Full width, 52pt; disabled until all fields valid |
| Back link | `type.subhead`, `color.primary` | `auth.reset.link.back` | Centred; pops to LoginView via `dismissToRoot` |

### Success

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Success card | `color.surface.elevated`, `radius.lg`, `space.lg` padding, `shadow.card` | — | |
| Hero icon | SF Symbol `checkmark.circle.fill`, 48pt, `color.success`, inside 64pt circle of `color.success.soft` | — | `.accessibilityHidden(true)` |
| Title | `type.headline` (size override → 20pt) | `auth.reset.success.title` | `color.label.primary` |
| Body | `type.body`, `color.label.secondary` | `auth.reset.success.body` | Max width 280pt |
| Back button | Primary Button | `auth.reset.link.back` | Full width; pops to `LoginView` via `dismissToRoot` |

---

## States

| State | Visual |
|-------|--------|
| Default | Empty fields; Submit button uses `color.primary.disabled` |
| Partially filled | Submit button still disabled until token + both passwords pass validation |
| All valid | Submit button uses `color.primary` |
| Loading | Submit button shows spinner; all fields disabled |
| Success | Form replaced by success card; Back link → Back button |
| Error | Inline error below token field |

---

## Error States

| Scenario | Key | Placement |
|----------|-----|-----------|
| Invalid or expired token | `auth.error.invalid_reset_token` | Below token field |
| Network unavailable | `auth.error.network` | Below token field |
| Server error | `auth.error.server` | Below token field |

Client-side validation (enforced by `canSubmit` before submission):

| Scenario | Key | Trigger |
|----------|-----|---------|
| Passwords do not match | `auth.reset.error.password_mismatch` | Validated by `canSubmit` (passwords must match) |
| Password too short | `auth.reset.error.password_too_short` | Validated by `canSubmit` (≥8 characters required) |

---

## Navigation — "Back to log in"

`ResetPasswordView` is always pushed from `ForgotPasswordView`'s success state via a
`NavigationLink`. To return the user to `LoginView`, the view accepts a `dismissToRoot`
closure from `ForgotPasswordView`. When the user taps "Back to log in" (either the link
in the form or the button in the success card), `dismissToRoot` fires — popping both
`ResetPasswordView` and `ForgotPasswordView` simultaneously, returning directly to
`LoginView`.

---

## Localisation Keys

| Key | English |
|-----|---------|
| `auth.reset.title` | Reset password |
| `auth.reset.subtitle` | Enter the token from your email and choose a new password. |
| `auth.reset.field.token.placeholder` | Reset token |
| `auth.reset.field.new_password.placeholder` | New password |
| `auth.reset.field.confirm_password.placeholder` | Confirm new password |
| `auth.reset.button.submit` | Reset password |
| `auth.reset.link.back` | Back to log in |
| `auth.reset.success.title` | Password reset! |
| `auth.reset.success.body` | Your password has been updated. You can now log in with your new password. |
| `auth.reset.error.password_mismatch` | Passwords do not match. |
| `auth.reset.error.password_too_short` | Password must be at least 8 characters. |

---

## Accessibility

- Min tap target 44 × 44pt — buttons are 52pt; back link is 44pt-tall.
- Dynamic Type scales every text style; `ScrollView` wrapping prevents clipping.
- Success card uses `accessibilityElement(children: .combine)` so VoiceOver reads icon + title + body as a single element.
- Focus order (form): Token → New password → Confirm → Submit → Back.
- Focus order (success): Success card → Back button.
- Reduced motion: form→success collapses to opacity-only fade, 180ms.

---

## Design Tokens Used

| Token | Where |
|-------|-------|
| `color.primary` | Submit / Back buttons, link tints |
| `color.bg` | Screen background |
| `color.surface` | Field fill |
| `color.surface.elevated` | Success card background |
| `color.label.primary` | Title, success title |
| `color.label.secondary` | Subtitle, success body |
| `color.error` | Inline error |
| `color.success` | Checkmark icon |
| `color.success.soft` | Icon ring backdrop |
| `color.separator` | Card hairline border |
| `type.title.lg` | Screen title |
| `type.callout` | Subtitle |
| `type.body` | Field value, success body |
| `type.headline` | Success title (size override 20pt) |
| `type.button` | Button labels |
| `type.subhead` | Back link |
| `type.footnote` | Inline error |
| `space.xxs` | Field → inline-error gap |
| `space.sm` | Icon circle → title gap; between fields |
| `space.lg` | Between sections |
| `space.xl` | Top breathing room, bottom padding |
| `radius.lg` | Success card |
| `radius.sm` | Text fields |
| `radius.md` | Primary button |
| `shadow.card` | Success card lift |
| `dur.reveal` / `ease.emphasis` | Success reveal |
