# UI Spec — ForgotPasswordView

## Purpose

Allows the user to request a password reset email. Has two distinct visual states:
the default form state and a success state shown after the reset email is sent.
Presented by pushing onto the `NavigationStack` inside the auth sheet from `LoginView`.

---

## Layout — Form State

`ForgotPasswordView` form state is a `ScrollView` containing a single `VStack` (top to bottom):

```
[Screen title]
[Spacing: spacing.sm]
[Subheading / instruction text]
[Spacing: spacing.lg]
[Email text field]
[Spacing: spacing.xs]
[Inline error message — conditionally visible]
[Spacing: spacing.lg]
["Send reset link" button — full width]
[Spacing: spacing.xl]
["Back to login" link — centred]
[Spacing: spacing.xl — bottom safe area]
```

Horizontal edge padding: `spacing.md` on both sides.
macOS: width capped at 400pt, centred.

---

## Layout — Success State

When the server returns a response (always 200 for a well-formed email), the form state
is replaced with the success state using a `.transition(.opacity)` animation:

```
[Spacing: spacing.xxl — top breathing room]
[Success state card — full width]
  [checkmark.circle.fill icon — 48pt — color.success — centred]
  [Spacing: spacing.sm]
  [Success title]
  [Spacing: spacing.xs]
  [Success body text]
[Spacing: spacing.lg]
["Back to login" button — full width]
[Spacing: spacing.xl — bottom safe area]
```

The success state card uses the `Success State Card` component spec from `design-system.md`.

---

## Components Used

### Form State

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|-----------------|-------|
| Screen title (`Text`) | `type.title`, `color.label.primary` | `auth.forgot.title` | |
| Subheading (`Text`) | `type.callout`, `color.label.secondary` | `auth.forgot.subtitle` | Wraps to multiple lines |
| Email field (`TextField`) | `type.body`, `border.field` | `auth.forgot.field.email.placeholder` | `keyboardType(.emailAddress)`, `textContentType(.emailAddress)`, `autocapitalization(.none)` |
| Inline error message | `type.footnote`, `color.error` | See Error States table | Conditionally visible |
| "Send reset link" button | Primary button component | `auth.forgot.button.submit` | Full width, 50pt height |
| "Back to login" link (`Button`) | `type.subhead`, `color.primary` | `auth.forgot.link.back` | Centred; pops `NavigationStack` |

### Success State

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|-----------------|-------|
| Success card container | `color.surface`, `radius.lg`, padding `spacing.lg` | — | |
| Checkmark icon (`Image(systemName:)`) | `checkmark.circle.fill`, 48pt, `color.success` | — | `.accessibilityHidden(true)` |
| Success title (`Text`) | `type.headline`, `color.label.primary` | `auth.forgot.success.title` | |
| Success body (`Text`) | `type.body`, `color.label.secondary` | `auth.forgot.success.body` | |
| "Back to login" button | Primary button component | `auth.forgot.link.back` | Full width; pops to `LoginView` |

---

## States

| State | Behaviour |
|-------|-----------|
| Default | Empty field, "Send reset link" button disabled |
| Field filled | "Send reset link" button active |
| Loading | Button shows spinner; field and links disabled; keyboard dismissed |
| Success | Form state replaced with success state card + "Back to login" button |
| Error | Inline error below email field or below Send button |

---

## Error States and Inline Messages

| Scenario | Key | Placement |
|----------|-----|-----------|
| Empty field | `auth.error.required` | Below email field |
| Invalid email format | `auth.error.email_format` | Below email field |
| Network unavailable | `auth.error.network` | Below Send button |
| Server error | `auth.error.server` | Below Send button |

> No "email not found" error is surfaced. The server always returns 200 for a
> valid email address. This is intentional to prevent user enumeration.

---

## Localisation Keys

| Key | Placeholder English String |
|-----|---------------------------|
| `auth.forgot.title` | "Reset password" |
| `auth.forgot.subtitle` | "Enter your email address and we'll send you a link to reset your password." |
| `auth.forgot.field.email.placeholder` | "Email" |
| `auth.forgot.button.submit` | "Send reset link" |
| `auth.forgot.link.back` | "Back to login" |
| `auth.forgot.success.title` | "Check your inbox" |
| `auth.forgot.success.body` | "We've sent a password reset link to your email. It may take a few minutes to arrive." |

---

## Accessibility

- Minimum tap target: 44x44pt — all interactive elements.
- Contrast ratio: WCAG AA — all system color tokens. `color.success` (#34C759) on `color.surface` — verify in context; add `.accessibilityLabel` to success icon for screen readers.
- Dynamic Type: `ScrollView` wrapping ensures no clipping.
- VoiceOver labels:
  - Email field: `accessibilityLabel("auth.forgot.field.email.placeholder")`
  - "Send reset link" button: `accessibilityLabel("auth.forgot.button.submit")`
  - "Back to login" link: `accessibilityLabel("auth.forgot.link.back")`
  - On success state transition: post `UIAccessibility.post(notification: .announcement, argument: ...)` using the `auth.forgot.success.title` string to announce the success to VoiceOver users
  - Success card: `accessibilityElement(children: .combine)` so VoiceOver reads title + body as one element
  - Checkmark icon: `.accessibilityHidden(true)` (decorative)
- Focus order (form): Email → Send → Back to login.
- Focus order (success): Success card (combined) → Back to login button.
- Keyboard: `submitLabel(.go)` on email field triggers send action.

---

## Design Tokens Used

| Token | Usage |
|-------|-------|
| `color.primary` | Send button background, Back link text |
| `color.background` | Screen background |
| `color.surface` | Success card background, text field background |
| `color.label.primary` | Title, success title |
| `color.label.secondary` | Subtitle, success body |
| `color.error` | Inline error |
| `color.success` | Checkmark icon |
| `type.title` | Screen title |
| `type.callout` | Subtitle instruction |
| `type.body` | Field text, success body |
| `type.button` | Button labels |
| `type.headline` | Success card title |
| `type.subhead` | Back to login link |
| `type.footnote` | Inline error |
| `spacing.xs` | Field to inline error gap |
| `spacing.sm` | Icon to title gap in success card |
| `spacing.md` | Horizontal edge insets |
| `spacing.lg` | Between form sections |
| `spacing.xl` | Bottom padding |
| `spacing.xxl` | Top breathing room in success state |
| `radius.lg` | Success card corner radius |
| `radius.sm` | Text field corner radius |
| `radius.md` | Button corner radius |
