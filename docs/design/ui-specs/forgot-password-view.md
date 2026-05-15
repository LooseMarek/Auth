# UI Spec — ForgotPasswordView

**Version:** 2.0 · **Date:** 2026-05-15

## Purpose

Lets the user request a password-reset email. Has two states — a form and a
success card — connected by an explicit emphasis transition (see § Motion).
Pushed onto the `NavigationStack` from `LoginView`.

See `../design-system.md` for the token vocabulary used below.

---

## Layout — Form

```
[Screen title — type.title.lg]
[Subtitle — type.callout, color.label.secondary]   space.xs below
[Space: space.lg]
[Email text field]
[Space: space.xxs]  (only when error present)
[Inline error — conditional]
[Space: space.lg]
["Send reset link" button — full width, primary]
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
[Back to log in button — primary, full width]
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

The card uses `ease.emphasis` to land with a tiny overshoot — the only
celebratory micro-moment in the package. Reduce-motion collapses the
transition to a 180ms opacity-only fade-in.

VoiceOver receives `UIAccessibility.post(notification: .announcement, ...)`
with the success title string on transition.

---

## Components Used

### Form

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Screen title | `type.title.lg`, `color.label.primary` | `auth.forgot.title` | |
| Subtitle | `type.callout`, `color.label.secondary` | `auth.forgot.subtitle` | Wraps to 2–3 lines |
| Email field | Text Field | `auth.forgot.field.email.placeholder` | `textContentType(.emailAddress)`, `submitLabel(.go)` |
| Inline error | Error Row component | See Error States | |
| Send button | Primary Button | `auth.forgot.button.submit` | Full width, 52pt |
| Back link | `type.subhead`, `color.primary` | `auth.forgot.link.back` | Centred; pops `NavigationStack` |

### Success

| Component | Token / Variant | Localisation Key | Notes |
|-----------|----------------|------------------|-------|
| Success card | `color.surface.elevated`, `radius.lg`, `space.lg` padding, `shadow.card` | — | |
| Hero icon | SF Symbol `checkmark.circle.fill`, 48pt, `color.success`, inside 64pt circle of `color.success.soft` | — | `.accessibilityHidden(true)` |
| Title | `type.headline` (size override → 20pt) | `auth.forgot.success.title` | `color.label.primary` |
| Body | `type.body`, `color.label.secondary` | `auth.forgot.success.body` | Max width 280pt |
| Back button | Primary Button | `auth.forgot.link.back` | Full width; pops to `LoginView` |

---

## States

| State | Visual |
|-------|--------|
| Default | Empty field; Send button uses `color.primary.disabled` |
| Field filled | Send button uses `color.primary` |
| Loading | Send button shows spinner; field and link disabled; keyboard dismissed |
| Success | Form replaced by success card; Back link → Back button |
| Error | Inline error below field or below Send button |

---

## Error States

| Scenario | Key | Placement |
|----------|-----|-----------|
| Empty field | `auth.error.required` | Below email field |
| Invalid email format | `auth.error.email_format` | Below email field |
| Network unavailable | `auth.error.network` | Below Send button |
| Server error | `auth.error.server` | Below Send button |

> No "email not found" error is surfaced. The server always returns 200 for a
> well-formed email. This is intentional — prevents user enumeration.

---

## Localisation Keys

| Key | English |
|-----|---------|
| `auth.forgot.title` | Reset password |
| `auth.forgot.subtitle` | Enter your email and we'll send you a link to reset your password. |
| `auth.forgot.field.email.placeholder` | you@email.com |
| `auth.forgot.button.submit` | Send reset link |
| `auth.forgot.link.back` | Back to log in |
| `auth.forgot.success.title` | Check your inbox |
| `auth.forgot.success.body` | We've sent a password reset link to your email. It may take a few minutes to arrive. |

---

## Accessibility

- Min tap target 44 × 44pt — buttons are 52pt; back link is 44pt-tall.
- Contrast AA — `color.success` (#2BA471) on `color.surface.elevated` (#FFFFFF) is 3.36:1; the icon also lives in a `color.success.soft` ring at 10% to provide enough visual weight. Accompanying icon does *not* carry the meaning alone — the title and body announce success.
- Dynamic Type scales every text style; `ScrollView` wrapping prevents clipping at large sizes.
- VoiceOver — on form→success transition, post `UIAccessibility.post(notification: .announcement, argument: <success.title string>)`. Success card uses `accessibilityElement(children: .combine)` so VoiceOver reads icon + title + body as a single element.
- Focus order (form): Email → Send → Back.
- Focus order (success): Success card → Back button.
- Reduced motion: form→success collapses to opacity-only fade, 180ms.

---

## Design Tokens Used

| Token | Where |
|-------|-------|
| `color.primary` | Send / Back buttons, link tints |
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
| `space.sm` | Icon circle → title gap |
| `space.lg` | Between sections |
| `space.xl` | Top breathing room, bottom padding |
| `radius.lg` | Success card |
| `radius.sm` | Text field |
| `radius.md` | Primary button |
| `shadow.card` | Success card lift |
| `dur.reveal` / `ease.emphasis` | Success reveal |
